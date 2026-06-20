#!/usr/bin/env bash
# refresh-opencode-quota.sh
# Auto-refreshes the OpenCode Go auth cookie and shows quota status.
#
# Usage:
#   ./refresh-opencode-quota.sh                       # Refresh the active account
#   ./refresh-opencode-quota.sh --account secondary   # Refresh a specific account
#   ./refresh-opencode-quota.sh switch primary        # Switch OpenCode Go to primary
#   ./refresh-opencode-quota.sh status                # Check both accounts
#   ./refresh-opencode-quota.sh --force               # Force refresh even if valid
#   ./refresh-opencode-quota.sh --check               # Only validate, don't refresh
#
# The script:
#   1. Checks if the current auth cookie is still valid
#   2. If expired (or --force), extracts a fresh cookie from your browser
#   3. Updates opencode-go.json with the new cookie
#   4. Shows current quota status

set -euo pipefail

# Auto-source .env if present (check cwd first, then repo root relative to script)
for env_file in "$PWD/.env" "$(cd "$(dirname "$0")/../../.." && pwd)/.env" "$HOME/.config/opencode/.env"; do
  if [[ -f "$env_file" ]]; then
    set -a; source "$env_file"; set +a
    break
  fi
done

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode-quota/opencode-go.json"
ACCOUNTS_DIR="$CONFIG_DIR/opencode-quota/accounts"
QUOTA_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/opencode/quota-provider-state"
ACTIVE_ACCOUNT_FILE="$CONFIG_DIR/opencode-quota/active-account"
OPENCODE_AUTH_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON_HELPER="$SCRIPT_DIR/extract_cookie.py"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()  { echo -e "${BLUE}[quota]${NC} $*" >&2; }
ok()   { echo -e "${GREEN}[quota]${NC} $*" >&2; }
warn() { echo -e "${YELLOW}[quota]${NC} $*" >&2; }
err()  { echo -e "${RED}[quota]${NC} $*" >&2; }

# --- Parse args ---
FORCE=false
CHECK_ONLY=false
MANUAL_COOKIE=""
COMMAND=""
ACCOUNT=""
REFRESH_BROWSER=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    switch|status|    use)
      COMMAND="$1"
      REFRESH_BROWSER=true
      shift
      if [[ $# -gt 0 && "$1" != -* ]]; then
        ACCOUNT="$1"
        shift
      fi
      ;;
    primary|secondary)
      COMMAND="use"
      ACCOUNT="$1"
      REFRESH_BROWSER=true
      shift
      ;;
    --force)         FORCE=true; shift ;;
    --check)         CHECK_ONLY=true; shift ;;
    --account)
      ACCOUNT="$2"
      shift 2
      ;;
    --cookie)
      MANUAL_COOKIE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [command] [options]"
      echo ""
      echo "Commands:"
      echo "  primary|secondary          Refresh if needed, switch account, show quota"
      echo "  use primary|secondary      Same as primary/secondary shorthand above"
      echo "  switch primary|secondary   Switch only (no refresh) using saved cookie"
      echo "  status                     Check status of primary and secondary accounts"
      echo ""
      echo "Options:"
      echo "  --account primary|secondary  Target account for refresh/check (default: active)"
      echo "  --force        Force refresh the auth cookie even if not expired"
      echo "  --check        Only check if the cookie is valid, don't refresh"
      echo "  --cookie VALUE Use this cookie value instead of auto-extracting from browser"
      echo ""
      echo "Examples:"
      echo "  $0                           Refresh the active account"
      echo "  $0 primary                   Refresh + switch to primary + show quota"
      echo "  $0 secondary                 Refresh + switch to secondary + show quota"
      echo "  $0 switch primary            Switch only (saved cookie, no browser refresh)"
      echo "  $0 status                    Show status for both accounts"
      echo ""
      echo "Workspace IDs and API keys come from .env:"
      echo "  OPENCODE_GO_WORKSPACE_ID_PRIMARY / OPENCODE_GO_API_KEY_PRIMARY"
      echo "  OPENCODE_GO_WORKSPACE_ID_SECONDARY / OPENCODE_GO_API_KEY_SECONDARY"
      echo ""
      echo "Switching accounts updates quota config and ~/.local/share/opencode/auth.json"
      echo "To get your auth cookie:"
      echo "  1. Open https://opencode.ai in your browser"
      echo "  2. DevTools → Application → Cookies → opencode.ai"
      echo "  3. Copy the value of the 'auth' cookie"
      exit 0
      ;;
    *) err "Unknown argument: $1"; exit 1 ;;
  esac
