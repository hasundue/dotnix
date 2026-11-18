/**
 * Worktree trust — inherit a trusted checkout's decision for its linked worktrees.
 *
 * A linked worktree is a different path, so Pi's trust store, which is keyed
 * by path, never matches it and Pi asks for trust on first start even when
 * the checkout it was cut from is already trusted. This user extension runs
 * before project-local resources load and answers Pi's `project_trust` event
 * from the saved store instead.
 *
 * The rule is narrow: trust is granted only when the target is a Git linked
 * worktree and the store holds an explicit `true` for a different, existing
 * checkout root of the same Git repository (same common directory). Anything
 * else — an unrelated repository, an independent clone, a parent-directory
 * entry, no saved approval at all — stays `undecided` so Pi's normal flow
 * (saved decisions, then the prompt or `defaultProjectTrust`) decides. A
 * saved decision that already applies to the target, including an explicit
 * denial, is never overridden.
 *
 * Errors defer rather than decide: a failed Git identification or an
 * unreadable trust store leaves the question to Pi.
 */

import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

import type { ExtensionAPI, ProjectTrustEventResult } from "@earendil-works/pi-coding-agent";

// ── Trust store ─────────────────────────────────────────────────────────────

/** The shape Pi persists: path → decision, where `null` means "ask again". */
export type TrustStore = Record<string, boolean | null>;

/**
 * Canonicalize like Pi does: resolve, then follow symlinks when the path
 * exists. A removed worktree's path only exists in the store, so a
 * nonexistent path falls back to the lexical resolution.
 */
export function canonicalizePath(path: string): string {
  const absolute = resolve(path);
  if (existsSync(absolute)) {
    return realpathSync(absolute);
  }
  return absolute;
}

function pathsEqual(a: string, b: string): boolean {
  return canonicalizePath(a) === canonicalizePath(b);
}

/** Read and validate the trust store; throws when the file is not a store. */
export function readTrustStore(trustPath: string): TrustStore {
  if (!existsSync(trustPath)) {
    return {};
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(readFileSync(trustPath, "utf-8"));
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Failed to read trust store ${trustPath}: ${message}`);
  }
  if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
    throw new Error(`Invalid trust store ${trustPath}: expected an object`);
  }
  const store: TrustStore = {};
  for (const [key, value] of Object.entries(parsed)) {
    if (value !== true && value !== false && value !== null) {
      throw new Error(
        `Invalid trust store ${trustPath}: value for ${JSON.stringify(key)} must be true, false, or null`,
      );
    }
    store[key] = value;
  }
  return store;
}

/**
 * The nearest saved decision that applies to `cwd`, mirroring Pi's own walk:
 * the directory itself, then its ancestors. `null` when none applies.
 */
export function nearestDecision(store: TrustStore, cwd: string): boolean | null {
  let current = canonicalizePath(cwd);
  for (;;) {
    for (const [key, value] of Object.entries(store)) {
      if ((value === true || value === false) && pathsEqual(key, current)) {
        return value;
      }
    }
    const parent = dirname(current);
    if (parent === current) {
      return null;
    }
    current = parent;
  }
}

// ── Git identification ──────────────────────────────────────────────────────

export interface WorktreeInfo {
  /** The checkout root. */
  toplevel: string;
  /** This checkout's git directory; per-worktree for a linked worktree. */
  gitDir: string;
  /** The repository-wide git directory shared by every worktree. */
  commonDir: string;
}

function git(dir: string, args: string[]): string {
  return execFileSync("git", ["-C", dir, ...args], { encoding: "utf-8" }).trim();
}

/** Describe the checkout containing `dir`, or null when Git says it is none. */
export function worktreeInfo(dir: string): WorktreeInfo | null {
  try {
    if (git(dir, ["rev-parse", "--is-inside-work-tree"]) !== "true") {
      return null;
    }
    const toplevel = canonicalizePath(git(dir, ["rev-parse", "--show-toplevel"]));
    const gitDir = git(dir, ["rev-parse", "--absolute-git-dir"]);
    const commonDir = canonicalizePath(resolve(dir, git(dir, ["rev-parse", "--git-common-dir"])));
    return { toplevel, gitDir, commonDir };
  } catch {
    return null;
  }
}

/** A linked worktree owns a private git directory under the common one. */
function isLinkedWorktree(info: WorktreeInfo): boolean {
  return info.gitDir !== info.commonDir;
}

// ── Decision ────────────────────────────────────────────────────────────────

export type TrustDecision = "yes" | "undecided";

/**
 * Decide trust for `cwd` from `store` alone. `yes` only for a linked
 * worktree with an explicit, applicable `true` on a different checkout root
 * of the same repository; everything else defers to Pi.
 */
export function decideWorktreeTrust(cwd: string, store: TrustStore): TrustDecision {
  const info = worktreeInfo(cwd);
  if (!info || !isLinkedWorktree(info)) {
    return "undecided";
  }
  // A saved decision already governs the target — trust or denial alike —
  // so Pi's own resolution must own the answer.
  if (nearestDecision(store, cwd) !== null) {
    return "undecided";
  }
  for (const [key, value] of Object.entries(store)) {
    if (value !== true) {
      continue;
    }
    const root = canonicalizePath(key);
    // The approval must belong to an existing checkout root of its own, not
    // to a parent directory or a subdirectory where Pi once ran.
    if (!existsSync(root)) {
      continue;
    }
    const rootInfo = worktreeInfo(root);
    if (!rootInfo || !pathsEqual(root, rootInfo.toplevel)) {
      continue;
    }
    if (pathsEqual(rootInfo.commonDir, info.commonDir)) {
      return "yes";
    }
  }
  return "undecided";
}

// ── Wiring ──────────────────────────────────────────────────────────────────

function trustStorePath(): string {
  const agentDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
  return join(agentDir, "trust.json");
}

export default function (pi: ExtensionAPI) {
  pi.on("project_trust", async (event): Promise<ProjectTrustEventResult> => {
    try {
      const store = readTrustStore(trustStorePath());
      if (decideWorktreeTrust(canonicalizePath(event.cwd), store) === "yes") {
        return { trusted: "yes", remember: true };
      }
    } catch {
      // An unreadable store is not a decision: let Pi resolve trust itself.
    }
    return { trusted: "undecided" };
  });
}
