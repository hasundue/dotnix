/**
 * Tests for Pi worktree trust: the `worktree-trust` extension's inheritance
 * decision, its explanation, and the `project_trust` handler it registers.
 * The fixtures are real Git repositories, so the Git identification the
 * extension relies on is exercised, not stubbed.
 *
 * Run from the repository root:
 *   node --test --experimental-strip-types tests/pi-worktree-trust.test.ts
 */

import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import assert from "node:assert/strict";
import { after, test } from "node:test";

import extension, {
  decideWorktreeTrust,
  explainWorktreeTrust,
  nearestDecision,
  readTrustStore,
  worktreeInfo,
} from "../configs/home/pi/agent/extensions/worktree-trust.ts";

type TrustHandler = (event: { cwd: string }) => Promise<{ trusted: string; remember?: boolean }>;

// ── Fixtures ────────────────────────────────────────────────────────────────

const base = mkdtempSync(join(tmpdir(), "pi-worktree-trust-test-"));

after(() => {
  rmSync(base, { recursive: true, force: true });
});

/** Create a Git repository with one commit; returns its root. */
function makeRepo(name: string): string {
  const root = join(base, name);
  mkdirSync(root, { recursive: true });
  execFileSync("git", ["-C", root, "init", "-q"]);
  execFileSync("git", ["-C", root, "config", "user.email", "test@example.com"]);
  execFileSync("git", ["-C", root, "config", "user.name", "Test"]);
  writeFileSync(join(root, "README.md"), "# test\n");
  execFileSync("git", ["-C", root, "add", "README.md"]);
  execFileSync("git", ["-C", root, "commit", "-q", "-m", "init"]);
  return root;
}

/** Add a linked worktree of `repo` at `<repo>-<name>`; returns its root. */
function makeWorktree(repo: string, name: string): string {
  const path = `${repo}-wt-${name}`;
  execFileSync("git", ["-C", repo, "worktree", "add", "-q", path, "-b", `wt-${name}`]);
  return path;
}

const repo = makeRepo("repo");
const worktreeA = makeWorktree(repo, "a");
const worktreeB = makeWorktree(repo, "b");
const other = makeRepo("other");

// ── Extension: inheritance ──────────────────────────────────────────────────

test("a linked worktree inherits trust from the trusted main checkout", () => {
  assert.equal(decideWorktreeTrust(worktreeA, { [repo]: true }), "yes");
});

test("a linked worktree inherits trust from a trusted sibling worktree", () => {
  assert.equal(decideWorktreeTrust(worktreeB, { [worktreeA]: true }), "yes");
});

test("a linked worktree has its own git directory under the common one", () => {
  const info = worktreeInfo(worktreeA);
  assert.ok(info);
  assert.equal(info.toplevel, worktreeA);
  assert.notEqual(info.gitDir, info.commonDir);
});

test("the explanation names the trusted checkout", () => {
  const explanation = explainWorktreeTrust(worktreeA, { [repo]: true });
  assert.equal(explanation.decision, "yes");
  assert.match(explanation.reason, new RegExp(`${repo} is a trusted checkout`));
});

// ── Extension: negative cases ───────────────────────────────────────────────

test("an unrelated repository's approval is not inherited", () => {
  assert.equal(decideWorktreeTrust(worktreeA, { [other]: true }), "undecided");
});

test("no saved approval leaves the decision to Pi", () => {
  assert.equal(decideWorktreeTrust(worktreeA, {}), "undecided");
});

test("an explicit denial that applies to the target is preserved", () => {
  assert.equal(decideWorktreeTrust(worktreeA, { [worktreeA]: false, [repo]: true }), "undecided");
});

test("an existing trust decision for the target is deferred to Pi", () => {
  assert.equal(decideWorktreeTrust(worktreeA, { [worktreeA]: true, [repo]: true }), "undecided");
});

test("a parent directory's approval is not inherited", () => {
  assert.equal(nearestDecision({ [base]: true }, worktreeA), true);
  assert.equal(decideWorktreeTrust(worktreeA, { [base]: true }), "undecided");
});

test("the main checkout itself does not inherit", () => {
  assert.equal(decideWorktreeTrust(repo, { [worktreeA]: true }), "undecided");
});

test("a stale approval path is ignored", () => {
  const missing = join(base, "gone");
  assert.equal(decideWorktreeTrust(worktreeA, { [missing]: true }), "undecided");
});

test("an approval for a subdirectory is not treated as a checkout root", () => {
  assert.equal(decideWorktreeTrust(worktreeA, { [join(repo, "configs")]: true }), "undecided");
});

// ── Extension: decline reasons ──────────────────────────────────────────────

test("a plain directory reports a failed Git identification", () => {
  const plain = join(base, "plain");
  mkdirSync(plain);
  assert.match(explainWorktreeTrust(plain, {}).reason, /Git could not identify/);
});

test("a bare repository reports that it is no work tree", () => {
  const bare = join(base, "bare.git");
  execFileSync("git", ["init", "-q", "--bare", bare]);
  assert.match(explainWorktreeTrust(bare, {}).reason, /not inside a Git work tree/);
});

test("the main checkout says it is not a linked worktree", () => {
  assert.match(explainWorktreeTrust(repo, { [worktreeA]: true }).reason, /not a linked worktree/);
});

test("an applicable saved denial is named", () => {
  assert.match(
    explainWorktreeTrust(worktreeA, { [worktreeA]: false, [repo]: true }).reason,
    /a saved denial applies/,
  );
});

