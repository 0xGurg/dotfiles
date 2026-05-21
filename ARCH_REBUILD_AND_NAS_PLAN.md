# Arch Rebuild and Phase 2 NAS Plan

> Last updated: 2026-05-21

## Final Decisions

- Use `archinstall` from the Arch ISO.
- Reformat the current install destructively; no backup of the current system is needed.
- Rebuild the OS on `btrfs`.
- Use `grub` in UEFI mode.
- Do **not** use disk encryption / LUKS.
- Re-sign Secure Boot manually **after** installation.
- Keep Arch as the main OS.
- Move the NAS / Plex storage design into **Phase 2**.
- Keep the OS/root storage separate from the future HDD media pool.

## Current Hardware Snapshot

- CPU: Intel `i5-9400`
- RAM: `32 GiB`
- Main OS disk: `nvme0n1` `476.9G` ADATA SX8200PNP
- Secondary disk: `sda` `931.5G` WD HDD
- Boot mode: UEFI
- Current firmware state: Secure Boot enabled
- Network: Realtek `1 GbE`

---

## Phase 1 — Destructive Arch Rebuild

### Goals

- Clean Arch reinstall
- Root filesystem on Btrfs
- GRUB as the bootloader
- Simpler rollback/snapshot workflow than the old ext4+LVM layout
- Keep the OS on the NVMe
- Reuse `sda` as a separate non-root disk

### Locked-In Choices

- `archinstall`
- `grub`
- `btrfs`
- no `LUKS`
- no disk swap
- re-enable zram after install
- manual Secure Boot signing after install

### Recommended Disk Layout

#### `nvme0n1` (OS disk)

- GPT
- `p1`: `512 MiB` FAT32 EFI System Partition mounted at `/efi`
- `p2`: Btrfs using the rest of the disk

Recommended Btrfs subvolumes:

- `@` → `/`
- `@home` → `/home`
- `@log` → `/var/log`
- `@pkg` → `/var/cache/pacman/pkg`

Recommended mount options:

- `compress=zstd`
- `noatime`

#### `sda` (separate local disk)

- Do **not** mix `sda` into the root Btrfs filesystem.
- Use it as a separate filesystem.
- Best default role: local backup / staging / downloads / scratch disk.

Recommended layout:

- GPT
- one Btrfs partition using the whole disk
- default mountpoint: `/srv/data`

Optional later subvolumes on `sda`:

- `@backup`
- `@downloads`
- `@staging`

### Why `sda` Stays Separate

- Do not build one mixed NVMe+HDD root filesystem.
- Keeping the HDD separate makes reinstalls, recovery, and later NAS expansion much easier.
- The NVMe should remain the fast workstation / app / metadata disk.

### Recommended `archinstall` Runbook

1. Boot the latest Arch ISO in **UEFI** mode.
2. If needed, update the installer on the ISO:
   - `pacman -Sy archinstall`
3. Temporarily **disable Secure Boot** in firmware.
4. Start the installer:
   - `archinstall`
5. Use these choices as the baseline:
   - bootloader: `grub`
   - partitioning: `manual`
   - filesystem: `btrfs`
   - encryption: `none`
   - swap: `disabled`
   - kernel: `linux`
   - profile: whatever desktop/minimal profile is actually desired
6. Create on `nvme0n1`:
   - `512 MiB` FAT32 ESP mounted at `/efi`
   - one Btrfs partition for the rest
7. Create the Btrfs subvolumes listed above.
8. Simplest handling for `sda`:
   - either leave it alone during `archinstall` and format it after first boot,
   - or create its single Btrfs partition in the installer if comfortable doing so.

### Why Use `/efi` Instead of a Separate FAT `/boot`

- Keeps `/boot` inside the Btrfs root.
- Kernels and initramfs stay aligned with root snapshots better.
- Better fit for a Btrfs + GRUB rollback workflow.

### Swap Plan

- Do **not** create disk swap during install.
- Re-enable zram after first boot.
- Verify zram is active after first boot with `zramctl` or `/proc/swaps`.
- Only revisit disk swap if hibernation becomes a real requirement later.