done

# --- Read current config ---
read_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo '{"workspaceId":"","authCookie":""}'
    return
  fi
  cat "$CONFIG_FILE"
}

normalize_account() {
  case "$1" in
    primary|1|Primary|PRIMARY) echo "primary" ;;
    secondary|2|Secondary|SECONDARY) echo "secondary" ;;
    *)
      err "Invalid account: $1 (use primary or secondary)"
      return 1
      ;;
  esac
}

resolve_workspace_id() {
  local account="$1"
  case "$account" in
    primary)
      echo "${OPENCODE_GO_WORKSPACE_ID_PRIMARY:-${OPENCODE_GO_WORKSPACE_ID:-}}"
      ;;
    secondary)
      echo "${OPENCODE_GO_WORKSPACE_ID_SECONDARY:-}"
      ;;
  esac
}

resolve_api_key() {
  local account="$1"
  case "$account" in
    primary)
      echo "${OPENCODE_GO_API_KEY_PRIMARY:-}"
      ;;
    secondary)
      echo "${OPENCODE_GO_API_KEY_SECONDARY:-}"
      ;;
  esac
}

resolve_browser_for_account() {
  local account="$1"
  case "$account" in
    primary) echo "brave" ;;
    secondary) echo "chrome" ;;
    *) echo "" ;;
  esac
}

update_provider_auth() {
  local account="$1"
  local api_key
  api_key=$(resolve_api_key "$account")

  if [[ -z "$api_key" ]]; then
    warn "No API key for $account — set OPENCODE_GO_API_KEY_PRIMARY/SECONDARY in .env (provider auth unchanged)"
    return 0
  fi

  if [[ ! -f "$OPENCODE_AUTH_FILE" ]]; then
    warn "Provider auth file not found: $OPENCODE_AUTH_FILE"
    return 0
  fi

  if ! OPENCODE_AUTH_FILE="$OPENCODE_AUTH_FILE" API_KEY="$api_key" python3 -c '
import json, os
path = os.environ["OPENCODE_AUTH_FILE"]
with open(path) as f:
    data = json.load(f)
entry = data.setdefault("opencode-go", {})
entry["type"] = "api"
entry["key"] = os.environ["API_KEY"]
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
'; then
    err "Failed to update provider auth in $OPENCODE_AUTH_FILE"
    return 1
  fi

  ok "Updated OpenCode Go provider API key ($account) in auth.json"
}

get_active_account() {
  if [[ -f "$ACTIVE_ACCOUNT_FILE" ]]; then
    tr -d '[:space:]' < "$ACTIVE_ACCOUNT_FILE"
  else
    echo "primary"
  fi
}

set_active_account() {
  mkdir -p "$(dirname "$ACTIVE_ACCOUNT_FILE")"
  echo "$1" > "$ACTIVE_ACCOUNT_FILE"
}

account_config_file() {
  echo "$ACCOUNTS_DIR/$1.json"
}

read_account_config() {
  local file
  file=$(account_config_file "$1")
  if [[ -f "$file" ]]; then
    cat "$file"
    return
  fi
  echo '{"workspaceId":"","authCookie":""}'
}

