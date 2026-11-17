#!/usr/bin/env python3
"""Run a task in a separate pi process, on material the caller supplies.

The launcher owns the run directory and session; it does not write a vault
artifact. stdout is the child's final text. stderr stays quiet unless the child
fails or --info is passed. Every run also prints one `run: ID` line to stderr,
so the caller can name the run for a follow-up.

A run is three things the caller supplies: a task system-prompt file, one
brief, and ordered --ref files. The launcher prepends the common prompt to the
task prompt and passes the text, not a path, as pi's --system-prompt. It
attaches each --ref as a pi @FILE positional argument and sends the brief on
stdin. The child is read-less (--no-tools): the caller selects the material,
the child analyzes it.
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
COMMON_PROMPT = SKILL_DIR / "references" / "prompts" / "common.md"
PROMPTS_DIR = SKILL_DIR / "references" / "prompts"
RUN_ID_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?$")
LATEST_FILE = "latest"
RUN_FORMAT = 2
REQUIRED_META = (
    "run_id",
    "session_id",
    "cwd",
    "created",
)
SYSTEM_PROMPT_MARKER = "<composed-system-prompt>"
CHILD_FLAGS = (
    "--no-approve",
    "--no-context-files",
    "--no-extensions",
    "--no-mcp",
    "--no-skills",
    "--no-prompt-templates",
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
    "--prompt-template",
    "--system-prompt",
    "--append-system-prompt",
    "--skill",
    "--tools",
    "-t",
    "--no-tools",
    "-nt",
    "--exclude-tools",
    "-xt",
    "--no-builtin-tools",
    "-nbt",
}
PROMPT_AND_TOOL_FLAGS = {
    "--system-prompt",
    "--append-system-prompt",
    "--skill",
    "--tools",
    "-t",
    "--no-tools",
    "-nt",
    "--exclude-tools",
    "-xt",
    "--no-builtin-tools",
    "-nbt",
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
    """Split argv at the first bare `--`: left goes to argparse/pi, right is the brief."""
    if "--" in argv:
        i = argv.index("--")
        return argv[:i], argv[i + 1 :]
    return argv, []


def strip_frontmatter(text: str) -> str:
    """Remove a leading YAML frontmatter block (`---` ... `---`).

    A caller's task prompt may carry a header the model does not need; drop
    it at runtime while the file keeps it.
    """
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return text
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return "".join(lines[i + 1 :]).lstrip("\n")
    return text


def load_prompt_file(path: str) -> str:
    file = Path(path).expanduser()
    try:
        text = file.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        die(f"cannot read --prompt {path}: {exc}")
    return strip_frontmatter(text).rstrip() + "\n"


def compose_system_prompt(prompt_path: str) -> tuple[str, Path]:
    """Return the combined prompt text and the task prompt it came from."""
    try:
        common = COMMON_PROMPT.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        die(f"cannot read the common prompt {COMMON_PROMPT}: {exc}")
    source = Path(prompt_path).expanduser().resolve()
    return common.rstrip() + "\n\n" + load_prompt_file(str(source)), source


def read_input(brief_words: list[str]) -> bytes:
    """Compose the one user message: the brief, then any piped text.

    The returned bytes are both the saved record and pi's stdin, so the child
    sees exactly what the run dir records. References travel as pi @FILE
    arguments instead; pi groups their contents with this message.
    """
    stdin_data = b""
    if not sys.stdin.isatty():
        stdin_data = sys.stdin.buffer.read()
    brief = " ".join(brief_words).strip()
    if stdin_data.strip() and brief:
        prompt = brief.encode() + b"\n\n" + stdin_data.lstrip(b"\r\n").rstrip()
    elif brief:
        prompt = brief.encode()
    elif stdin_data.strip():
        prompt = stdin_data.lstrip(b"\r\n").rstrip()
    else:
        die("no brief: pass words after `--` or pipe the brief")
    return prompt


def resolve_refs(values: list[str] | None) -> list[Path]:
    """Resolve --ref values to absolute files, in the order given."""
    refs: list[Path] = []
    for value in values or []:
        path = Path(value).expanduser().resolve()
        if not path.is_file():
            die(f"--ref is not a file: {value}")
        refs.append(path)
    return refs


def ref_args(refs: list[Path]) -> list[str]:
    return [f"@{path}" for path in refs]


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
    """Die on words before `--` that would never become the brief.

    Bare words would reach pi as extra messages, and `@file` words as
    attachments. Unknown flags are assumed to take a value, mirroring pi's own
    unknown-flag consumption.
    """
    i = 0
    while i < len(pi_flags):
        tok = pi_flags[i]
        if tok.startswith("@"):
            die(f"bare {tok!r} before `--` is forwarded to pi as an attachment; use --ref FILE")
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
        die(f"bare word {tok!r} before `--` never becomes the brief; put it after `--`")


def has_flag(pi_flags: list[str], *names: str) -> bool:
    for flag in pi_flags:
        if flag.split("=", 1)[0] in names:
            return True
    return False


def parent_model_flags() -> list[str]:
    """Default `--model` to the parent pi session's provider and model."""
    model = os.environ.get("PI_MODEL", "").strip()
    if not model:
        return []
    provider = os.environ.get("PI_PROVIDER", "").strip()
    return ["--model", f"{provider}/{model}" if provider else model]