### Snapshot Plan

- Use `snapper` after the base system is installed and booting.
- Treat snapshots as rollback points, not as the only backup.
- Keep the initial `archinstall` subvolume layout simple.
- Create the Snapper-specific snapshot layout after first boot instead of forcing everything into the installer.

Recommended post-install snapshot layout:

- `@` → `/`
- `@home` → `/home`
- `@snapshots` → `/.snapshots`
- `@log` → `/var/log`
- `@pkg` → `/var/cache/pacman/pkg`

Maintenance note:

- If snapshot churn gets high or space usage becomes odd after many snapshot deletions, plan for occasional targeted Btrfs balance operations.

### Suggested Additional Packages

Useful packages to have installed early:

- `btrfs-progs`
- `snapper`
- `grub-btrfs`
- `inotify-tools`
- `rsync`
- `sbctl`

Optional quality-of-life additions later:

- `snap-pac`
- `btrfs-assistant`

### Post-Install Tasks

1. Boot the new system and update it.
2. Verify Btrfs mounts and subvolumes.
3. Re-enable zram.
4. Install/restow dotfiles.
5. Configure Snapper:
   - create `@snapshots`
   - mount it at `/.snapshots`
   - create the root Snapper config
   - optionally create a separate home Snapper config
   - enable snapshot timeline/cleanup timers
6. Enable `grub-btrfs` if GRUB snapshot menu entries are wanted.
7. Format and mount `sda` if that was postponed until after first boot.
8. Verify boot, audio, network, GPU, suspend, and updates.

### Secure Boot Signing Plan After Install

- Leave Secure Boot disabled until the new system is booting correctly.
- This repo already contains helper scripts:
  - `scripts/sbctl-setup.sh`
  - `scripts/sbctl-sign.sh`

Recommended flow:

1. Boot the new Arch install.
2. Make sure `sbctl` is installed.
3. Keep a current Arch ISO / recovery USB available before changing Secure Boot state.
4. Review the scripts for the new GRUB-based setup.
5. Confirm the GRUB EFI binary that must be signed is the one reported by `sbctl verify`.
6. Run:
   - `./scripts/sbctl-setup.sh`
7. Reboot into firmware and clear existing Secure Boot keys to enter Setup Mode.
8. Boot back into Arch.
9. Run:
   - `./scripts/sbctl-sign.sh`
10. Verify with `sbctl status` and confirm the GRUB EFI binary shows up as signed.
11. Re-enable Secure Boot in firmware.

Important note:

- The old system used `systemd-boot`, but the new plan uses `grub`.
- Before re-enabling Secure Boot, confirm that the scripts are signing the actual GRUB EFI binary found by `sbctl verify`.

### Phase 1 Completion Status

All Phase 1 items are done:

- ✅ Arch reinstalled with `archinstall`, `grub`, `btrfs`, no LUKS
- ✅ Btrfs subvolumes: `@` → `/`, `@home` → `/home`, `@log` → `/var/log`, `@pkg` → `/var/cache/pacman/pkg`
- ✅ ESP at `/efi` (1G FAT32)
- ✅ zram active (4G zstd)
- ✅ Secure Boot enabled with custom keys (sbctl), all EFI binaries signed
- ✅ `sda1` mounted at `/srv/data` (btrfs, separate from root)
- ✅ Snapper configured with timeline/cleanup timers
- ✅ grub-btrfs installed for snapshot boot menu entries
- ✅ ESP cleaned up — no stale systemd-boot, BOOTX64, or standalone images

Actual subvolume names differ slightly from the original plan (`@log` instead of `@var_log`). This is cosmetic and has no functional impact.

### Backup Setup

#### What is backed up

The latest snapper snapshot of `/` is rsynced to `/srv/data/snapper-backup/` on the HDD. This protects against NVMe failure — the HDD holds a full, browsable, file-level copy of the root filesystem.

#### How it works

