# ============================================================================
# LOGIN SHELL STARTUP
# ============================================================================
# This file runs once per login shell (new terminal window/tab),
# NOT on every subshell or script invocation.

# System info display (only in interactive login shells)
if [[ -o interactive ]] && command -v fastfetch &> /dev/null; then
  fastfetch
fi
