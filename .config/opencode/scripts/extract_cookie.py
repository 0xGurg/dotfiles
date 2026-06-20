#!/usr/bin/env python3
"""Extract the 'auth' cookie for opencode.ai from the local browser."""

import argparse
import json
import subprocess
import sys
from typing import Optional

try:
    import browser_cookie3
except ImportError:
    print("ERROR: browser_cookie3 not installed. Run: pip3 install browser_cookie3", file=sys.stderr)
    sys.exit(1)

DOMAIN = "opencode.ai"
COOKIE_NAME = "auth"
USER_AGENT = "Mozilla/5.0"

BROWSERS = {
    "chrome": ("Chrome", browser_cookie3.chrome),
    "google-chrome": ("Chrome", browser_cookie3.chrome),
    "chromium": ("Chromium", browser_cookie3.chromium),
    "safari": ("Safari", browser_cookie3.safari),
    "firefox": ("Firefox", browser_cookie3.firefox),
    "edge": ("Edge", browser_cookie3.edge),
    "brave": ("Brave", browser_cookie3.brave),
    "arc": ("Arc", browser_cookie3.arc),
}

DEFAULT_BROWSER_ORDER = ["chrome", "safari", "firefox", "edge", "brave", "arc"]


def cookie_valid_for_workspace(cookie: str, workspace_id: str) -> bool:
    try:
        http_code = subprocess.check_output(
            [
                "curl",
                "-s",
                "-o",
                "/dev/null",
                "-w",
                "%{http_code}",
                "-H",
                f"Cookie: auth={cookie}",
                "-H",
                "User-Agent: Mozilla/5.0",
                "-H",
                "Accept: text/html",
                f"https://opencode.ai/workspace/{workspace_id}/go",
            ],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
        return http_code == "200"
    except Exception:
        return False


def extract_from_browser(name: str, loader, workspace_id: Optional[str] = None) -> Optional[dict]:
    try:
        cj = loader(domain_name=DOMAIN)
    except Exception:
        return None

    cookies = []
    for cookie in cj:
        if cookie.name == COOKIE_NAME and DOMAIN in cookie.domain:
            cookies.append(cookie.value)

    if not cookies:
        return None

    if workspace_id:
        for value in cookies:
            if cookie_valid_for_workspace(value, workspace_id):
                return {"cookie": value, "browser": name, "workspaceId": workspace_id}
        return {"cookie": None, "browser": name, "workspaceId": workspace_id}

    return {"cookie": cookies[0], "browser": name}


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract opencode.ai auth cookie from a browser")
    parser.add_argument(
        "--browser",
        help="Browser to read (chrome, safari, firefox, edge, brave, arc). Default: try all.",
    )
    parser.add_argument(
        "--workspace-id",
        help="Require a cookie that is valid for this OpenCode Go workspace ID.",
    )
    args = parser.parse_args()

    workspace_id = args.workspace_id.strip() if args.workspace_id else None

    if args.browser:
        key = args.browser.strip().lower()
        if key not in BROWSERS:
            print(
                json.dumps({"cookie": None, "browser": None, "error": f"Unknown browser: {args.browser}"}),
                file=sys.stderr,
            )
            return 1
        name, loader = BROWSERS[key]
        result = extract_from_browser(name, loader, workspace_id)
        if result and result.get("cookie"):
            print(json.dumps(result))
            return 0
        print(json.dumps({"cookie": None, "browser": name, "workspaceId": workspace_id}))
        return 1

    for key in DEFAULT_BROWSER_ORDER:
        name, loader = BROWSERS[key]
        result = extract_from_browser(name, loader, workspace_id)
        if result and result.get("cookie"):
            print(json.dumps(result))
            return 0

    print(json.dumps({"cookie": None, "browser": None, "workspaceId": workspace_id}))
    return 1


if __name__ == "__main__":
    sys.exit(main())