write_account_store() {
  local account="$1"
  local cookie="$2"
  local wsid="$3"
  local file current updated

  file=$(account_config_file "$account")
  mkdir -p "$(dirname "$file")"
  current=$(read_account_config "$account")

  updated=$(echo "$current" | COOKIE="$cookie" WSID="$wsid" python3 -c "
import sys, json, os
data = json.load(sys.stdin)
data['authCookie'] = os.environ['COOKIE']
wsid = os.environ.get('WSID', '')
if wsid:
    data['workspaceId'] = wsid
print(json.dumps(data, indent=2))
" 2>/dev/null)

  echo "$updated" > "$file"
}

load_account_credentials() {
  local account="$1"
  local wsid cookie

  wsid=$(resolve_workspace_id "$account")
  cookie=$(read_account_config "$account" | python3 -c "import sys,json; print(json.load(sys.stdin).get('authCookie',''))" 2>/dev/null || echo "")

  if [[ -z "$wsid" ]]; then
    wsid=$(read_account_config "$account" | python3 -c "import sys,json; print(json.load(sys.stdin).get('workspaceId',''))" 2>/dev/null || echo "")
  fi

  WORKSPACE_ID="$wsid"
  AUTH_COOKIE="$cookie"
}

prepare_account_credentials() {
  local account="$1"
  local expected_wsid

  load_account_credentials "$account"
  expected_wsid=$(resolve_workspace_id "$account")

  if [[ -n "$expected_wsid" ]]; then
    WORKSPACE_ID="$expected_wsid"
  fi

  if [[ -z "$WORKSPACE_ID" ]]; then
    return 1
  fi
  if [[ -z "$AUTH_COOKIE" ]]; then
    return 0
  fi

  local status
  status=$(check_cookie "$AUTH_COOKIE" "$WORKSPACE_ID")
  if [[ "$status" != "valid" ]]; then
    warn "Saved cookie for $account does not match workspace $WORKSPACE_ID ($status)"
    AUTH_COOKIE=""
  fi
  return 0
}

validate_cookie_for_account() {
  local account="$1"
  local cookie="$2"
  local expected_wsid other_account other_cookie status browser

  expected_wsid=$(resolve_workspace_id "$account")
  if [[ -z "$expected_wsid" || -z "$cookie" ]]; then
    err "Missing workspace or cookie for $account"
    return 1
  fi

  status=$(check_cookie "$cookie" "$expected_wsid")
  if [[ "$status" != "valid" ]]; then
    browser=$(resolve_browser_for_account "$account")
    err "Cookie from $browser is not valid for $account workspace ($expected_wsid)"
    err "Log into the $account OpenCode account in $browser before running: oc-go-${account}"
    return 1
  fi

  case "$account" in
    primary) other_account=secondary ;;
    secondary) other_account=primary ;;
    *) return 0 ;;
  esac

  other_cookie=$(read_account_config "$other_account" | python3 -c "import sys,json; print(json.load(sys.stdin).get('authCookie',''))" 2>/dev/null || echo "")
  if [[ -n "$other_cookie" && "$cookie" == "$other_cookie" ]]; then
    browser=$(resolve_browser_for_account "$account")
    err "Cookie from $browser is the same as the saved $other_account account"
    err "Use separate browser profiles: Brave for primary, Chrome for secondary"
    return 1
  fi

  return 0
}

report_account_status() {
  local account="$1"
  local wsid cookie status

  wsid=$(resolve_workspace_id "$account")
  cookie=$(read_account_config "$account" | python3 -c "import sys,json; print(json.load(sys.stdin).get('authCookie',''))" 2>/dev/null || echo "")

  if [[ -z "$wsid" ]]; then
    warn "$account: workspace ID not configured"
    return
  fi
  if [[ -z "$(resolve_api_key "$account")" ]]; then
    warn "$account: API key not in .env"
  fi
  if [[ -z "$cookie" ]]; then
    warn "$account: no saved cookie (run: $0 $account)"
    return
  fi

  status=$(check_cookie "$cookie" "$wsid")
  case "$status" in
    valid)   ok "$account: valid" ;;
    expired) warn "$account: expired" ;;
    missing) warn "$account: missing credentials" ;;
    *)       warn "$account: unknown ($status)" ;;
  esac
}

switch_account_cmd() {
  local account
  account=$(normalize_account "${1:-}") || exit 1

  prepare_account_credentials "$account"

  if [[ -z "$WORKSPACE_ID" ]]; then
    err "No workspace ID for $account"
    err "Set OPENCODE_GO_WORKSPACE_ID_PRIMARY or OPENCODE_GO_WORKSPACE_ID_SECONDARY in .env"
    exit 1
  fi
  if [[ -z "$AUTH_COOKIE" ]]; then
    err "No saved cookie for $account"
    err "Log into that account in $(resolve_browser_for_account "$account"), then run: $0 $account"
    exit 1
  fi

  activate_account "$account"
  show_quota
}

activate_account() {
  local account="$1"
  update_config "$AUTH_COOKIE" "$WORKSPACE_ID"
  write_account_store "$account" "$AUTH_COOKIE" "$WORKSPACE_ID"
  set_active_account "$account"
  update_provider_auth "$account"
  ok "Using $account account ($WORKSPACE_ID)"
}

