#!/usr/bin/env bash
# refresh-opencode-quota.sh
# Auto-refreshes the OpenCode Go auth cookie and shows quota status.
#
# Usage:
#   ./refresh-opencode-quota.sh          # Check quota, refresh cookie if expired
#   ./refresh-opencode-quota.sh --force  # Force refresh the cookie even if not expired
#   ./refresh-opencode-quota.sh --check  # Only check if cookie is valid, don't refresh
#
# The script:
#   1. Checks if the current auth cookie is still valid
#   2. If expired (or --force), extracts a fresh cookie from your browser
#   3. Updates opencode-go.json with the new cookie
#   4. Shows current quota status

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode-quota/opencode-go.json"
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
for arg in "$@"; do
  case "$arg" in
    --force)  FORCE=true ;;
    --check)  CHECK_ONLY=true ;;
    -h|--help)
      echo "Usage: $0 [--force] [--check]"
      echo "  --force  Force refresh the auth cookie even if not expired"
      echo "  --check  Only check if the cookie is valid, don't refresh"
      exit 0
      ;;
    *) err "Unknown argument: $arg"; exit 1 ;;
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

WORKSPACE_ID=$(read_config | python3 -c "import sys,json; print(json.load(sys.stdin).get('workspaceId',''))" 2>/dev/null || echo "")
AUTH_COOKIE=$(read_config | python3 -c "import sys,json; print(json.load(sys.stdin).get('authCookie',''))" 2>/dev/null || echo "")

# Env vars take precedence
if [[ -n "${OPENCODE_GO_WORKSPACE_ID:-}" ]]; then
  WORKSPACE_ID="$OPENCODE_GO_WORKSPACE_ID"
fi
if [[ -n "${OPENCODE_GO_AUTH_COOKIE:-}" ]]; then
  AUTH_COOKIE="$OPENCODE_GO_AUTH_COOKIE"
fi

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
  if [[ ! -f "$PYTHON_HELPER" ]]; then
    err "Python helper not found: $PYTHON_HELPER"
    return 1
  fi

  local result
  result=$(python3 "$PYTHON_HELPER" 2>/dev/null)
  if [[ -z "$result" ]]; then
    err "Could not extract cookie from any browser"
    err "Make sure you've logged into opencode.ai in your browser"
    return 1
  fi

  local cookie browser
  cookie=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cookie',''))" 2>/dev/null)
  browser=$(echo "$result" | python3 -c "import sys,json; print(json.load(sys.stdin).get('browser',''))" 2>/dev/null)

  if [[ -z "$cookie" || "$cookie" == "None" ]]; then
    err "No auth cookie found in any browser"
    err "Please log into opencode.ai in your browser first"
    return 1
  fi

  ok "Extracted auth cookie from $browser"
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

  local npx_cmd="npx @slkiser/opencode-quota show --provider opencode-go"
  if command -v opencode-quota &>/dev/null; then
    npx_cmd="opencode-quota show --provider opencode-go"
  fi

  log "Current quota:"
  cd "$CONFIG_DIR" && $npx_cmd 2>/dev/null || warn "Could not fetch quota"
}

# --- Main ---
main() {
  log "Checking auth cookie status..."

  local status
  status=$(check_cookie "$AUTH_COOKIE" "$WORKSPACE_ID")

  case "$status" in
    valid)
      ok "Auth cookie is valid"
      if [[ "$FORCE" == true ]]; then
        log "Force refresh requested..."
      else
        if [[ "$CHECK_ONLY" == true ]]; then
          ok "Cookie is valid, no refresh needed"
          show_quota
          exit 0
        fi
        show_quota
        exit 0
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
      exit 0
    else
      err "Cookie is not valid: $status"
      exit 1
    fi
  fi

  # --- Refresh cookie ---
  log "Extracting fresh auth cookie from browser..."
  local new_cookie
  new_cookie=$(extract_cookie)
  if [[ $? -ne 0 ]]; then
    err "Automatic cookie extraction failed"
    err ""
    err "To manually refresh:"
    err "  1. Open https://opencode.ai in your browser"
    err "  2. Open DevTools → Application → Cookies → opencode.ai"
    err "  3. Copy the value of the 'auth' cookie"
    err "  4. Edit $CONFIG_FILE"
    err "     Set authCookie to the copied value"
    exit 1
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
      warn "Set OPENCODE_GO_WORKSPACE_ID or update $CONFIG_FILE manually"
      warn "Find it in your browser at: https://opencode.ai/dashboard"
    fi
  fi

  # --- Update config ---
  update_config "$new_cookie" "$WORKSPACE_ID"

  # --- Verify ---
  log "Verifying new cookie..."
  local new_status
  new_status=$(check_cookie "$new_cookie" "$WORKSPACE_ID")
  if [[ "$new_status" == "valid" ]]; then
    ok "New cookie is valid!"
  else
    warn "Could not verify new cookie (status: $new_status)"
    warn "The cookie may need a moment to propagate, or the workspace ID may be incorrect"
  fi

  # --- Show quota ---
  show_quota
}

main
