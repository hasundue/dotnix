#!/usr/bin/env python3
"""Run a task in a separate pi process, on material the caller supplies.

The launcher owns the session directory; it does not write a vault artifact.
stdout is the child's final text, preceded by one blank line on stderr when it
is non-empty. stderr otherwise stays quiet unless the child fails or --info is
passed, and every run prints one `session: ID (new|resumed)` line there, so the
caller can name the session for a follow-up.

A session is three things the caller supplies: a task system-prompt file
(--system-prompt), one message, and attachments named @FILE. The launcher
prepends the common prompt to the task prompt and passes the text, not a path,
as pi's --system-prompt. It attaches each @FILE as a pi positional argument and
sends the message on stdin. The child is read-less (--no-tools): the caller
selects the material, the child analyzes it.

The session dir is <state-dir>/<session-id>/, and its name must equal the
session ID. It holds meta.json (the meta format, session ID, cwd, source
prompt, pi flags, and one entry per turn: message file, refs, model, and
thinking level), the message as prompt.md or followups/*.md, the composed
system prompt as system-prompt.md, pi's own session files under sessions/, and
the child's agent dir. A run_id or task_prompt left by an older launcher is
ignored.
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
SESSION_ID_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?$")
META_FORMAT = 2
REQUIRED_META = (
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
        die(f"cannot read --system-prompt {path}: {exc}")
    return strip_frontmatter(text).rstrip() + "\n"


def compose_system_prompt(prompt_path: str) -> tuple[str, Path]:
    """Return the combined prompt text and the task prompt it came from."""
    try:
        common = COMMON_PROMPT.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        die(f"cannot read the common prompt {COMMON_PROMPT}: {exc}")
    source = Path(prompt_path).expanduser().resolve()
    return common.rstrip() + "\n\n" + load_prompt_file(str(source)), source


def read_message(message_words: list[str]) -> bytes:
    """Compose the one user message: the message, then any piped text.

    The returned bytes are both the saved record and pi's stdin, so the child
    sees exactly what the session dir records. References travel as pi @FILE
    arguments instead; pi groups their contents with this message.
    """
    stdin_data = b""
    if not sys.stdin.isatty():
        stdin_data = sys.stdin.buffer.read()
    message = " ".join(message_words).strip()
    if stdin_data.strip() and message:
        prompt = message.encode() + b"\n\n" + stdin_data.lstrip(b"\r\n").rstrip()
    elif message:
        prompt = message.encode()
    elif stdin_data.strip():
        prompt = stdin_data.lstrip(b"\r\n").rstrip()
    else:
        die("no message: pass words or pipe the message")
    return prompt


def resolve_refs(words: list[str]) -> list[Path]:
    """Resolve @FILE words to absolute files, in the order given."""
    refs: list[Path] = []
    for word in words:
        path = Path(word[1:]).expanduser().resolve()
        if not path.is_file():
            die(f"an argument starting with `@` is an attachment; {word} is not a file")
        refs.append(path)
    return refs


def split_words(words: list[str]) -> tuple[list[str], list[Path]]:
    """Split positional words into message words, in order, and @FILE refs."""
    message_words: list[str] = []
    ref_words: list[str] = []
    for word in words:
        if word.startswith("@") and len(word) > 1:
            ref_words.append(word)
        else:
            message_words.append(word)
    return message_words, resolve_refs(ref_words)


def ref_args(refs: list[Path]) -> list[str]:
    return [f"@{path}" for path in refs]


def flag_value(flags: list[str], name: str) -> str | None:
    for index, token in enumerate(flags):
        if token == name and index + 1 < len(flags):
            return flags[index + 1]
        if token.startswith(name + "="):
            return token.split("=", 1)[1]
    return None


def set_flag(flags: list[str], name: str, value: str) -> list[str]:
    """Return the flags with `name` set, replacing an existing entry."""
    out: list[str] = []
    index = 0
    while index < len(flags):
        token = flags[index]
        if token == name:
            index += 2
            continue
        if token.startswith(name + "="):
            index += 1
            continue
        out.append(token)
        index += 1
    return [*out, name, value]


def compose_flags(model: str | None, thinking: str | None) -> list[str]:
    flags: list[str] = []
    if model:
        flags += ["--model", model]
    if thinking:
        flags += ["--thinking", thinking]
    return flags


def parent_model() -> str | None:
    """Default `--model` to the parent pi session's provider and model."""
    model = os.environ.get("PI_MODEL", "").strip()
    if not model:
        return None
    provider = os.environ.get("PI_PROVIDER", "").strip()
    return f"{provider}/{model}" if provider else model