use_account_cmd() {
  local account
  account=$(normalize_account "${1:-}") || exit 1
  TARGET_ACCOUNT="$account"
  prepare_account_credentials "$account"

  if [[ -z "$WORKSPACE_ID" ]]; then
    err "No workspace ID for $account"
    err "Set OPENCODE_GO_WORKSPACE_ID_PRIMARY or OPENCODE_GO_WORKSPACE_ID_SECONDARY in .env"
    exit 1
  fi

  refresh_account
}

status_all_accounts() {
  local active
  active=$(get_active_account)
  log "Active account: $active"
  echo ""
  report_account_status "primary"
  report_account_status "secondary"
}

# --- Check if cookie is still valid ---
check_cookie() {
  local cookie="$1"
  local wsid="$2"

  if [[ -z "$cookie" || -z "$wsid" ]]; then
    echo "missing"
    return
  fi

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Cookie: auth=${cookie}" \
    -H "User-Agent: Mozilla/5.0" \
    -H "Accept: text/html" \
    "https://opencode.ai/workspace/${wsid}/go" 2>/dev/null)

  if [[ "$http_code" == "200" ]]; then
    echo "valid"
  elif [[ "$http_code" == "302" || "$http_code" == "401" || "$http_code" == "403" ]]; then
    echo "expired"
  else
    echo "unknown:$http_code"
  fi
}

# --- Extract cookie from browser ---
extract_cookie() {
  local account="${1:-${TARGET_ACCOUNT:-}}"
  local browser args=()

  if [[ ! -f "$PYTHON_HELPER" ]]; then
    err "Python helper not found: $PYTHON_HELPER"
    return 1
  fi

  if [[ -n "$account" ]]; then
    browser=$(resolve_browser_for_account "$account")
  fi

  if [[ -n "$browser" ]]; then
    log "Extracting cookie from $browser for ${account} account..."
    args=(--browser "$browser")
  fi

  if [[ -n "$account" ]]; then
    local expected_wsid
    expected_wsid=$(resolve_workspace_id "$account")
    if [[ -n "$expected_wsid" ]]; then
      args+=(--workspace-id "$expected_wsid")
    fi
  fi

  local result
  result=$(python3 "$PYTHON_HELPER" "${args[@]}" 2>/dev/null)
  if [[ -z "$result" ]]; then
    if [[ -n "$browser" && -n "$account" ]]; then
      err "Could not extract a valid cookie from $browser for ${account} workspace"
      err "Make sure the ${account} OpenCode account is logged in at https://opencode.ai in $browser"
      err "Tip: use a separate browser profile so primary (Brave) and secondary (Chrome) stay signed into different accounts"
    elif [[ -n "$browser" ]]; then
      err "Could not extract cookie from $browser"
      err "Log into opencode.ai in $browser for the ${account} account first"
    else
      err "Could not extract cookie from any browser"
      err "Make sure you've logged into opencode.ai in your browser"
    fi
    return 1
  fi

  local cookie browser_name
  cookie=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cookie',''))" 2>/dev/null)
  browser_name=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('browser',''))" 2>/dev/null)

  if [[ -z "$cookie" || "$cookie" == "None" ]]; then
    if [[ -n "$browser" && -n "$account" ]]; then
      err "No auth cookie in $browser matches workspace $(resolve_workspace_id "$account")"
      err "The ${account} account is probably not logged in there — check https://opencode.ai in $browser"
    elif [[ -n "$browser" ]]; then
      err "No auth cookie found in $browser"
      err "Log into opencode.ai in $browser for the ${account} account first"
    else
      err "No auth cookie found in any browser"
      err "Please log into opencode.ai in your browser first"
    fi
    return 1
  fi

  ok "Extracted auth cookie from $browser_name"
  echo "$cookie"
}

