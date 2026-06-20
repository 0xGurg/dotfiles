#!/bin/bash
# ============================================================================
# Shared UI Output Functions
# Source this file from any script that needs colorized status output.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"
#   print_status "Doing something..."
#   print_success "Done!"
# ============================================================================

set -euo pipefail

# ── Guard: prevent double-sourcing ──────────────────────────────────────────
if [[ -n "${__UI_SH_SOURCED:-}" ]]; then
    return 0
fi
__UI_SH_SOURCED=1

# ── Color variables (exported for subprocesses) ─────────────────────────────
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m'   # No Color / reset

# ── Print functions ─────────────────────────────────────────────────────────
print_status()  { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }
print_info()    { echo -e "${CYAN}  $1${NC}"; }