test("an approval of another repository is named", () => {
  assert.match(explainWorktreeTrust(worktreeA, { [other]: true }).reason, /another repository/);
});

test("a stale approval is named", () => {
  assert.match(explainWorktreeTrust(worktreeA, { [join(base, "gone")]: true }).reason, /missing/);
});

test("a subdirectory approval is named", () => {
  const subdirectory = join(repo, "configs");
  mkdirSync(subdirectory, { recursive: true });
  assert.match(
    explainWorktreeTrust(worktreeA, { [subdirectory]: true }).reason,
    /not a checkout root/,
  );
});

test("an empty store names the missing approval", () => {
  assert.match(explainWorktreeTrust(worktreeA, {}).reason, /no trusted checkout shares/);
});

// ── Extension: project_trust handler ────────────────────────────────────────

/** Register the extension against a stub API and return its handler. */
function loadProjectTrustHandler(): TrustHandler {
  const handlers: TrustHandler[] = [];
  const api = {
    on(event: string, handler: TrustHandler) {
      if (event === "project_trust") {
        handlers.push(handler);
      }
    },
  };
  extension(api as unknown as Parameters<typeof extension>[0]);
  assert.equal(handlers.length, 1);
  return handlers[0];
}

/** Point the extension at `agentDir` for the duration of `run`. */
async function withAgentDir(agentDir: string, run: () => Promise<void>): Promise<void> {
  const previous = process.env.PI_CODING_AGENT_DIR;
  process.env.PI_CODING_AGENT_DIR = agentDir;
  try {
    await run();
  } finally {
    if (previous === undefined) {
      delete process.env.PI_CODING_AGENT_DIR;
    } else {
      process.env.PI_CODING_AGENT_DIR = previous;
    }
  }
}

/** A fresh agent directory holding `store` as its trust.json. */
function agentDirWith(name: string, store: Record<string, boolean | null> | string): string {
  const agentDir = join(base, name);
  mkdirSync(agentDir, { recursive: true });
  const contents = typeof store === "string" ? store : `${JSON.stringify(store, null, 2)}\n`;
  writeFileSync(join(agentDir, "trust.json"), contents);
  return agentDir;
}

test("the handler grants trust without asking Pi to remember it", async () => {
  const agentDir = agentDirWith("agent-grant", { [repo]: true });
  const before = readFileSync(join(agentDir, "trust.json"), "utf-8");
  await withAgentDir(agentDir, async () => {
    const result = await loadProjectTrustHandler()({ cwd: worktreeA });
    // No `remember`: the decision must not be persisted.
    assert.deepEqual(result, { trusted: "yes" });
  });
  assert.equal(readFileSync(join(agentDir, "trust.json"), "utf-8"), before);
});

test("the handler stays undecided without a matching approval", async () => {
  const agentDir = agentDirWith("agent-absent", { [other]: true });
  await withAgentDir(agentDir, async () => {
    assert.deepEqual(await loadProjectTrustHandler()({ cwd: worktreeA }), {
      trusted: "undecided",
    });
  });
});

test("the handler stays undecided when the store is unreadable", async () => {
  const agentDir = agentDirWith("agent-broken", "{not json");
  await withAgentDir(agentDir, async () => {
    assert.deepEqual(await loadProjectTrustHandler()({ cwd: worktreeA }), {
      trusted: "undecided",
    });
  });
});

test("the debug trace names the decision and its reason", async () => {
  const agentDir = agentDirWith("agent-trace", { [repo]: true });
  const stderr = process.stderr as unknown as { write(chunk: string): boolean };
  const previousWrite = stderr.write;
  const previousDebug = process.env.PI_WORKTREE_TRUST_DEBUG;
  let traced = "";
  stderr.write = (chunk: string) => {
    traced += chunk;
    return true;
  };
  process.env.PI_WORKTREE_TRUST_DEBUG = "1";
  try {
    await withAgentDir(agentDir, async () => {
      await loadProjectTrustHandler()({ cwd: worktreeA });
    });
  } finally {
    stderr.write = previousWrite;
    if (previousDebug === undefined) {
      delete process.env.PI_WORKTREE_TRUST_DEBUG;
    } else {
      process.env.PI_WORKTREE_TRUST_DEBUG = previousDebug;
    }
  }
  assert.match(
    traced,
    /worktree-trust: .* -> yes: .* is a trusted checkout of the same repository/,
  );
  assert.match(traced, /store .*agent-trace\/trust\.json/);
});

test("nothing is traced without PI_WORKTREE_TRUST_DEBUG", async () => {
  const agentDir = agentDirWith("agent-quiet", { [repo]: true });
  const stderr = process.stderr as unknown as { write(chunk: string): boolean };
  const previousWrite = stderr.write;
  let traced = "";
  stderr.write = (chunk: string) => {
    traced += chunk;
    return true;
  };
  try {
    await withAgentDir(agentDir, async () => {
      await loadProjectTrustHandler()({ cwd: worktreeA });
    });
  } finally {
    stderr.write = previousWrite;
  }
  assert.equal(traced, "");
});

// ── Extension: store reading ────────────────────────────────────────────────

test("a missing trust store reads as empty", () => {
  assert.deepEqual(readTrustStore(join(base, "absent", "trust.json")), {});
});

test("an invalid trust store throws instead of deciding", () => {
  const bad = join(base, "bad-trust.json");
  writeFileSync(bad, "{not json");
  assert.throws(() => readTrustStore(bad));
  const wrongShape = join(base, "wrong-shape.json");
  writeFileSync(wrongShape, '{"maybe": "yes"}');
  assert.throws(() => readTrustStore(wrongShape));
});