# --- Extract workspace ID from dashboard ---
extract_workspace_id() {
  local cookie="$1"

  # Try to get workspace ID from the dashboard redirect
  local response
  response=$(curl -s -D - \
    -H "Cookie: auth=${cookie}" \
    -H "User-Agent: Mozilla/5.0" \
    "https://opencode.ai/dashboard" 2>/dev/null)

  # Look for workspace ID in redirect or page content
  local wsid
  wsid=$(echo "$response" | grep -oE 'workspace/[a-zA-Z0-9_-]+' | head -1 | sed 's/workspace\///')
  if [[ -n "$wsid" ]]; then
    echo "$wsid"
    return
  fi

  # Try the workspaces API
  wsid=$(curl -s \
    -H "Cookie: auth=${cookie}" \
    -H "User-Agent: Mozilla/5.0" \
    "https://opencode.ai/api/workspaces" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if isinstance(data, list) and len(data) > 0:
        print(data[0].get('id', ''))
    elif isinstance(data, dict):
        ws = data.get('workspaces', data.get('data', []))
        if isinstance(ws, list) and len(ws) > 0:
            print(ws[0].get('id', ''))
except:
    pass
" 2>/dev/null)

  if [[ -n "$wsid" ]]; then
    echo "$wsid"
    return
  fi

  echo ""
}

# --- Update config file ---
update_config() {
  local cookie="$1"
  local wsid="$2"

  mkdir -p "$(dirname "$CONFIG_FILE")"

  local current
  current=$(read_config)

  # Update fields using env vars to avoid shell injection
  local updated
  updated=$(echo "$current" | COOKIE="$cookie" WSID="$wsid" python3 -c "
import sys, json, os
data = json.load(sys.stdin)
data['authCookie'] = os.environ['COOKIE']
wsid = os.environ.get('WSID', '')
if wsid:
    data['workspaceId'] = wsid
print(json.dumps(data, indent=2))
" 2>/dev/null)

  echo "$updated" > "$CONFIG_FILE"
  ok "Updated $CONFIG_FILE"
}

# --- Export env vars from config file ---
# The opencode-quota plugin checks env vars first and short-circuits
# if only one is set. We export both from opencode-go.json so the
# plugin always finds a complete config via env vars.
export_env_from_config() {
  unset OPENCODE_GO_WORKSPACE_ID OPENCODE_GO_AUTH_COOKIE
  if [[ -f "$CONFIG_FILE" ]]; then
    local wsid acookie
    wsid=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('workspaceId',''))" 2>/dev/null || echo "")
    acookie=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('authCookie',''))" 2>/dev/null || echo "")
    [[ -n "$wsid" ]] && export OPENCODE_GO_WORKSPACE_ID="$wsid"
    [[ -n "$acookie" ]] && export OPENCODE_GO_AUTH_COOKIE="$acookie"
  fi
}

# --- Show quota ---
show_quota() {
  export_env_from_config

  local bin="npx"
  if command -v pnpm &>/dev/null; then
    bin="pnpm exec"
  elif command -v npx &>/dev/null; then
    bin="npx"
  else
    warn "Neither pnpm nor npx found — cannot run opencode-quota"
    return 1
  fi

  # Ensure dependencies are installed
  if ! ls "$CONFIG_DIR/node_modules/@slkiser/opencode-quota/package.json" &>/dev/null; then
    log "Installing opencode-quota dependency..."
    cd "$CONFIG_DIR" && pnpm install 2>&1 | tail -1 || true
  fi

  # The opencode-quota cache key does NOT include the workspace/cookie, so a
  # cached result from another account (or the running TUI) would be shown for
  # the account we just switched to. Drop the opencode-go cache to force a fresh
  # fetch for the active account.
  if [[ -d "$QUOTA_CACHE_DIR" ]]; then
    find "$QUOTA_CACHE_DIR" -maxdepth 1 -name 'opencode-go-*.json' -delete 2>/dev/null || true
  fi

  log "Current quota:"
  cd "$CONFIG_DIR" && $bin opencode-quota show --provider opencode-go 2>&1 || warn "Could not fetch quota"
}

