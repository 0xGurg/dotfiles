#!/bin/bash
# ============================================================================
# Rsync the latest snapper snapshot to /srv/data for off-NVMe backup.
#
# Uses --link-dest so each backup appears full but only stores diffs
# (hardlinks for unchanged files). Safe to delete old backups — hardlinks
# keep their data until the last reference is removed.
#
# Usage: sudo ./scripts/snapper-rsync-backup.sh
#
# Recommended: run via systemd timer or cron after snapper-timeline fires.
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status()  { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error()   { echo -e "${RED}✗${NC} $1"; }

# ── Config ─────────────────────────────────────────────────────────────────────
DEST_BASE="/srv/data/snapper-backup"
SNAPPER_ROOT="/"
KEEP_BACKUPS=10          # number of incremental backups to keep on HDD
EXCLUDE_FILE=""          # optional: path to rsync exclude file

# ── Guards ─────────────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  print_error "Run this script as root (sudo)."
  exit 1
fi

if ! command -v snapper &> /dev/null; then
  print_error "snapper is not installed."
  exit 1
fi

if ! mountpoint -q "$DEST_BASE" 2>/dev/null && ! mountpoint -q "/srv/data" 2>/dev/null; then
  print_error "$DEST_BASE is not mounted. Is /srv/data mounted?"
  exit 1
fi

# ── Find latest snapshot ──────────────────────────────────────────────────────
LATEST=$(snapper -c root list --type single 2>/dev/null | tail -1 | awk '{print $1}')

if [[ -z "$LATEST" ]]; then
  print_error "No snapper snapshots found."
  exit 1
fi

SOURCE="/.snapshots/${LATEST}/snapshot"

if [[ ! -d "$SOURCE" ]]; then
  print_error "Snapshot directory not found: $SOURCE"
  exit 1
fi

print_status "Latest snapper snapshot: #${LATEST}"
print_status "Source: ${SOURCE}"

# ── Prepare destination ───────────────────────────────────────────────────────
mkdir -p "$DEST_BASE"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEST="${DEST_BASE}/${TIMESTAMP}"

# Find the most recent backup for --link-dest
LINK_DEST=""
PREV=$(ls -1d "${DEST_BASE}"/[0-9]* 2>/dev/null | sort | tail -1)
if [[ -n "$PREV" && -d "$PREV" ]]; then
  LINK_DEST="$PREV"
  print_status "Incremental backup — linking against: $(basename "$PREV")"
else
  print_status "First backup — full copy"
fi

# ── Rsync ─────────────────────────────────────────────────────────────────────
RSYNC_ARGS=(
  -aHAXS              # archive, hardlinks, acls, xattrs, sparse
  --delete            # delete files in dest that no longer exist in source
  --numeric-ids
  --info=progress2
)

if [[ -n "$LINK_DEST" ]]; then
  RSYNC_ARGS+=(--link-dest="$LINK_DEST")
fi

if [[ -n "$EXCLUDE_FILE" && -f "$EXCLUDE_FILE" ]]; then
  RSYNC_ARGS+=(--exclude-from="$EXCLUDE_FILE")
fi

print_status "Rsyncing snapshot #${LATEST} → ${DEST} ..."
rsync "${RSYNC_ARGS[@]}" "$SOURCE/" "$DEST/"

print_success "Backup created: ${DEST}"

# ── Cleanup old backups ───────────────────────────────────────────────────────
BACKUP_COUNT=$(ls -1d "${DEST_BASE}"/[0-9]* 2>/dev/null | wc -l)
if [[ "$BACKUP_COUNT" -gt "$KEEP_BACKUPS" ]]; then
  REMOVE_COUNT=$((BACKUP_COUNT - KEEP_BACKUPS))
  print_status "Removing ${REMOVE_COUNT} old backup(s)..."
  ls -1d "${DEST_BASE}"/[0-9]* | sort | head -n "$REMOVE_COUNT" | while read -r old; do
    rm -rf "$old"
    print_success "Removed: $(basename "$old")"
  done
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
print_status "Backup summary:"
echo "  Snapshot: #${LATEST}"
echo "  Location: ${DEST}"
echo "  Total backups on HDD: $(ls -1d "${DEST_BASE}"/[0-9]* 2>/dev/null | wc -l)"
echo "  Disk usage:"
du -sh "$DEST_BASE" 2>/dev/null || true