- **Script**: `scripts/snapper-rsync-backup.sh`
- **Schedule**: daily at 03:00 via systemd timer (`snapper-rsync-backup.timer`)
- **Method**: `rsync -aHAXS --delete --link-dest=<previous>`
  - `--link-dest` makes each backup appear as a full copy but only stores diffs (unchanged files are hardlinked)
  - Each backup directory is a complete, browsable tree — no special tools needed to restore individual files
- **Retention**: keeps the last 10 backups on HDD, prunes older ones
- **IO priority**: `IOSchedulingClass=idle` so backups don't compete with real work

#### Directory structure on HDD

```
/srv/data/snapper-backup/
├── 20260521-100500/    ← first backup (full copy)
├── 20260522-030012/    ← only diffs (hardlinks for the rest)
├── 20260523-030008/    ← only diffs
...
```

#### Snapper snapshot schedule

| Timer | Schedule | Purpose |
|---|---|---|
| `snapper-timeline.timer` | Hourly | Creates snapshots |
| `snapper-cleanup.timer` | Hourly | Prunes old snapshots |

Snapshot retention on NVMe:

| Type | Limit |
|---|---|
| Hourly | 8 |
| Daily | 7 |
| Weekly | 0 |
| Monthly | 3 |
| Yearly | 0 |

Long-term retention is handled by the HDD rsync backups, not by keeping many NVMe snapshots.

#### What the backup protects

- ✅ All files, configs, dotfiles in the root subvolume
- ✅ Browsable at any time — just `ls /srv/data/snapper-backup/<timestamp>/`
- ✅ Individual file recovery: `cp` or `rsync` from the backup
- ✅ Full system recovery after NVMe replacement (see below)

#### What the backup does NOT protect

- ❌ Installed packages — need `bigkis apply` to reinstall
- ❌ Bootloader/EFI state — need `grub-install` after bare-metal restore
- ❌ `/home` — only the root subvolume is snapshotted and backed up (add a home snapper config later if needed)

#### Bare-metal recovery after NVMe failure

1. Install a new NVMe.
2. Reinstall Arch with the same layout (btrfs, grub, subvolumes).
3. Restore from HDD:
   ```bash
   mount /dev/nvme0n1p2 /mnt -o subvol=/@
   rsync -aHAXS --delete /srv/data/snapper-backup/<latest>/ /mnt/
   arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi
   arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
   ```
4. Reboot — system is back to the state of the last backup.
5. Reinstall packages: `sudo bigkis apply --config ~/.config/bigkis/system.toml`

---

## Phase 2 — NAS and Plex

### Goals

- Keep Arch as the host OS.
- Keep the OS, apps, Plex metadata, and transcode on the NVMe.
- Keep media and NAS data on HDDs.
- Expand storage gradually, two drives at a time.
- Get an Unraid-like growth model without replacing Arch.

### Recommended Storage Model

- `mergerfs + SnapRAID`
- individual HDD filesystems as `ext4` or `XFS`
- no Btrfs RAID5/6
- do not mix the NVMe into the HDD pool

### Why This Is the Best Fit

- Closest Linux DIY match to Unraid-style incremental growth
- Good fit for Plex/media workloads
- Works with different disk sizes
- Lets drives be added later without rebuilding a striped RAID
- Keeps data disks individually readable if the array is broken beyond parity recovery

### Important Limitation

- SnapRAID parity is **not** real-time.
- Protection only reflects the last successful `snapraid sync`.
- This is fine for mostly-static media libraries.
- It is not ideal for high-churn VM / database / scratch workloads.

Basic recovery note:

- If a protected data disk fails, replace it, update mounts/config as needed, and use the SnapRAID recovery workflow (`fix` / rebuild onto the replacement disk) before resyncing the array.

### Role of `sda` in Phase 2

Best default role:

- keep `sda` separate from the main media pool
- use it for local backup, downloads, temporary staging, or scratch

Not recommended:

- do not use the `1 TB` drive as parity for a future `6 TB` pool
- do not make it part of the OS root filesystem

### Plex Layout

- Plex config / metadata / transcode: NVMe
- media library: merged HDD pool
- backups of Plex config: `sda` or another backup target

### Drive Guidance

Best parity drive classes:

- `WD Red Plus`
- `WD Red Pro`
- `Seagate IronWolf`
- `Seagate IronWolf Pro`

Avoid unless the exact model is verified:

- plain `WD Red`

Budget data-drive rule:

- `BarraCuda` is acceptable as a **data** drive if budget forces it
- `BarraCuda` is **not** the preferred parity drive
- do not build the parity tier around desktop-class drives if better NAS-class options are affordable

The earlier 6 TB MediaMarkt drive identified during research was:

- `ST6000DM003`

Treat it as:

- usable budget data disk
- not a parity disk
- not the ideal drive family to standardize on long-term

### Mixed-Drive Layout Under Consideration

This layout is valid with `SnapRAID`:

- `2 x` parity-class `6 TB` drives (`WD Red Plus` / `IronWolf`)
- `4 x` `6 TB` `BarraCuda` data drives

Why this can work:

- parity drives only need to be at least as large as the largest data drive
- dual parity is more conservative than strictly required for only four data disks
- that extra caution is useful if the data disks are cheaper desktop models

Main caveat:

- better parity drives do **not** turn weak data drives into strong NAS drives
- the BarraCuda disks would still be the weak point of the array

### Recommended Incremental Buy Path

Best purchase order:

#### Stage A — 2 drives total

- `1 x` parity-class `6 TB`
- `1 x` data `6 TB`

Layout:

- `1 parity`
- `1 data`

#### Stage B — 4 drives total

- add `2 x` data `6 TB`

Layout:

- `1 parity`
- `3 data`

#### Stage C — 6 drives total

- add `1 x` parity-class `6 TB`
- add `1 x` data `6 TB`

Final layout:

- `2 parity`
- `4 data`

Why this order is better:

- both purchased drives are useful immediately
- avoids buying a second parity disk too early and leaving it underused
- lands cleanly at the desired final `2 parity + 4 data` design

### Example Future Layout

Example mount structure:

- `/srv/parity1`
- `/srv/parity2`
- `/srv/disk1`
- `/srv/disk2`
- `/srv/disk3`
- `/srv/disk4`
- merged media mount: `/srv/storage`

Example usage:

- Plex libraries point to `/srv/storage/media`
- downloader / staging directories can live on `sda` or a non-parity area

### Suggested Maintenance Routine

- nightly or regular `snapraid sync`
- weekly `snapraid scrub`
- SMART monitoring on all disks
- parity drives at least as large as the largest data drive
- keep multiple `content` file copies on different devices

For dual parity, keep at least **3** SnapRAID `content` copies on different disks.

### M.2-to-SATA / Enclosure Warning

Do **not** commit to a `6-port M.2-to-SATA` adapter until all of this is confirmed:

- the spare M.2 slot is PCIe-capable
- there is enough power for multiple 3.5" HDDs
- the PSU and especially the `+12V` rail can handle HDD spin-up current safely
- there is actual physical room / mounting
- the controller and drives can be cooled properly

Given this machine class, a powered external enclosure / DAS may still be safer than trying to force six internal drives.

---

## Final Direction

### Phase 1

- destructive Arch reinstall
- `archinstall`
- `grub`
- `btrfs`
- no `LUKS`
- no disk swap
- zram after install
- manual Secure Boot signing after install
- `sda` kept as a separate local disk, not part of root

### Phase 2

- Arch-hosted Plex/NAS
- `mergerfs + SnapRAID`
- HDD pool separate from the NVMe OS disk
- prefer NAS-class parity drives
- treat BarraCuda as budget data drives only
- grow the pool gradually in an Unraid-like way

## Immediate Next Actions

1. ~~Reinstall Arch with the Phase 1 layout above.~~ ✅
2. ~~Get the new GRUB + Btrfs system stable.~~ ✅
3. ~~Re-enable zram and set up Snapper.~~ ✅
4. ~~Use the existing `sbctl` scripts in this repo to re-sign and re-enable Secure Boot.~~ ✅
5. Decide the exact parity drive models for Phase 2.
6. Only after that, choose the final enclosure / adapter path for the future HDD pool.
7. Consider adding a home snapper config for `/home` backup coverage.