def meta_pi_flags(meta: dict) -> list[str]:
    value = meta.get("pi_flags")
    if not isinstance(value, list) or not value:
        die("meta.json has no pi_flags to resume from")
    return [str(item) for item in value]


def make_session_id() -> str:
    return datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + secrets.token_hex(3)


def validate_session_id(session_id: str) -> str:
    if not SESSION_ID_RE.fullmatch(session_id):
        die(
            f"invalid session ID: {session_id!r} "
            "(use [A-Za-z0-9._-], start and end alphanumeric)"
        )
    return session_id


def unique_session_id(state_dir: Path) -> str:
    for _ in range(16):
        session_id = make_session_id()
        if not (state_dir / session_id).exists():
            return session_id
    die("could not generate a unique session ID")


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


def write_meta(session_dir: Path, meta: dict) -> None:
    content = json.dumps(meta, indent=2, ensure_ascii=False) + "\n"
    atomic_write(session_dir / "meta.json", content.encode())


def load_meta(session_dir: Path) -> dict:
    path = session_dir / "meta.json"
    if not path.is_file():
        die(f"meta.json not found in {session_dir}")
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
    meta: dict,
    session_dir: Path,
    message_file: Path,
    refs: list[Path],
    pi_flags: list[str],
) -> None:
    turns = meta.setdefault("turns", [])
    if not isinstance(turns, list):
        die("meta.json turns is not a list")
    turns.append(
        {
            "message": str(message_file.relative_to(session_dir)),
            "refs": [str(path) for path in refs],
            "created": now_iso(),
            "model": flag_value(pi_flags, "--model"),
            "thinking": flag_value(pi_flags, "--thinking"),
        }
    )