def validate_pi_flags(pi_flags: list[str]) -> None:
    for flag in pi_flags:
        name = flag.split("=", 1)[0]
        if name in PROMPT_AND_TOOL_FLAGS:
            die(
                f"the child's prompt and tool policy are fixed "
                f"(--no-tools); do not pass {name}"
            )
        if name in RESERVED_PI_FLAGS:
            die(f"run.py manages {name}; do not pass it to the child")


def meta_pi_flags(meta: dict) -> list[str]:
    value = meta.get("pi_flags")
    if not isinstance(value, list) or not value:
        die("meta.json has no pi_flags to resume from")
    return [str(item) for item in value]


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


def record_turn(
    meta: dict, run_dir: Path, brief_file: Path, refs: list[Path]
) -> None:
    turns = meta.setdefault("turns", [])
    if not isinstance(turns, list):
        die("meta.json turns is not a list")
    turns.append(
        {
            "brief": str(brief_file.relative_to(run_dir)),
            "refs": [str(path) for path in refs],
            "created": now_iso(),
        }
    )


def build_command(
    session_id: str,
    session_dir: Path,
    pi_flags: list[str],
    system_prompt: str,
    refs: list[Path],
    resume: bool,
) -> list[str]:
    command = ["pi", "--print", "--session-dir", str(session_dir)]
    if resume:
        command += ["--session", session_id]
    else:
        command += ["--session-id", session_id]
    command += CHILD_FLAGS
    command += ["--no-tools"]
    command += pi_flags
    command += ["--system-prompt", system_prompt]
    if refs:
        command += ["--"] + ref_args(refs)
    return command


def manual_command(
    session_id: str,
    session_dir: Path,
    pi_flags: list[str],
    system_prompt: str,
    refs: list[Path],
) -> list[str]:
    command = [
        "pi",
        "--session-dir",
        str(session_dir),
        "--session",
        session_id,
    ]
    command += CHILD_FLAGS
    command += ["--no-tools"]
    command += pi_flags
    command += ["--system-prompt", system_prompt]
    if refs:
        command += ["--"] + ref_args(refs)
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
    refs: list[Path],
    system_prompt_path: Path,
    task_prompt: str | None,
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
    eprint(f"system-prompt: {system_prompt_path}")
    eprint(f"task-prompt: {task_prompt or 'run record'}")
    eprint(f"brief: {prompt_path}")
    eprint(f"refs: {' '.join(str(path) for path in refs) or 'none'}")
    eprint("command:")
    eprint("  " + shlex.join(command))
    eprint("manual resume:")
    eprint("  " + shlex.join(manual))


