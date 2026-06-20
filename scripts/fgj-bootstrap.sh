#!/bin/bash
# Rebuild fgj config from .env secrets
# Run after cloning dotfiles on a new machine, or when secrets change
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$DOTFILES_DIR/.env"
CONFIG_FILE="$HOME/.config/fgj/config.yaml"

[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

if [[ -z "${CODEBERG_TOKEN:-}" ]]; then
    echo "ERROR: CODEBERG_TOKEN not set in .env" >&2
    exit 1
fi

mkdir -p "$(dirname "$CONFIG_FILE")"

cat > "$CONFIG_FILE" <<YAML
hosts:
    codeberg.org:
        hostname: codeberg.org
        token: ${CODEBERG_TOKEN}
        user: gurg
        git_protocol: https
YAML

chmod 600 "$CONFIG_FILE"
echo "✓ fgj config rebuilt from .env"
