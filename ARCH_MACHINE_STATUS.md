# Arch Machine Status

> Last updated: 2026-05-26
>
> Roles: personal workstation / gaming / NAS / Plex host

## Hardware

| Component | Detail |
|---|---|
| CPU | Intel i5-9400 |
| RAM | 32 GiB |
| GPU (iGPU) | Intel UHD Graphics 630 |
| GPU (dGPU) | NVIDIA GTX 1650 Mobile / Max-Q (TU117M) |
| OS disk | `nvme0n1` 476.9G ADATA SX8200PNP |
| Data disk | `sda` 931.5G WD HDD |
| Network | Realtek 1 GbE, IP `10.0.1.122/24` |
| Boot | UEFI, Secure Boot enabled |

---

## OS

- Arch Linux, kernel `7.0.9-arch2-1`
- Bootloader: GRUB
- Filesystem: Btrfs
- ESP at `/efi` (1G FAT32)
- No LUKS, no disk swap
- zram active: 4G zstd at `/dev/zram0`

### Btrfs subvolumes — `nvme0n1p2`

| Subvolume | Mountpoint | Purpose |
|---|---|---|
| `@` | `/` | Root |
| `@home` | `/home` | User data, dotfiles, configs |
| `@log` | `/var/log` | System logs |
| `@pkg` | `/var/cache/pacman/pkg` | Package cache |
| `@fast_games` | `/fast_games` | Steam, Lutris game libraries |

All with `compress=zstd:3`, `ssd`, `discard=async`, `space_cache=v2`.

### Filesystems — `sda1`

| Subvolume | Mountpoint | Purpose |
|---|---|---|
| top-level | `/srv/data` | Samba share, backups, media staging |

Btrfs with `compress=zstd:3`, `discard=async`.

---

## Security

- **Secure Boot**: enabled, custom keys via `sbctl` — all EFI binaries signed
- **Firewall**: UFW active, default deny incoming / allow outgoing
  - TCP 445 (SMB) allowed from `10.0.1.0/24` only
- **User authentication**: Samba `security = user`, share protected by password

---

## Desktop

- **Compositor**: Hyprland (Wayland)
- **Terminal**: Ghostty
- **NVIDIA driver**: `nvidia-open` 595.71.05, `nvidia-utils` + `lib32-nvidia-utils`
- **Mesa**: 26.1.1 (Intel iGPU)
- **Audio**: PipeWire + WirePlumber

---

## Services

| Service | State | Notes |
|---|---|---|
| `smb` + `nmb` | enabled, active | Samba share at `/srv/data`, valid user: `gurg` |
| `ufw` | enabled, active | See firewall section above |
| `snapper-timeline.timer` | enabled, active | Hourly root snapshots |
| `snapper-cleanup.timer` | enabled, active | Prunes old root snapshots |
| `snapper-rsync-backup.timer` | enabled, active | Daily 03:30 rsync to HDD |
| `pipewire` + `wireplumber` | — (user) | Audio routing |

---

## Package Management

Declarative via **bigkis** at `~/.config/bigkis/system.toml`.

Backends: pacman, AUR (`yay`), Flatpak, pnpm.

Apply with: `bigkis apply`

---

## Snapshots and Backup

### Snapper — NVMe

Only the `root` Snapper config currently exists.

| Config | Subvolume | Snapshot path |
|---|---|---|
| `root` | `/` | `/.snapshots/N/snapshot` |
| `home` | `/home` | pending — create `home` Snapper config |

Snapshot retention on NVMe:

| Type | Limit |
|---|---|
| Hourly | 8 |
| Daily | 7 |
| Weekly | 0 |
| Monthly | 3 |
| Yearly | 0 |

### Rsync backup — HDD

Script: `scripts/snapper-rsync-backup.sh`
Schedule: daily at 03:30 via systemd timer
Method: `rsync -aHAXS --delete --link-dest=<previous>` per Snapper config
Retention: 10 backups per config

```
/srv/data/snapper-backup/           ← root snapshots
/srv/data/home-snapper-backup/      ← home snapshots (once home config exists)
```

### What is protected

- ✅ Root subvolume (system configs, packages, etc.)
- ✅ `/home` — once `home` Snapper config is created

### What is NOT protected

- ❌ Installed packages — reinstall via `bigkis apply`
- ❌ Bootloader/EFI state — reinstall via `grub-install`
- ❌ `/srv/data` (HDD share/media) and `/fast_games` (games, re-downloadable)

### Bare-metal recovery

1. Install new NVMe
2. Reinstall Arch with same layout (btrfs, grub, subvolumes)
3. Restore root: `rsync -aHAXS --delete /srv/data/snapper-backup/<latest>/ /mnt/`
4. Restore home: `rsync -aHAXS --delete /srv/data/home-snapper-backup/<latest>/ /mnt/home/`
5. `grub-install` + `grub-mkconfig` from chroot
6. Reboot, then `bigkis apply`

---

## Samba

- Share: `[data]` at `/srv/data`
- Valid user: `gurg`
- Security: user-level auth
- SMB ports: TCP 445 (firewalled to LAN only)
- Avahi/mDNS discovery: pending

---

## Pending Setup

### High priority

- [ ] Create `home` Snapper config (commands ready)
- [ ] Re-install updated systemd units for backup timer (`systemctl daemon-reload`)
- [ ] Add `smartmontools` to bigkis for drive health monitoring

### Gaming

- [ ] Add to bigkis: `gamemode`, `lib32-gamemode`, `mangohud`, `lib32-mangohud`, `wine-staging`, `winetricks`, `lutris`
- [ ] Configure Steam library at `/fast_games/steam`
- [ ] Configure Lutris library at `/fast_games/lutris`

### Plex

- [ ] Add `plex-media-server` to AUR packages in bigkis
- [ ] Enable: `sudo systemctl enable --now plexmediaserver`
- [ ] Point libraries at `/srv/data/Videos`, `/srv/data/Pictures`, etc.

### Networking

- [ ] Add `avahi` to bigkis for SMB service discovery
- [ ] Create `/etc/avahi/services/smb.service`

---

## Phase 2 — NAS drive pool (future)

Architecture: `mergerfs + SnapRAID`
Target: 2 parity + 4 data drives, incremental growth

| Stage | Drives |
|---|---|
| A | 1 parity-class 6 TB + 1 data 6 TB |
| B | +2 data 6 TB |
| C | +1 parity-class 6 TB + 1 data 6 TB |

- Parity drives: WD Red Plus / Seagate IronWolf (NAS-class)
- Data drives: BarraCuda acceptable (budget)
- Individual disk filesystems: XFS
- Keep `sda` separate from pool (used for backups)
- NVMe hosts OS, Plex metadata, transcode — not mixed into pool
- Enclosure/DAS decision pending
