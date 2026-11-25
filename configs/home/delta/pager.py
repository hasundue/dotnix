#!/usr/bin/env python3
"""Choose delta's layout from the available terminal width."""

import os
import shutil
import sys

SIDE_BY_SIDE_MIN_WIDTH = 140


def parse_args(args):
    width = None
    delta_args = []
    index = 0
    while index < len(args):
        arg = args[index]
        if arg == "--width" and index + 1 < len(args):
            width = int(args[index + 1])
            index += 2
        elif arg.startswith("--width="):
            width = int(arg.split("=", 1)[1])
            index += 1
        else:
            delta_args.append(arg)
            index += 1
    if width is None:
        width = shutil.get_terminal_size((80, 24)).columns
    return width, delta_args


def main():
    width, delta_args = parse_args(sys.argv[1:])
    if width < SIDE_BY_SIDE_MIN_WIDTH:
        # Without a gutter the terminal can soft-wrap at column 0 harmlessly.
        layout = ["--side-by-side=false", "--line-numbers=false"]
    else:
        layout = ["--side-by-side=true"]
    command = (
        [os.environ.get("DELTA_BIN", "delta")]
        + delta_args
        + [f"--width={width}"]
        + layout
    )
    os.execvp(command[0], command)


if __name__ == "__main__":
    main()
