#!/bin/bash
# ============================================================================
# Rsync latest snapper snapshots to /srv/data for off-NVMe backup.
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
shopt -s nullglob

source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

# ── Config ─────────────────────────────────────────────────────────────────────
DEST_MOUNT="/srv/data"
ROOT_DEST_BASE="${DEST_MOUNT}/snapper-backup"
HOME_DEST_BASE="${DEST_MOUNT}/home-snapper-backup"
KEEP_BACKUPS=10          # number of incremental backups to keep per config
EXCLUDE_FILE=""          # optional: path to rsync exclude file

# config:subvolume:destination:required|optional
BACKUP_TARGETS=(
  "root:/:${ROOT_DEST_BASE}:required"
  "home:/home:${HOME_DEST_BASE}:optional"
)

# ── Guards ─────────────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  print_error "Run this script as root (sudo)."
  exit 1
fi

if ! command -v snapper &> /dev/null; then
  print_error "snapper is not installed."
  exit 1
fi

if ! mountpoint -q "$DEST_MOUNT" 2>/dev/null; then
  print_error "$DEST_MOUNT is not mounted. Refusing to write backups to root filesystem."
  exit 1
fi

# ── Helpers ────────────────────────────────────────────────────────────────────
latest_snapshot() {
  local config="$1"
  snapper -c "$config" list --type single 2>/dev/null \
    | awk 'NF && $1 ~ /^[0-9]+$/ { latest=$1 } END { print latest }'
}

backup_count() {
  local dest_base="$1"
  local backups=("${dest_base}"/[0-9]*)
  echo "${#backups[@]}"
}

backup_config() {
  local config="$1"
  local subvolume="$2"
  local dest_base="$3"
  local requirement="$4"

  if ! snapper -c "$config" get-config &>/dev/null; then
    if [[ "$requirement" == "required" ]]; then
      print_error "Required snapper config not found: ${config}"
      return 1
    fi

    print_status "Skipping optional snapper config '${config}' — not configured yet."
    return 0
  fi

  local latest
  latest=$(latest_snapshot "$config")

  if [[ -z "$latest" ]]; then
    if [[ "$requirement" == "required" ]]; then
      print_error "No snapshots found for required config: ${config}"
      return 1
    fi

    print_status "Skipping optional snapper config '${config}' — no snapshots found."
    return 0
  fi

  local source="${subvolume%/}/.snapshots/${latest}/snapshot"
  if [[ ! -d "$source" ]]; then
    print_error "Snapshot directory not found for ${config}: ${source}"
    return 1
  fi

  print_status "Backing up '${config}' snapshot #${latest}"
  print_status "Source: ${source}"

  mkdir -p "$dest_base"

  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local dest="${dest_base}/${timestamp}"

  # Find the most recent backup for --link-dest.
  local link_dest=""
  local prev
  local existing_backups=("${dest_base}"/[0-9]*)
  prev=""
  if [[ "${#existing_backups[@]}" -gt 0 ]]; then
    prev=$(printf '%s\n' "${existing_backups[@]}" | sort | tail -1)
  fi

  if [[ -n "$prev" && -d "$prev" ]]; then
    link_dest="$prev"
    print_status "Incremental backup — linking against: $(basename "$prev")"
  else
    print_status "First backup — full copy"
  fi

  local rsync_args=(
    -aHAXS              # archive, hardlinks, acls, xattrs, sparse
    --delete            # delete files in dest that no longer exist in source
    --numeric-ids
    --info=progress2
  )

  if [[ -n "$link_dest" ]]; then
    rsync_args+=(--link-dest="$link_dest")
  fi

  if [[ -n "$EXCLUDE_FILE" ]]; then
    if [[ -f "$EXCLUDE_FILE" ]]; then
      rsync_args+=(--exclude-from="$EXCLUDE_FILE")
    else
      print_warning "Exclude file is configured but missing: ${EXCLUDE_FILE}"
    fi
  fi

  local tmp_dest="${dest}.incomplete"
  rm -rf "$tmp_dest"
  mkdir -p "$tmp_dest"

  print_status "Rsyncing ${config} snapshot #${latest} → ${dest} ..."
  if ! rsync "${rsync_args[@]}" "$source/" "$tmp_dest/"; then
    rm -rf "$tmp_dest"
    print_error "Rsync failed for ${config}; incomplete backup was removed."
    return 1
  fi

  mv "$tmp_dest" "$dest"

  print_success "Backup created: ${dest}"

  local count
  count=$(backup_count "$dest_base")
  if [[ "$count" -gt "$KEEP_BACKUPS" ]]; then
    local remove_count=$((count - KEEP_BACKUPS))
    print_status "Removing ${remove_count} old '${config}' backup(s)..."
    local backups=("${dest_base}"/[0-9]*)
    local sorted_backups=()
    mapfile -t sorted_backups < <(printf '%s\n' "${backups[@]}" | sort)

    local old
    for old in "${sorted_backups[@]:0:${remove_count}}"; do
      rm -rf "$old"
      print_success "Removed: $(basename "$old")"
    done
  fi

  echo ""
  print_status "${config} backup summary:"
  echo "  Snapshot: #${latest}"
  echo "  Location: ${dest}"
  echo "  Total backups on HDD: $(backup_count "$dest_base")"
  echo "  Disk usage:"
  du -sh "$dest_base" 2>/dev/null || true
  echo ""
}

# ── Backup all configured targets ──────────────────────────────────────────────
FAILED=0

for target in "${BACKUP_TARGETS[@]}"; do
  IFS=: read -r config subvolume dest_base requirement <<< "$target"
  if ! backup_config "$config" "$subvolume" "$dest_base" "$requirement"; then
    FAILED=1
    if [[ "$requirement" == "required" ]]; then
      print_error "Required backup target failed: ${config}"
    else
      print_warning "Optional backup target failed: ${config}"
    fi
  fi
done

exit "$FAILED"
