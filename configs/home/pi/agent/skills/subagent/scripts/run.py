#!/usr/bin/env python3
"""Run a pi task in a separate, read-only-by-default process.

The launcher owns the run directory and session; it does not write a vault
artifact. stdout is the child's final text. stderr stays quiet unless the child
fails or --info is passed.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import secrets
import shlex
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import NoReturn

SKILL_DIR = Path(__file__).resolve().parent.parent
CHILD_PROMPT = SKILL_DIR / "references" / "child.md"
RUN_ID_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?$")
LATEST_FILE = "latest"
REQUIRED_META = (
    "schema",
    "run_id",
    "session_id",
    "cwd",
    "created",
)
READ_ONLY_TOOLS = ("read", "grep", "find", "ls")
CHILD_FLAGS = (
    "--no-approve",
    "--no-extensions",
    "--no-mcp",
    "--no-skills",
    "--no-prompt-templates",
    "--system-prompt",
    "--append-system-prompt",
)
RESERVED_PI_FLAGS = {
    "--print",
    "-p",
    "--session",
    "--session-id",
    "--session-dir",
    "--no-session",
    "--continue",
    "-c",
    "--fork",
    "-r",
    "--mode",
    "--export",
    "--list-models",
    "--version",
    "-v",
    "--approve",
    "-a",
    "--extension",
    "-e",
    "--skill",
    "--prompt-template",
}
AGENT_FILES = ("auth.json", "models.json", "models-store.json", "settings.json")
AGENT_CONTEXT_FILES = (
    "AGENTS.md",
    "AGENTS.override.md",
    "CLAUDE.md",
    "APPEND_SYSTEM.md",
)


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr)


def die(message: str, code: int = 2) -> NoReturn:
    eprint(f"run.py: {message}")
    raise SystemExit(code)


def now_iso() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def default_state_dir() -> Path:
    base = os.environ.get("XDG_STATE_HOME")
    root = Path(base) if base else Path.home() / ".local" / "state"
    return root / "pi" / "subagents"


def resolve_state_dir(value: str | None) -> Path:
    if value:
        return Path(value).expanduser().resolve()
    return default_state_dir()


def source_agent_dir() -> Path:
    value = os.environ.get("PI_CODING_AGENT_DIR")
    root = Path(value).expanduser() if value else Path.home() / ".pi" / "agent"
    return root.resolve()


def prepare_agent_dir(agent_dir: Path, source: Path) -> None:
    agent_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    for name in AGENT_CONTEXT_FILES:
        target = agent_dir / name
        if target.exists() or target.is_symlink():
            target.unlink()
    for name in AGENT_FILES:
        source_file = source / name
        target = agent_dir / name
        if target.exists() or target.is_symlink():
            target.unlink()
        if not source_file.is_file():
            continue
        if name == "settings.json":
            try:
                data = json.loads(source_file.read_text())
            except (OSError, json.JSONDecodeError):
                pass
            else:
                if isinstance(data, dict):
                    data.pop("packages", None)
                target.write_text(
                    json.dumps(data, indent=2, ensure_ascii=False) + "\n"
                )
                target.chmod(0o600)
                continue
        shutil.copyfile(source_file, target)
        target.chmod(0o600)


def split_argv(argv: list[str]) -> tuple[list[str], list[str]]:
    """Split argv at the first bare `--`: left goes to argparse/pi, right is the prompt."""
    if "--" in argv:
        i = argv.index("--")
        return argv[:i], argv[i + 1 :]
    return argv, []


def read_input(prompt_words: list[str]) -> bytes:
    """Compose the full prompt run.py delivers to pi.

    Words after `--` are joined with spaces into the task, which comes
    first; piped input follows. The returned bytes are both the saved record
    and pi's stdin, so the child sees exactly what the run dir records.
    """
    stdin_data = b""
    if not sys.stdin.isatty():
        stdin_data = sys.stdin.buffer.read()
    task = " ".join(prompt_words).strip()
    if not stdin_data.strip() and not task:
        die("no prompt: pass words after `--` or pipe the prompt")
    if stdin_data.strip() and task:
        prompt = task.encode() + b"\n\n" + stdin_data.lstrip(b"\r\n").rstrip()
    elif task:
        prompt = task.encode()
    else:
        prompt = stdin_data.lstrip(b"\r\n").rstrip()
    return prompt


# pi flags that never take a value (verified against pi's cli/args.js in the
# pinned pi release). Unknown flags are assumed to take one, mirroring pi's
# own unknown-flag consumption.
BOOLEAN_PI_FLAGS = frozenset(
    {
        "--approve",
        "--continue",
        "--help",
        "--no-approve",
        "--no-builtin-tools",
        "--no-context-files",
        "--no-extensions",
        "--no-mcp",
        "--no-prompt-templates",
        "--no-session",
        "--no-skills",
        "--no-themes",
        "--no-tools",
        "--offline",
        "--verbose",
        "--version",
        "-a",
        "-c",
        "-h",
        "-na",
        "-nbt",
        "-nc",
        "-ne",
        "-ns",
        "-nt",
        "-np",
        "-v",
    }
)


def reject_bare_words(pi_flags: list[str]) -> None:
    """Die on words before `--` that would never become the task.

    Bare words would reach pi as extra messages, and `@file` words as
    attachments re-read on every `--resume`. Unknown flags are assumed to
    take a value, mirroring pi's own unknown-flag consumption.
    """
    i = 0
    while i < len(pi_flags):
        tok = pi_flags[i]
        if tok.startswith("@"):
            die(f"bare {tok!r} before `--` is forwarded to pi as an attachment; name it inside the task instead")
        if tok.startswith("-"):
            if (
                tok not in BOOLEAN_PI_FLAGS
                and "=" not in tok
                and i + 1 < len(pi_flags)
            ):
                nxt = pi_flags[i + 1]
                if not nxt.startswith("-") and not nxt.startswith("@"):
                    i += 1
            i += 1
            continue
        die(f"bare word {tok!r} before `--` never becomes the task; put it after `--`")


def has_flag(pi_flags: list[str], *names: str) -> bool:
    for flag in pi_flags:
        if flag.split("=", 1)[0] in names:
            return True
    return False


def validate_pi_flags(pi_flags: list[str]) -> None:
    for flag in pi_flags:
        name = flag.split("=", 1)[0]
        if name in RESERVED_PI_FLAGS:
            die(f"run.py manages {name}; do not pass it to the child")


def meta_pi_flags(meta: dict) -> list[str]:
    if "pi_flags" in meta:
        value = meta["pi_flags"]
        if not isinstance(value, list):
            die("meta.json pi_flags is not a list")
        return [str(item) for item in value]
    flags: list[str] = []
    if meta.get("model"):
        flags += ["--model", str(meta["model"])]
    if meta.get("thinking"):
        flags += ["--thinking", str(meta["thinking"])]
    tools = meta.get("tools")
    if tools == "none":
        flags.append("--no-tools")
    elif tools:
        flags += ["--tools", str(tools)]
    if meta.get("no_context_files") or meta.get("schema", 1) < 3:
        flags.append("--no-context-files")
    if not flags:
        die("meta.json has no pi_flags to resume from")
    return flags


def make_run_id() -> str:
    return datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + secrets.token_hex(3)


def write_latest(state_dir: Path, run_id: str) -> None:
    atomic_write(state_dir / LATEST_FILE, (run_id + "\n").encode())


def resolve_resume_id(state_dir: Path, value: str) -> str:
    if value != "last":
        return validate_run_id(value)
    path = state_dir / LATEST_FILE
    try:
        run_id = path.read_text().strip()
    except OSError:
        die(f"--resume with no ID needs {path}, which does not exist yet")
    if not run_id:
        die(f"{path} is empty")
    return validate_run_id(run_id)


def validate_run_id(run_id: str) -> str:
    if not RUN_ID_RE.fullmatch(run_id):
        die(
            f"invalid run ID: {run_id!r} "
            "(use [A-Za-z0-9._-], start and end alphanumeric)"
        )
    return run_id


def unique_run_id(state_dir: Path) -> str:
    for _ in range(16):
        run_id = make_run_id()
        if not (state_dir / run_id).exists():
            return run_id
    die("could not generate a unique run ID")


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(
        dir=path.parent, prefix=path.name + ".", suffix=".tmp"
    )
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def write_meta(run_dir: Path, meta: dict) -> None:
    content = json.dumps(meta, indent=2, ensure_ascii=False) + "\n"
    atomic_write(run_dir / "meta.json", content.encode())


def load_meta(run_dir: Path) -> dict:
    path = run_dir / "meta.json"
    if not path.is_file():
        die(f"meta.json not found in {run_dir}")
    try:
        meta = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        die(f"cannot read {path}: {exc}")
    if not isinstance(meta, dict):
        die(f"meta.json is not an object: {path}")
    missing = [key for key in REQUIRED_META if key not in meta]
    if missing:
        die(f"meta.json is missing: {', '.join(missing)}")
    return meta


def build_system_prompt() -> str:
    return CHILD_PROMPT.read_text().rstrip() + "\n"


def build_command(
    session_id: str,
    session_dir: Path,
    pi_flags: list[str],
    system_prompt: Path,
    resume: bool,
) -> list[str]:
    command = ["pi", "--print", "--session-dir", str(session_dir)]
    if resume:
        command += ["--session", session_id]
    else:
        command += ["--session-id", session_id]
    command += CHILD_FLAGS
    if not has_flag(pi_flags, "--tools", "-t", "--no-tools", "-nt"):
        command += ["--tools", ",".join(READ_ONLY_TOOLS)]
    command += pi_flags
    command += ["--append-system-prompt", str(system_prompt)]
    return command


def manual_command(
    session_id: str,
    session_dir: Path,
    pi_flags: list[str],
    system_prompt: Path,
) -> list[str]:
    command = [
        "pi",
        "--session-dir",
        str(session_dir),
        "--session",
        session_id,
    ]
    command += CHILD_FLAGS
    if not has_flag(pi_flags, "--tools", "-t", "--no-tools", "-nt"):
        command += ["--tools", ",".join(READ_ONLY_TOOLS)]
    command += pi_flags
    command += ["--append-system-prompt", str(system_prompt)]
    return command


def session_files(run_dir: Path) -> list[Path]:
    sessions = run_dir / "sessions"
    if not sessions.is_dir():
        return []
    return sorted(sessions.rglob("*.jsonl"))


def print_provenance(
    run_id: str,
    run_dir: Path,
    session_dir: Path,
    session_file: Path | None,
    cwd: Path,
    agent_dir: Path,
    pi_flags: list[str],
    prompt_path: Path,
    command: list[str],
    manual: list[str],
) -> None:
    eprint(f"run: {run_id}")
    eprint(f"run-dir: {run_dir}")
    eprint(f"session-dir: {session_dir}")
    if session_file is not None:
        eprint(f"session: {session_file}")
    eprint(f"cwd: {cwd}")
    eprint(f"agent-dir: {agent_dir}")
    if pi_flags:
        eprint(f"pi-flags: {shlex.join(pi_flags)}")
    eprint(f"prompt: {prompt_path}")
    eprint("command:")
    eprint("  " + shlex.join(command))
    eprint("manual resume:")
    eprint("  " + shlex.join(manual))


def print_dry_run(
    command: list[str], system_prompt: str, agent_dir: Path, prompt: bytes
) -> None:
    print("# input: piped input follows the task words after `--`")
    print()
    print("# env")
    print(f"PI_CODING_AGENT_DIR={agent_dir}")
    print()
    print("# command")
    print(shlex.join(command))
    print()
    lines = prompt.decode(errors="replace").splitlines()
    print(f"# prompt: {len(prompt)} bytes, {len(lines)} lines")
    for line in lines[:20]:
        print(line)
    if len(lines) > 20:
        print(f"# ... ({len(lines) - 20} more lines)")
    print()
    print("# system prompt")
    print(system_prompt, end="" if system_prompt.endswith("\n") else "\n")


def run_child(
    command: list[str],
    prompt: bytes,
    cwd: Path,
    agent_dir: Path,
    show_stderr: bool = False,
) -> int:
    env = dict(os.environ)
    env["PI_CODING_AGENT_DIR"] = str(agent_dir)
    kwargs: dict[str, object] = {
        "cwd": str(cwd),
        "stdout": subprocess.PIPE,
        "stderr": subprocess.PIPE,
        "env": env,
        "input": prompt,
    }
    try:
        result = subprocess.run(command, **kwargs)
    except OSError as exc:
        die(f"cannot run pi: {exc}")
    if result.stdout:
        sys.stdout.buffer.write(result.stdout)
        sys.stdout.buffer.flush()
    code = result.returncode
    if code < 0:
        code = 128 + (-code)
    if result.stderr and (code != 0 or show_stderr):
        sys.stderr.buffer.write(result.stderr)
        sys.stderr.buffer.flush()
    return code


def save_follow_up(run_dir: Path, prompt: bytes) -> Path:
    followups = run_dir / "followups"
    followups.mkdir(parents=True, exist_ok=True, mode=0o700)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    for index in range(1, 100):
        path = followups / f"{stamp}-{index:02d}.md"
        if not path.exists():
            atomic_write(path, prompt)
            return path
    die("could not allocate a follow-up file")


def parse_args(argv: list[str]) -> argparse.Namespace:
    argv, prompt_words = split_argv(list(argv))
    if "--prompt" in argv or any(a.startswith("--prompt=") for a in argv):
        die("run.py no longer takes --prompt; pass the task as words after `--`")
    parser = argparse.ArgumentParser(
        prog="run.py",
        description="Run a task in a separate, read-only-by-default pi process.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        allow_abbrev=False,
        epilog=(
            "Unrecognized flags are forwarded to pi (bare words before `--`\n"
            "are rejected), except the session, mode, trust, and\n"
            "resource-loading flags run.py manages.\n"
            "The child is read-only by default (read,grep,find,ls).\n"
            "\n"
            "Write the task as words after `--`, like pi itself; piped input\n"
            "follows the task. --resume without an ID resumes the latest run.\n"
            "\n"
            f"Conventions for prompts, output, and resume: {SKILL_DIR / 'SKILL.md'}\n"
        ),
    )
    parser.add_argument(
        "--run-id",
        metavar="ID",
        help="run ID; default is timestamp + random",
    )
    parser.add_argument(
        "--state-dir",
        metavar="DIR",
        help="run storage; default is ${XDG_STATE_HOME:-~/.local/state}/pi/subagents",
    )
    parser.add_argument(
        "--info",
        action="store_true",
        help="print provenance and the child's stderr; default is the answer alone",
    )
    parser.add_argument(
        "--resume",
        nargs="?",
        const="last",
        metavar="RUN_ID",
        help="send a follow-up to an existing run; default is the most recent",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the command, agent dir, and system prompt without running",
    )
    args, pi_flags = parser.parse_known_args(argv)
    args.pi_flags = pi_flags
    args.prompt_words = prompt_words
    reject_bare_words(pi_flags)
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if shutil.which("pi") is None:
        die("pi not found in PATH")
    os.umask(0o077)
    state_dir = resolve_state_dir(args.state_dir)

    if args.resume:
        forbidden: list[str] = []
        if args.run_id is not None:
            forbidden.append("--run-id")
        if args.pi_flags:
            forbidden.append("pi flags")
        if forbidden:
            die("--resume cannot change the run: " + ", ".join(forbidden))

        run_id = resolve_resume_id(state_dir, args.resume)
        run_dir = state_dir / run_id
        if not run_dir.is_dir():
            die(f"run dir not found: {run_dir}")
        meta = load_meta(run_dir)
        if meta["run_id"] != run_id:
            die(f"meta.json run_id does not match {run_id}")
        session_id = str(meta["session_id"])
        pi_flags = meta_pi_flags(meta)
        cwd = Path(str(meta["cwd"]))
        if not cwd.is_dir():
            die(f"run cwd is not a directory: {cwd}")
        agent_dir = run_dir / "agent"
        session_dir = run_dir / "sessions"
        files = session_files(run_dir)
        if not files:
            die(f"session not found under {session_dir}")
        if len(files) != 1:
            die(f"expected one session file under {session_dir}, found {len(files)}")
        system_prompt_path = run_dir / "system-prompt.md"
        if not system_prompt_path.is_file():
            die(f"system prompt not found: {system_prompt_path}")
        system_prompt = system_prompt_path.read_text()
        prompt = read_input(args.prompt_words)
        command = build_command(
            session_id,
            session_dir,
            pi_flags,
            system_prompt_path,
            True,
        )
        manual = manual_command(
            session_id,
            session_dir,
            pi_flags,
            system_prompt_path,
        )
        if args.dry_run:
            print_dry_run(command, system_prompt, agent_dir, prompt)
            return 0
        prepare_agent_dir(agent_dir, source_agent_dir())
        follow_up = save_follow_up(run_dir, prompt)
        if args.info:
            print_provenance(
                run_id,
                run_dir,
                session_dir,
                files[0],
                cwd,
                agent_dir,
                pi_flags,
                follow_up,
                command,
                manual,
            )
        write_latest(state_dir, run_id)
        return run_child(command, prompt, cwd, agent_dir, args.info)

    validate_pi_flags(args.pi_flags)
    if not has_flag(args.pi_flags, "--model"):
        die("a new run needs --model")
    cwd = Path.cwd().resolve()
    prompt = read_input(args.prompt_words)
    system_prompt = build_system_prompt()
    run_id = validate_run_id(args.run_id) if args.run_id else unique_run_id(state_dir)
    run_dir = state_dir / run_id
    if run_dir.exists():
        die(f"run dir already exists: {run_dir}")
    agent_dir = run_dir / "agent"
    session_dir = run_dir / "sessions"
    session_id = run_id
    system_prompt_path = run_dir / "system-prompt.md"
    command = build_command(
        session_id,
        session_dir,
        args.pi_flags,
        system_prompt_path,
        False,
    )
    manual = manual_command(
        session_id,
        session_dir,
        args.pi_flags,
        system_prompt_path,
    )
    if args.dry_run:
        print_dry_run(command, system_prompt, agent_dir, prompt)
        return 0

    state_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    run_dir.mkdir(mode=0o700)
    (run_dir / "followups").mkdir(mode=0o700)
    (run_dir / "sessions").mkdir(mode=0o700)
    prepare_agent_dir(agent_dir, source_agent_dir())
    atomic_write(run_dir / "prompt.md", prompt)
    atomic_write(system_prompt_path, system_prompt.encode())
    meta = {
        "schema": 4,
        "run_id": run_id,
        "session_id": session_id,
        "cwd": str(cwd),
        "pi_flags": args.pi_flags,
        "created": now_iso(),
    }
    write_meta(run_dir, meta)
    write_latest(state_dir, run_id)
    if args.info:
        print_provenance(
            run_id,
            run_dir,
            session_dir,
            None,
            cwd,
            agent_dir,
            args.pi_flags,
            run_dir / "prompt.md",
            command,
            manual,
        )
    code = run_child(command, prompt, cwd, agent_dir, args.info)
    if args.info:
        files = session_files(run_dir)
        if len(files) == 1:
            eprint(f"session: {files[0]}")
        elif len(files) > 1:
            eprint(f"session: multiple files under {session_dir}")
            for path in files:
                eprint(f"  {path}")
        else:
            eprint(f"session: none created under {session_dir}")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
