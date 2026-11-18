/**
 * Tests for Pi worktree trust: the `worktree-trust` extension's inheritance
 * decision and the `pi-trust-cleanup` helper Worktrunk's post-remove hook
 * calls. The fixtures are real Git repositories, so the Git identification
 * the extension relies on is exercised, not stubbed.
 *
 * Run from the repository root:
 *   node --test --experimental-strip-types tests/pi-worktree-trust.test.ts
 */

import { execFileSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import assert from "node:assert/strict";
import { after, test } from "node:test";

import {
  decideWorktreeTrust,
  nearestDecision,
  readTrustStore,
  worktreeInfo,
} from "../configs/home/pi/agent/extensions/worktree-trust.ts";

const CLEANUP_SCRIPT = new URL("../configs/home/worktrunk/pi-trust-cleanup.sh", import.meta.url)
  .pathname;

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

test("the remembered key is the worktree's own canonical path", () => {
  const info = worktreeInfo(worktreeA);
  assert.ok(info);
  assert.equal(info.toplevel, worktreeA);
  assert.notEqual(info.gitDir, info.commonDir);
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

// ── Cleanup helper ──────────────────────────────────────────────────────────

/** Run the cleanup helper; returns exit code and stderr. */
function runCleanup(removed: string, trustFile: string) {
  try {
    execFileSync("bash", [CLEANUP_SCRIPT, removed, trustFile], { encoding: "utf-8" });
    return { status: 0, stderr: "" };
  } catch (error) {
    const err = error as { status?: number; stderr?: string };
    return { status: err.status ?? -1, stderr: err.stderr ?? "" };
  }
}

test("a successful removal deletes only the removed worktree's key", () => {
  const dir = join(base, "cleanup-remove");
  mkdirSync(dir);
  const trustFile = join(dir, "trust.json");
  const store = {
    [other]: true,
    [repo]: true,
    [worktreeA]: true,
    [worktreeB]: true,
  };
  writeFileSync(trustFile, `${JSON.stringify(store, null, 2)}\n`);

  const result = runCleanup(worktreeA, trustFile);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(JSON.parse(readFileSync(trustFile, "utf-8")), {
    [other]: true,
    [repo]: true,
    [worktreeB]: true,
  });
  // Keys stay sorted, the way Pi writes them.
  const keys = Object.keys(JSON.parse(readFileSync(trustFile, "utf-8")));
  assert.deepEqual([...keys].sort(), keys);
  // The lock is released afterwards.
  assert.equal(existsSync(`${trustFile}.lock`), false);
});

test("canonical path matching: a trailing slash still matches", () => {
  const dir = join(base, "cleanup-canonical");
  mkdirSync(dir);
  const trustFile = join(dir, "trust.json");
  writeFileSync(trustFile, `${JSON.stringify({ [worktreeA]: true, [repo]: true }, null, 2)}\n`);

  const result = runCleanup(`${worktreeA}/.`, trustFile);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(JSON.parse(readFileSync(trustFile, "utf-8")), { [repo]: true });
});

test("an absent key is a no-op", () => {
  const dir = join(base, "cleanup-absent");
  mkdirSync(dir);
  const trustFile = join(dir, "trust.json");
  const contents = `${JSON.stringify({ [repo]: true }, null, 2)}\n`;
  writeFileSync(trustFile, contents);

  const result = runCleanup(worktreeA, trustFile);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(readFileSync(trustFile, "utf-8"), contents);
});

test("a missing trust store is a no-op", () => {
  const dir = join(base, "cleanup-missing-store");
  mkdirSync(dir);
  const result = runCleanup(worktreeA, join(dir, "trust.json"));
  assert.equal(result.status, 0, result.stderr);
});

test("invalid JSON leaves the store unchanged and fails loudly", () => {
  const dir = join(base, "cleanup-invalid");
  mkdirSync(dir);
  const trustFile = join(dir, "trust.json");
  const contents = '{"repo": broken';
  writeFileSync(trustFile, contents);

  const result = runCleanup(worktreeA, trustFile);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /not a valid Pi trust store/);
  assert.equal(readFileSync(trustFile, "utf-8"), contents);
});

test("wrong-shape JSON leaves the store unchanged and fails loudly", () => {
  const dir = join(base, "cleanup-shape");
  mkdirSync(dir);
  const trustFile = join(dir, "trust.json");
  const contents = '{"repo": "yes"}\n';
  writeFileSync(trustFile, contents);

  const result = runCleanup(worktreeA, trustFile);
  assert.notEqual(result.status, 0);
  assert.equal(readFileSync(trustFile, "utf-8"), contents);
});

test("a held lock fails without touching the store or the lock", () => {
  const dir = join(base, "cleanup-lock");
  mkdirSync(dir);
  const trustFile = join(dir, "trust.json");
  const contents = `${JSON.stringify({ [worktreeA]: true, [repo]: true }, null, 2)}\n`;
  writeFileSync(trustFile, contents);
  mkdirSync(`${trustFile}.lock`);

  const result = runCleanup(worktreeA, trustFile);
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /could not lock/);
  assert.equal(readFileSync(trustFile, "utf-8"), contents);
  // The lock belongs to the other holder; it must survive.
  assert.equal(existsSync(`${trustFile}.lock`), true);
});

test("an unwritable store directory fails without data loss", () => {
  const dir = join(base, "cleanup-readonly");
  mkdirSync(dir);
  const trustFile = join(dir, "trust.json");
  writeFileSync(trustFile, `${JSON.stringify({ [worktreeA]: true }, null, 2)}\n`);
  chmodSync(dir, 0o500);
  try {
    const result = runCleanup(worktreeA, trustFile);
    assert.notEqual(result.status, 0);
    assert.deepEqual(JSON.parse(readFileSync(trustFile, "utf-8")), { [worktreeA]: true });
  } finally {
    chmodSync(dir, 0o700);
  }
});