# --- Main ---
refresh_account() {
  log "Checking auth cookie status for ${TARGET_ACCOUNT:-active} account..."

  local status
  status=$(check_cookie "$AUTH_COOKIE" "$WORKSPACE_ID")

  case "$status" in
    valid)
      ok "Auth cookie is valid"
      if [[ "$FORCE" == true || "$REFRESH_BROWSER" == true ]]; then
        if [[ "$REFRESH_BROWSER" == true ]]; then
          log "Refreshing cookie from $(resolve_browser_for_account "$TARGET_ACCOUNT")..."
        else
          log "Force refresh requested..."
        fi
      else
        if [[ -n "$TARGET_ACCOUNT" ]]; then
          activate_account "$TARGET_ACCOUNT"
        fi
        if [[ "$CHECK_ONLY" == true ]]; then
          ok "Cookie is valid, no refresh needed"
          show_quota
          return 0
        fi
        show_quota
        return 0
      fi
      ;;
    expired)
      warn "Auth cookie has expired"
      ;;
    missing)
      warn "No auth cookie or workspace ID configured"
      ;;
    *)
      warn "Could not verify cookie (HTTP ${status#unknown:})"
      ;;
  esac

  if [[ "$CHECK_ONLY" == true ]]; then
    if [[ "$status" == "valid" ]]; then
      ok "Cookie is valid"
      return 0
    else
      err "Cookie is not valid: $status"
      return 1
    fi
  fi

  # --- Refresh cookie ---
  local new_cookie
  if [[ -n "$MANUAL_COOKIE" ]]; then
    new_cookie="$MANUAL_COOKIE"
    log "Using provided cookie (--cookie flag)"
  else
    log "Extracting fresh auth cookie from browser..."
    new_cookie=$(extract_cookie "$TARGET_ACCOUNT")
    if [[ $? -ne 0 ]]; then
      err "Automatic cookie extraction failed"
      err ""
      err "To manually refresh:"
      err "  Run: $0 --cookie \"<value>\""
      err ""
      err "To get your auth cookie value:"
      err "  1. Open https://opencode.ai in your browser"
      err "  2. DevTools → Application → Cookies → opencode.ai"
      err "  3. Copy the value of the 'auth' cookie"
      return 1
    fi
  fi

  # --- Try to get workspace ID if missing ---
  if [[ -z "$WORKSPACE_ID" ]]; then
    log "Workspace ID not set, trying to discover it..."
    local wsid
    wsid=$(extract_workspace_id "$new_cookie")
    if [[ -n "$wsid" ]]; then
      ok "Found workspace ID: $wsid"
      WORKSPACE_ID="$wsid"
    else
      warn "Could not auto-discover workspace ID"
      warn "Set OPENCODE_GO_WORKSPACE_ID_PRIMARY/SECONDARY in .env or update $CONFIG_FILE manually"
      warn "Find it in your browser at: https://opencode.ai/dashboard"
    fi
  fi

  if ! validate_cookie_for_account "$TARGET_ACCOUNT" "$new_cookie"; then
    return 1
  fi

  # --- Update config ---
  AUTH_COOKIE="$new_cookie"
  activate_account "$TARGET_ACCOUNT"
  ok "New cookie is valid for $TARGET_ACCOUNT ($WORKSPACE_ID)"

  # --- Show quota ---
  show_quota
}

init_target_account() {
  TARGET_ACCOUNT=""
  WORKSPACE_ID=""
  AUTH_COOKIE=""

  if [[ -n "$ACCOUNT" ]]; then
    TARGET_ACCOUNT=$(normalize_account "$ACCOUNT") || exit 1
  else
    TARGET_ACCOUNT=$(get_active_account)
  fi

  if [[ -n "$TARGET_ACCOUNT" ]]; then
    prepare_account_credentials "$TARGET_ACCOUNT"
  fi

  if [[ -z "$WORKSPACE_ID" ]]; then
    WORKSPACE_ID=$(read_config | python3 -c "import sys,json; print(json.load(sys.stdin).get('workspaceId',''))" 2>/dev/null || echo "")
  fi
  if [[ -z "$AUTH_COOKIE" ]]; then
    AUTH_COOKIE=$(read_config | python3 -c "import sys,json; print(json.load(sys.stdin).get('authCookie',''))" 2>/dev/null || echo "")
  fi

  if [[ -n "${OPENCODE_GO_WORKSPACE_ID:-}" && -z "${OPENCODE_GO_WORKSPACE_ID_PRIMARY:-}" ]]; then
    WORKSPACE_ID="$OPENCODE_GO_WORKSPACE_ID"
  fi
  if [[ -n "${OPENCODE_GO_AUTH_COOKIE:-}" ]]; then
    AUTH_COOKIE="$OPENCODE_GO_AUTH_COOKIE"
  fi
}

main() {
  case "$COMMAND" in
    switch)
      switch_account_cmd "$ACCOUNT"
      ;;
    status)
      status_all_accounts
      ;;
    use)
      use_account_cmd "$ACCOUNT"
      ;;
    *)
      init_target_account
      refresh_account
      ;;
  esac
}

main
