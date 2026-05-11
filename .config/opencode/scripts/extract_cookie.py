#!/usr/bin/env python3
"""Extract the 'auth' cookie for opencode.ai from the local browser."""

import sys
import json

try:
    import browser_cookie3
except ImportError:
    print("ERROR: browser_cookie3 not installed. Run: pip3 install browser_cookie3", file=sys.stderr)
    sys.exit(1)

DOMAIN = "opencode.ai"
COOKIE_NAME = "auth"

# Try browsers in order of likelihood
browsers = [
    ("Chrome", browser_cookie3.chrome),
    ("Safari", browser_cookie3.safari),
    ("Firefox", browser_cookie3.firefox),
    ("Edge", browser_cookie3.edge),
    ("Brave", browser_cookie3.brave),
    ("Arc", browser_cookie3.arc),
]

for name, loader in browsers:
    try:
        cj = loader(domain_name=DOMAIN)
        for cookie in cj:
            if cookie.name == COOKIE_NAME and DOMAIN in cookie.domain:
                print(json.dumps({"cookie": cookie.value, "browser": name}))
                sys.exit(0)
    except Exception:
        continue

print(json.dumps({"cookie": None, "browser": None}))
sys.exit(1)
