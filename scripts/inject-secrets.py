#!/usr/bin/env python3
"""Pull secrets from Bitwarden and render config templates + SSH keys.

Reads scripts/secrets.jsonc for configuration. Edit that file to add/remove
secrets or SSH keys -- no need to modify this script.

Prerequisites:
  - bitwarden-cli (bw) installed
  - Bitwarden items matching secrets.jsonc config

Usage:
  ./scripts/inject-secrets.py                    # interactive
  BW_SESSION=... ./scripts/inject-secrets.py     # non-interactive
"""

import json
import os
import re
import shutil
import socket
import subprocess
import sys
from pathlib import Path

DOTFILES = Path(__file__).resolve().parent.parent
CONFIG = DOTFILES / "scripts" / "secrets.jsonc"

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
NC = "\033[0m"


def status(msg):
    print(f"{BLUE}==>{NC} {msg}")


def success(msg):
    print(f"{GREEN}✓{NC} {msg}")


def warning(msg):
    print(f"{YELLOW}⚠{NC} {msg}")


def error(msg):
    print(f"{RED}✗{NC} {msg}")


def read_config():
    text = CONFIG.read_text()
    return json.loads(strip_jsonc_comments(text))


def strip_jsonc_comments(text):
    result = []
    i = 0
    in_string = False
    string_quote = ""
    escaped = False

    while i < len(text):
        char = text[i]
        next_char = text[i + 1] if i + 1 < len(text) else ""

        if in_string:
            result.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == string_quote:
                in_string = False
            i += 1
            continue

        if char in ('"', "'"):
            in_string = True
            string_quote = char
            result.append(char)
            i += 1
            continue

        if char == "/" and next_char == "/":
            i += 2
            while i < len(text) and text[i] not in "\r\n":
                i += 1
            continue

        if char == "/" and next_char == "*":
            i += 2
            while i + 1 < len(text) and not (text[i] == "*" and text[i + 1] == "/"):
                result.append("\n" if text[i] in "\r\n" else " ")
                i += 1
            i += 2
            continue

        result.append(char)
        i += 1

    return "".join(result)


def bw_run(*args):
    result = subprocess.run(["bw", *args], capture_output=True, text=True)
    return result


def bw_get_item(name, session):
    result = bw_run("get", "item", name, "--session", session)
    if result.returncode != 0:
        error(f"Failed to fetch Bitwarden item '{name}': {result.stderr.strip()}")
        return None
    return json.loads(result.stdout)


def get_field(item, name):
    for f in item.get("fields", []):
        if f["name"] == name:
            return f["value"]
    return ""


def ensure_session():
    session = os.environ.get("BW_SESSION", "")

    check = bw_run("unlock", "--check")
    if check.returncode == 0:
        success("Bitwarden vault is unlocked")
        return session

    result = bw_run("status")
    try:
        bw_status = json.loads(result.stdout).get("status", "unauthenticated")
    except (json.JSONDecodeError, AttributeError):
        bw_status = "unauthenticated"

    if bw_status == "unauthenticated":
        status("Logging into Bitwarden...")
        proc = subprocess.run(["bw", "login", "--raw"], capture_output=False, text=True,
                              stdout=subprocess.PIPE)
        if proc.returncode != 0:
            error("Bitwarden login failed")
            sys.exit(1)
        session = proc.stdout.strip()
    elif bw_status == "locked":
        status("Unlocking Bitwarden vault...")
        proc = subprocess.run(["bw", "unlock", "--raw"], capture_output=False, text=True,
                              stdout=subprocess.PIPE)
        if proc.returncode != 0:
            error("Bitwarden unlock failed")
            sys.exit(1)
        session = proc.stdout.strip()
    else:
        success("Bitwarden vault is unlocked")

    os.environ["BW_SESSION"] = session
    return session