def print_dry_run(
    command: list[str],
    system_prompt: str,
    agent_dir: Path,
    prompt: bytes,
    refs: list[Path],
    task_prompt: str | None,
) -> None:
    print("# refs (attached in this order)")
    if refs:
        for path in refs:
            print(f"@{path}")
    else:
        print("(none)")
    print()
    print("# env")
    print(f"PI_CODING_AGENT_DIR={agent_dir}")
    print()
    print("# command")
    print(
        shlex.join(
            [
                SYSTEM_PROMPT_MARKER if item == system_prompt else item
                for item in command
            ]
        )
    )
    print()
    lines = prompt.decode(errors="replace").splitlines()
    print(f"# brief: {len(prompt)} bytes, {len(lines)} lines (sent on stdin)")
    for line in lines[:20]:
        print(line)
    if len(lines) > 20:
        print(f"# ... ({len(lines) - 20} more lines)")
    print()
    print(f"# system prompt: {COMMON_PROMPT} + {task_prompt or 'run record'}")
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
    argv, brief_words = split_argv(list(argv))
    parser = argparse.ArgumentParser(
        prog="run.py",
        description=(
            "Run a task in a separate pi process on material the caller supplies."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        allow_abbrev=False,
        epilog=(
            "A new run takes a task system-prompt file with --prompt FILE,\n"
            "one brief, and ordered references with repeated --ref FILE. The\n"
            "launcher prepends the common prompt, passes the composed text as\n"
            "pi's --system-prompt, and attaches each --ref as a pi @FILE\n"
            "argument. The child is read-less (--no-tools); --ref takes a\n"
            "file, not a glob.\n"
            "\n"
            "The brief is words after `--`, piped input, or both, joined into\n"
            "one user message. A resume keeps the run's system prompt and\n"
            "tool policy and takes a new brief and --ref list.\n"
            "\n"
            "Unrecognized flags are forwarded to pi (bare words before `--`\n"
            "are rejected), except the session, mode, trust, tool, prompt,\n"
            "and resource-loading flags run.py manages.\n"
            "\n"
            f"Built-in task prompts: {PROMPTS_DIR}\n"
            f"Conventions for prompts, output, and resume: {SKILL_DIR / 'SKILL.md'}\n"
        ),
    )
    parser.add_argument(
        "--prompt",
        metavar="FILE",
        help="task system-prompt file for a new run; the common prompt is prepended",
    )
    parser.add_argument(
        "--ref",
        metavar="FILE",
        action="append",
        help="input file to attach, in order; repeatable, new runs and resumes",
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
        help="print full provenance and the child's stderr",
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
        help="print the command, refs, brief, and composed system prompt without running",
    )
    args, pi_flags = parser.parse_known_args(argv)
    args.pi_flags = pi_flags
    args.brief_words = brief_words
    reject_bare_words(pi_flags)
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if shutil.which("pi") is None:
        die("pi not found in PATH")
    os.umask(0o077)
    state_dir = resolve_state_dir(args.state_dir)
    refs = resolve_refs(args.ref)

    if args.resume:
        forbidden: list[str] = []
        if args.run_id is not None:
            forbidden.append("--run-id")
        if args.prompt is not None:
            forbidden.append("--prompt")
        if args.pi_flags:
            forbidden.append("pi flags")
        if forbidden:
            die(
                "--resume keeps the run's system prompt and tool policy; "
                "do not pass: " + ", ".join(forbidden)
            )

        run_id = resolve_resume_id(state_dir, args.resume)
        run_dir = state_dir / run_id
        if not run_dir.is_dir():
            die(f"run dir not found: {run_dir}")
        meta = load_meta(run_dir)
        if str(meta.get("format")) != str(RUN_FORMAT):
            die(
                f"run {run_id} uses run format {meta.get('format', 'none')}, "
                f"not the current format {RUN_FORMAT}; start a new run"
            )
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
        prompt = read_input(args.brief_words)
        command = build_command(
            session_id,
            session_dir,
            pi_flags,
            system_prompt,
            refs,
            True,
        )
        manual = manual_command(
            session_id,
            session_dir,
            pi_flags,
            system_prompt,
            refs,
        )
        if args.dry_run:
            print_dry_run(
                command,
                system_prompt,
                agent_dir,
                prompt,
                refs,
                str(meta.get("task_prompt") or ""),
            )
            return 0
        prepare_agent_dir(agent_dir, source_agent_dir())
        follow_up = save_follow_up(run_dir, prompt)
        record_turn(meta, run_dir, follow_up, refs)
        write_meta(run_dir, meta)
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
                refs,
                system_prompt_path,
                str(meta.get("task_prompt") or ""),
                command,
                manual,
            )
        write_latest(state_dir, run_id)
        if not args.info:
            eprint(f"run: {run_id}")
        return run_child(command, prompt, cwd, agent_dir, args.info)

    validate_pi_flags(args.pi_flags)
    if args.prompt is None:
        die("a new run needs --prompt FILE (the task system prompt)")
    if not has_flag(args.pi_flags, "--model"):
        args.pi_flags = parent_model_flags() + args.pi_flags
    if not has_flag(args.pi_flags, "--model"):
        die("a new run needs --model (PI_MODEL is unset)")
    cwd = Path.cwd().resolve()
    prompt = read_input(args.brief_words)
    system_prompt, task_prompt = compose_system_prompt(args.prompt)
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
        system_prompt,
        refs,
        False,
    )
    manual = manual_command(
        session_id,
        session_dir,
        args.pi_flags,
        system_prompt,
        refs,
    )
    if args.dry_run:
        print_dry_run(
            command,
            system_prompt,
            agent_dir,
            prompt,
            refs,
            str(task_prompt),
        )
        return 0

    state_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    run_dir.mkdir(mode=0o700)
    (run_dir / "followups").mkdir(mode=0o700)
    (run_dir / "sessions").mkdir(mode=0o700)
    prepare_agent_dir(agent_dir, source_agent_dir())
    atomic_write(run_dir / "prompt.md", prompt)
    atomic_write(system_prompt_path, system_prompt.encode())
    meta = {
        "format": RUN_FORMAT,
        "run_id": run_id,
        "session_id": session_id,
        "cwd": str(cwd),
        "created": now_iso(),
        "task_prompt": str(task_prompt),
        "pi_flags": args.pi_flags,
    }
    record_turn(meta, run_dir, run_dir / "prompt.md", refs)
    write_meta(run_dir, meta)
    write_latest(state_dir, run_id)
    if not args.info:
        eprint(f"run: {run_id}")
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
            refs,
            system_prompt_path,
            str(task_prompt),
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
