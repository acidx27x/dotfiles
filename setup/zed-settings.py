#!/usr/bin/env python3
"""Keep Zed's machine-local connections separate from shared settings."""

import argparse
import hashlib
import re
from pathlib import Path


CONFIG_DIR = Path(__file__).resolve().parent.parent / "zed" / ".config" / "zed"
SHARED = CONFIG_DIR / "settings.shared.json"
ACTIVE = CONFIG_DIR / "settings.json"
LOCAL_START = "  // BEGIN LOCAL SETTINGS (this machine only)\n"
LOCAL_END = "  // END LOCAL SETTINGS\n"
SHARED_END = "  // END SHARED SETTINGS\n"
ACTIVE_PATTERN = re.compile(
    r"\A\{\n"
    + re.escape(LOCAL_START)
    + r"(?P<local>.*?)"
    + re.escape(LOCAL_END)
    + r"  // BEGIN SHARED SETTINGS sha256=(?P<hash>[0-9a-f]{64})\n"
    + r"(?P<shared>.*?)"
    + re.escape(SHARED_END)
    + r"\}\n\Z",
    re.DOTALL,
)
DEFAULT_LOCAL = '  "wsl_connections": [],\n  "ssh_connections": [],\n'
CONNECTION_SETTING = re.compile(r'^\s*"(?:ssh_connections|wsl_connections)"\s*:', re.MULTILINE)


def body(content: str) -> str:
    if not content.startswith("{\n") or not content.endswith("}\n"):
        raise ValueError("Shared settings must start with '{' and end with '}' on their own lines")
    result = content[2:-2]
    if CONNECTION_SETTING.search(result):
        raise ValueError("Move SSH and WSL connection arrays to the LOCAL section")
    return result


def digest(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def read_active():
    match = ACTIVE_PATTERN.fullmatch(ACTIVE.read_text(encoding="utf-8"))
    if match is None:
        raise ValueError(
            f"{ACTIVE} has no recognized sections; move its changes into the shared "
            "or local section first"
        )
    return match


def render(local: str, shared: str) -> str:
    return (
        "{\n"
        + LOCAL_START
        + local
        + LOCAL_END
        + f"  // BEGIN SHARED SETTINGS sha256={digest(shared)}\n"
        + shared
        + SHARED_END
        + "}\n"
    )


def sync():
    shared = body(SHARED.read_text(encoding="utf-8"))
    local = DEFAULT_LOCAL
    if ACTIVE.exists():
        match = read_active()
        if digest(match["shared"]) != match["hash"]:
            raise ValueError("Zed changed the shared section; run 'promote' before 'sync'")
        local = match["local"]
    content = render(local, shared)
    if not ACTIVE.exists() or ACTIVE.read_text(encoding="utf-8") != content:
        ACTIVE.write_text(content, encoding="utf-8")
        print(f"Updated {ACTIVE}")
    else:
        print("Zed settings are already in sync")


def promote():
    match = read_active()
    source = body(SHARED.read_text(encoding="utf-8"))
    if digest(source) != match["hash"]:
        raise ValueError(
            "Shared settings changed since the last sync; "
            "merge the two shared sections manually"
        )
    body("{\n" + match["shared"] + "}\n")
    SHARED.write_text("{\n" + match["shared"] + "}\n", encoding="utf-8")
    ACTIVE.write_text(render(match["local"], match["shared"]), encoding="utf-8")
    print(f"Promoted shared settings to {SHARED}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("sync", "promote"))
    args = parser.parse_args()
    try:
        if args.action == "sync":
            sync()
        else:
            promote()
    except ValueError as error:
        parser.exit(1, f"Error: {error}\n")


if __name__ == "__main__":
    main()