def inject_secrets(session, config):
    status("Fetching secrets from Bitwarden...")

    secrets_item = config["secrets_item"]
    item = bw_get_item(secrets_item, session)
    if not item:
        error(f"Create a Bitwarden item named '{secrets_item}' with the fields listed in secrets.jsonc")
        return False

    values = {}
    missing = []
    for field_name in config["fields"]:
        val = get_field(item, field_name)
        values[field_name] = val
        if not val:
            missing.append(field_name)

    if missing:
        warning(f"Missing fields in '{secrets_item}': {', '.join(missing)}")

    status("Rendering templates...")
    for tmpl in DOTFILES.rglob("*.tmpl"):
        content = tmpl.read_text()
        for key, val in values.items():
            content = content.replace(f"{{{{{key}}}}}", val)
        
        remaining = re.findall(r'\{\{(\w+)\}\}', content)
        if remaining:
            warning(f"Unresolved placeholders in {tmpl}: {', '.join(remaining)}")
            
        output = tmpl.with_suffix("")
        output.write_text(content)
        output.chmod(0o600)
        success(f"Rendered: {output}")

    success("All templates rendered")
    return True


def inject_ssh(session, config, hostname):
    status("Restoring SSH keys from Bitwarden...")

    ssh_dir = Path.home() / ".ssh"
    ssh_dir.mkdir(mode=0o700, exist_ok=True)

    written_keys = []

    for entry in config.get("ssh_keys", []):
        if isinstance(entry, str):
            bw_name = filename = entry
            allowed_hosts = None
        else:
            bw_name = entry["bw_item"]
            filename = entry["filename"]
            allowed_hosts = entry.get("hosts")

        # Skip keys restricted to other hosts
        if allowed_hosts and hostname not in allowed_hosts:
            status(f"Skipping {filename} (host '{hostname}' not in {allowed_hosts})")
            continue

        item = bw_get_item(bw_name, session)
        if not item:
            warning(f"Skipping {filename}")
            continue

        # SSH key item type (type 5) stores keys under sshKey.*
        # Custom fields store them as private_key / public_key
        ssh_key = item.get("sshKey") or {}
        priv = ssh_key.get("privateKey") or get_field(item, "private_key")
        pub = ssh_key.get("publicKey") or get_field(item, "public_key")

        if priv:
            key_path = ssh_dir / filename
            key_path.write_text(priv + "\n")
            key_path.chmod(0o600)
            success(f"Wrote ~/.ssh/{filename}")
            written_keys.append(key_path)
        else:
            warning(f"No private_key field in '{bw_name}'")

        if pub:
            pub_path = ssh_dir / f"{filename}.pub"
            pub_path.write_text(pub + "\n")
            pub_path.chmod(0o644)
            success(f"Wrote ~/.ssh/{filename}.pub")
        else:
            warning(f"No public_key field in '{bw_name}'")

    # Add keys to ssh-agent
    if written_keys:
        status("Adding keys to ssh-agent...")
        result = subprocess.run(["ssh-add"] + [str(k) for k in written_keys],
                                capture_output=True)
        if result.returncode != 0:
            warning(f"ssh-add failed: {result.stderr.decode().strip() if result.stderr else 'agent not running?'}")
            warning("Start ssh-agent with: eval $(ssh-agent -s)")
        else:
            success("Keys added to ssh-agent")


def main():
    if not shutil.which("bw"):
        error("bitwarden-cli (bw) is required but not installed")
        sys.exit(1)

    if not CONFIG.is_file():
        error(f"Config file not found: {CONFIG}")
        sys.exit(1)

    print()
    print("╔═══════════════════════════════════════════════════════════════╗")
    print("          Bitwarden Secrets Injection                           ")
    print("╚═══════════════════════════════════════════════════════════════╝")
    print()

    config = read_config()
    session = ensure_session()
    hostname = socket.gethostname()
    status(f"Detected hostname: {hostname}")

    status("Syncing Bitwarden vault...")
    result = bw_run("sync", "--session", session)
    if result.returncode != 0:
        error(f"Bitwarden sync failed: {result.stderr.strip() if result.stderr else 'unknown error'}")
        sys.exit(1)
    success("Vault synced")

    inject_secrets(session, config)
    inject_ssh(session, config, hostname)

    print()
    success("All secrets injected!")
    print()


if __name__ == "__main__":
    main()