def build_command(
    session_id: str,
    pi_session_dir: Path,
    pi_flags: list[str],
    system_prompt: str,
    refs: list[Path],
    resume: bool,
) -> list[str]:
    command = ["pi", "--print", "--session-dir", str(pi_session_dir)]
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
    pi_session_dir: Path,
    pi_flags: list[str],
    system_prompt: str,
    refs: list[Path],
) -> list[str]:
    command = [
        "pi",
        "--session-dir",
        str(pi_session_dir),
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


def pi_session_files(session_dir: Path) -> list[Path]:
    sessions = session_dir / "sessions"
    if not sessions.is_dir():
        return []
    return sorted(sessions.rglob("*.jsonl"))


def print_provenance(
    session_id: str,
    session_state: str,
    session_dir: Path,
    pi_session_dir: Path,
    pi_session_file: Path | None,
    cwd: Path,
    agent_dir: Path,
    pi_flags: list[str],
    message_path: Path,
    refs: list[Path],
    system_prompt_path: Path,
    prompt_source: str | None,
    command: list[str],
    manual: list[str],
) -> None:
    eprint(f"session: {session_id} ({session_state})")
    eprint(f"session-dir: {session_dir}")
    eprint(f"pi-session-dir: {pi_session_dir}")
    if pi_session_file is not None:
        eprint(f"pi-session: {pi_session_file}")
    eprint(f"cwd: {cwd}")
    eprint(f"agent-dir: {agent_dir}")
    if pi_flags:
        eprint(f"pi-flags: {shlex.join(pi_flags)}")
    eprint(f"system-prompt: {system_prompt_path}")
    eprint(f"prompt-source: {prompt_source or 'session record'}")
    eprint(f"message: {message_path}")
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
    prompt_source: str | None,
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
    print(f"# message: {len(prompt)} bytes, {len(lines)} lines (sent on stdin)")
    for line in lines[:20]:
        print(line)
    if len(lines) > 20:
        print(f"# ... ({len(lines) - 20} more lines)")
    print()
    print(f"# system prompt: {COMMON_PROMPT} + {prompt_source or 'session record'}")
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
        # The session line, and any --info provenance, end just above the
        # answer; keep the two apart, but only when there is one.
        eprint()
        sys.stdout.buffer.write(result.stdout)
        sys.stdout.buffer.flush()
    code = result.returncode
    if code < 0:
        code = 128 + (-code)
    if result.stderr and (code != 0 or show_stderr):
        sys.stderr.buffer.write(result.stderr)
        sys.stderr.buffer.flush()
    return code


def save_follow_up(session_dir: Path, prompt: bytes) -> Path:
    followups = session_dir / "followups"
    followups.mkdir(parents=True, exist_ok=True, mode=0o700)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    for index in range(1, 100):
        path = followups / f"{stamp}-{index:02d}.md"
        if not path.exists():
            atomic_write(path, prompt)
            return path
    die("could not allocate a follow-up file")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="run.py",
        description=(
            "Run a task in a separate pi process on material the caller supplies."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        allow_abbrev=False,
        epilog=(
            "A new session takes a task system-prompt file with --system-prompt\n"
            "FILE, one message, and attachments named @FILE. The launcher\n"
            "prepends the common prompt, passes the composed text as pi's\n"
            "--system-prompt, and attaches each @FILE as a pi positional\n"
            "argument. The child is read-less (--no-tools); @FILE takes a file,\n"
            "not a glob.\n"
            "\n"
            "Bare words are the message. `--` ends option parsing, as in pi, so a\n"
            "message that starts with a dash goes after it. Piped input follows\n"
            "the message in the same prompt.\n"
            "\n"
            "--session-id resumes the existing session of that ID, and creates\n"
            "it otherwise; it takes --model and --thinking to override the\n"
            "recorded model. Unknown flags are an error: nothing is forwarded\n"
            "to pi.\n"
            "\n"
            "stdout is the child's answer alone; the session line, a blank line\n"
            "before the answer, errors, and --info's provenance go to stderr.\n"
            "Piped input is read whenever stdin is not a TTY.\n"
            "\n"
            f"Built-in task prompts: {PROMPTS_DIR}\n"
            f"Conventions for prompts, output, and resume: {SKILL_DIR / 'SKILL.md'}\n"
        ),
    )
    parser.add_argument(
        "--system-prompt",
        metavar="FILE",
        help="task system-prompt file for a new session; the common prompt is prepended",
    )
    parser.add_argument(
        "--model",
        metavar="PATTERN",
        help="model pattern or ID, provider-qualified when needed; default is the parent's for a new session, the recorded one on resume",
    )
    parser.add_argument(
        "--thinking",
        metavar="LEVEL",
        help="thinking level: off, minimal, low, medium, high, xhigh, max",
    )
    parser.add_argument(
        "--session-id",
        metavar="ID",
        help="resume the session with this ID, or create it; default is timestamp + random",
    )
    parser.add_argument(
        "--state-dir",
        metavar="DIR",
        help="session storage; default is ${XDG_STATE_HOME:-~/.local/state}/pi/subagents",
    )
    parser.add_argument(
        "--info",
        action="store_true",
        help="print full provenance and the child's stderr",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="print the command, refs, message, and composed system prompt without running",
    )
    parser.add_argument(
        "words",
        nargs="*",
        metavar="WORD",
        help="message words, and @FILE attachments, in any order",
    )
    return parser.parse_intermixed_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if shutil.which("pi") is None:
        die("pi not found in PATH")
    os.umask(0o077)
    state_dir = resolve_state_dir(args.state_dir)
    message_words, refs = split_words(args.words)

    if args.session_id:
        session_id = validate_session_id(args.session_id)
        resume = (state_dir / session_id).is_dir()
    else:
        session_id = unique_session_id(state_dir)
        resume = False
    session_state = "resumed" if resume else "new"

    if resume:
        if args.system_prompt is not None:
            die(
                "--session-id resumes a session; "
                "do not pass --system-prompt"
            )
        session_dir = state_dir / session_id
        if not session_dir.is_dir():
            die(f"session dir not found: {session_dir}")
        meta = load_meta(session_dir)
        if str(meta.get("format")) != str(META_FORMAT):
            die(
                f"session {session_id} uses meta format "
                f"{meta.get('format', 'none')}, not the current format "
                f"{META_FORMAT}; start a new session"
            )
        if meta["session_id"] != session_id:
            die(f"meta.json session_id does not match {session_id}")
        cwd = Path(str(meta["cwd"]))
        if not cwd.is_dir():
            die(f"session cwd is not a directory: {cwd}")
        agent_dir = session_dir / "agent"
        pi_session_dir = session_dir / "sessions"
        files = pi_session_files(session_dir)
        if not files:
            die(f"session not found under {pi_session_dir}")
        if len(files) != 1:
            die(f"expected one session file under {pi_session_dir}, found {len(files)}")
        system_prompt_path = session_dir / "system-prompt.md"
        if not system_prompt_path.is_file():
            die(f"system prompt not found: {system_prompt_path}")
        system_prompt = system_prompt_path.read_text()
        prompt = read_message(message_words)
        prompt_source = meta.get("system_prompt") or meta.get("task_prompt") or ""
        pi_flags = meta_pi_flags(meta)
        if args.model:
            pi_flags = set_flag(pi_flags, "--model", args.model)
        if args.thinking:
            pi_flags = set_flag(pi_flags, "--thinking", args.thinking)
        meta["pi_flags"] = pi_flags
        command = build_command(
            session_id,
            pi_session_dir,
            pi_flags,
            system_prompt,
            refs,
            True,
        )
        manual = manual_command(
            session_id,
            pi_session_dir,
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
                str(prompt_source),
            )
            return 0
        prepare_agent_dir(agent_dir, source_agent_dir())
        follow_up = save_follow_up(session_dir, prompt)
        record_turn(meta, session_dir, follow_up, refs, pi_flags)
        write_meta(session_dir, meta)
        if args.info:
            print_provenance(
                session_id,
                session_state,
                session_dir,
                pi_session_dir,
                files[0],
                cwd,
                agent_dir,
                pi_flags,
                follow_up,
                refs,
                system_prompt_path,
                str(prompt_source),
                command,
                manual,
            )
        return run_child(command, prompt, cwd, agent_dir, args.info)

    if args.system_prompt is None:
        die("a new session needs --system-prompt FILE (the task system prompt)")
    model = args.model if args.model is not None else parent_model()
    if model is None:
        die("a new session needs --model (PI_MODEL is unset)")
    pi_flags = compose_flags(model, args.thinking)
    cwd = Path.cwd().resolve()
    prompt = read_message(message_words)
    system_prompt, prompt_source = compose_system_prompt(args.system_prompt)
    session_dir = state_dir / session_id
    if session_dir.exists():
        die(f"session dir already exists: {session_dir}")
    agent_dir = session_dir / "agent"
    pi_session_dir = session_dir / "sessions"
    system_prompt_path = session_dir / "system-prompt.md"
    command = build_command(
        session_id,
        pi_session_dir,
        pi_flags,
        system_prompt,
        refs,
        False,
    )
    manual = manual_command(
        session_id,
        pi_session_dir,
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
            str(prompt_source),
        )
        return 0

    state_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    session_dir.mkdir(mode=0o700)
    (session_dir / "followups").mkdir(mode=0o700)
    (session_dir / "sessions").mkdir(mode=0o700)
    prepare_agent_dir(agent_dir, source_agent_dir())
    atomic_write(session_dir / "prompt.md", prompt)
    atomic_write(system_prompt_path, system_prompt.encode())
    meta = {
        "format": META_FORMAT,
        "session_id": session_id,
        "cwd": str(cwd),
        "created": now_iso(),
        "system_prompt": str(prompt_source),
        "pi_flags": pi_flags,
    }
    record_turn(meta, session_dir, session_dir / "prompt.md", refs, pi_flags)
    write_meta(session_dir, meta)
    if not args.info:
        eprint(f"session: {session_id} ({session_state})")
    if args.info:
        print_provenance(
            session_id,
            session_state,
            session_dir,
            pi_session_dir,
            None,
            cwd,
            agent_dir,
            pi_flags,
            session_dir / "prompt.md",
            refs,
            system_prompt_path,
            str(prompt_source),
            command,
            manual,
        )
    code = run_child(command, prompt, cwd, agent_dir, args.info)
    if args.info:
        files = pi_session_files(session_dir)
        if len(files) == 1:
            eprint(f"pi-session: {files[0]}")
        elif len(files) > 1:
            eprint(f"pi-session: multiple files under {pi_session_dir}")
            for path in files:
                eprint(f"  {path}")
        else:
            eprint(f"pi-session: none created under {pi_session_dir}")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
