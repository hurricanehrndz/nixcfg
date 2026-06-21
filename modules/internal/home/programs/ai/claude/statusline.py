#!/usr/bin/env python3
"""
Claude status line renderer.
Powerline-style display with model, branch, path, and context usage.

Invoked by Claude Code with session JSON on stdin; see settings.json
`statusLine.command`. Kept dependency-free so it runs under a plain
python3 (no uv/venv required).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

# Powerline symbols
PL_RIGHT = ""

# ANSI color codes - Background colors
BG_BLUE = "\033[44m"
BG_GREEN = "\033[42m"
BG_MAGENTA = "\033[45m"
BG_CYAN = "\033[46m"

# ANSI color codes - Foreground colors
FG_BLUE = "\033[34m"
FG_GREEN = "\033[32m"
FG_MAGENTA = "\033[35m"
FG_CYAN = "\033[36m"
FG_BLACK = "\033[30m"

BOLD = "\033[1m"
RESET = "\033[0m"


def get_git_branch(cwd: str | None = None) -> str | None:
    """Get current git branch."""
    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            cwd=cwd,
            text=True,
            timeout=1,
        )
        if result.returncode == 0:
            branch = result.stdout.strip()
            if branch:
                return branch
    except Exception:
        pass

    # Fallback: try reading .git/HEAD
    try:
        git_head = Path(cwd or ".") / ".git" / "HEAD"
        if git_head.exists():
            content = git_head.read_text().strip()
            if content.startswith("ref: refs/heads/"):
                return content.replace("ref: refs/heads/", "")
    except Exception:
        pass

    return None


def shorten_path(path: str, max_length: int = 20) -> str:
    """Shorten a path for display."""
    if not path:
        return "~"

    # Replace home directory with ~
    home = str(Path.home())
    if path.startswith(home):
        path = "~" + path[len(home) :]

    # If still too long, show only last parts
    if len(path) > max_length:
        parts = path.split(os.sep)
        if len(parts) > 2:
            return f"{parts[0]}/.../{parts[-1]}"

    return path


def generate_status_line(input_data: dict) -> str:
    """Generate the powerline status line."""
    # Get model name
    model_info = input_data.get("model", {})
    model_name = model_info.get("display_name", "Claude")

    # Get workspace info
    workspace = input_data.get("workspace", {})
    current_dir = workspace.get("current_dir", os.getcwd())
    short_path = shorten_path(current_dir)

    # Get context usage
    context_data = input_data.get("context_window", {})
    used_percentage = context_data.get("used_percentage", 0) or 0

    # Get git branch
    git_branch = get_git_branch(current_dir)

    # Build powerline segments
    segments = []

    # Segment 1: Model name (blue background)
    segments.append(f"{BG_BLUE}{FG_BLACK}{BOLD} {model_name} {RESET}")
    segments.append(f"{FG_BLUE}{BG_GREEN}{PL_RIGHT}{RESET}")

    # Segment 2: Git branch (green background) - only if in git repo
    if git_branch:
        segments.append(f"{BG_GREEN}{FG_BLACK} {git_branch} {RESET}")
        segments.append(f"{FG_GREEN}{BG_MAGENTA}{PL_RIGHT}{RESET}")
    else:
        segments.append(f"{FG_GREEN}{BG_MAGENTA}{PL_RIGHT}{RESET}")

    # Segment 3: Path (magenta background)
    segments.append(f"{BG_MAGENTA}{FG_BLACK} {short_path} {RESET}")
    segments.append(f"{FG_MAGENTA}{BG_CYAN}{PL_RIGHT}{RESET}")

    # Segment 4: Context usage (cyan background)
    segments.append(f"{BG_CYAN}{FG_BLACK} {used_percentage:.0f}% {RESET}")
    segments.append(f"{FG_CYAN}{PL_RIGHT}{RESET}")

    return "".join(segments)


def main() -> None:
    try:
        # Read JSON input from stdin
        input_data = json.loads(sys.stdin.read())

        # Generate status line
        status_line = generate_status_line(input_data)

        # Output the status line directly (not wrapped in JSON)
        print(status_line)
        sys.exit(0)

    except Exception:
        # Handle errors gracefully with a simple error indicator
        print(f"{BG_MAGENTA}{FG_BLACK} Error {RESET}{FG_MAGENTA}{PL_RIGHT}{RESET}")
        sys.exit(0)


if __name__ == "__main__":
    main()
