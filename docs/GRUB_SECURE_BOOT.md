# GRUB + Secure Boot with sbctl (Custom Keys)

> Reference guide for Arch Linux with GRUB bootloader, btrfs `@` subvolume root, and sbctl-managed Secure Boot keys (no shim.efi).

## Why This Is Complicated

Arch's `grub` package embeds the **`shim_lock` module** in the GRUB core image by default. This module looks for `EFI_SHIM_LOCK_PROTOCOL` at boot — a protocol registered by `shim.efi` (Microsoft's signed bootloader). If you use sbctl custom keys instead of shim, the protocol doesn't exist and GRUB refuses to load the kernel.

Two errors you'll hit if you don't configure this correctly:

| Error | Cause |
|-------|-------|
| `shim_lock protocol not found` | `shim_lock` module is in the core image but shim.efi isn't in the boot chain |
| `verification requested but nobody cares` | `shim_lock` was removed but no other verifier is registered — GRUB refuses to load modules like `normal.mod` |

## The Fix

Two flags are required together:

```bash
sudo grub-install \
  --target=x86_64-efi \
  --efi-directory=/efi \
  --bootloader-id=GRUB \
  --disable-shim-lock \
  --modules="tpm"
```

### What each flag does

| Flag | Purpose |
|------|---------|
| `--target=x86_64-efi` | Build for UEFI 64-bit |
| `--efi-directory=/efi` | ESP mount point (not `/boot/efi`) |
| `--bootloader-id=GRUB` | NVRAM entry name and `/EFI/GRUB/` directory |
| `--disable-shim-lock` | Don't embed `shim_lock` module — GRUB won't look for shim.efi |
| `--modules="tpm"` | Embed TPM verifier — satisfies GRUB's verification requirement without blocking boot |

### Why `--modules="tpm"` is required

Without `shim_lock`, GRUB has **zero verifiers registered**. When Secure Boot is on, GRUB asks *"does anyone want to verify this file?"* before loading each module. With no verifier, the answer is "nobody cares" and GRUB drops to rescue mode.

The `tpm` module registers as a verifier that "cares" — it measures files to the TPM but **doesn't block them**. This satisfies GRUB's verification requirement.

### Common mistakes

| Mistake | What happens |
|---------|-------------|
| Using `--no-shim-lock` instead of `--disable-shim-lock` | `unrecognized option` error — wrong flag name |
| Using `--disable-shim-lock` without `--modules="tpm"` | `verification requested but nobody cares` → rescue mode |
| Using `--efi-directory=/boot/efi` | Wrong ESP path — your ESP is at `/efi` |
| Using `--removable` | Creates `BOOTX64.EFI` fallback — unnecessary for internal NVMe, causes Secure Boot conflicts |

## Full Setup Flow

### Prerequisites

- Arch Linux installed with GRUB, btrfs root on subvolume `@`
- ESP mounted at `/efi`
- `sbctl` installed: `sudo pacman -S sbctl`
- Secure Boot **disabled** in BIOS during setup

### Step 1: Generate keys

```bash
./scripts/sbctl-setup.sh
```

This creates signing keys at `/usr/share/secureboot/` and reboots you into BIOS.

### Step 2: Clear keys in BIOS

1. Enter BIOS/UEFI firmware (Del, F2, or F12 on boot)
2. Navigate to Secure Boot settings
3. Delete/clear ALL existing Secure Boot keys
4. This puts the firmware in **Setup Mode**
5. Save and boot back into Arch

### Step 3: Enroll keys and sign everything

```bash
./scripts/sbctl-sign.sh
```

This script:
1. Checks Secure Boot status
2. Enrolls keys (including Microsoft's for hardware compatibility)
3. Reinstalls GRUB with `--disable-shim-lock --modules="tpm"`
4. Adds `rootflags=subvol=@` to `/etc/default/grub` if needed
5. Regenerates `grub.cfg`
6. Signs all unsigned EFI binaries
7. Signs the kernel (`/boot/vmlinuz-linux`)
8. Reboots

### Step 4: Re-enable Secure Boot in BIOS

After the reboot from step 3, enter BIOS again and re-enable Secure Boot.

### Step 5: Verify

```bash
sbctl status
sbctl verify
```

Both should show everything is signed and Secure Boot is active.

## Manual Commands (if you need to run them individually)

```bash
# Reinstall GRUB without shim_lock, with TPM verifier
sudo grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --disable-shim-lock --modules="tpm"

# Regenerate grub.cfg
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Sign the GRUB binary
sudo sbctl sign -s /efi/EFI/GRUB/grubx64.efi

# Sign the kernel
sudo sbctl sign -s /boot/vmlinuz-linux

# Verify everything
sudo sbctl verify
```

## How sbctl vs shim.efi Compare

| Approach | Boot Chain | Works? |
|----------|-----------|--------|
| **shim.efi** (Microsoft-signed) | UEFI → shim → GRUB → kernel | Yes, but requires shim in the chain |
| **sbctl custom keys** (this setup) | UEFI → GRUB → kernel | Yes, but requires `--disable-shim-lock --modules="tpm"` |

With sbctl, your own keys sign `grubx64.efi` directly. UEFI verifies the signature, loads GRUB, and GRUB loads the kernel. No shim needed.

## archinstall Settings

When running `archinstall`:

- **Bootloader**: `grub`
- **GRUB removable**: **Disable** — not needed for internal NVMe, causes Secure Boot conflicts
- **The other Secure Boot option**: **Disable** — Secure Boot will be set up post-install with sbctl

## Troubleshooting

### `shim_lock protocol not found`

You're running GRUB with `shim_lock` still in the core image. Reinstall with `--disable-shim-lock --modules="tpm"`.

### `verification requested but nobody cares`

You disabled `shim_lock` but didn't add a replacement verifier. Add `--modules="tpm"` to `grub-install`.

### `unrecognized option --no-shim-lock`

The flag is `--disable-shim-lock`, not `--no-shim-lock`.

### GRUB drops to rescue mode after enabling Secure Boot

Make sure both flags are present: `--disable-shim-lock --modules="tpm"`. Then re-sign:

```bash
sudo sbctl sign -s /efi/EFI/GRUB/grubx64.efi
```

### Kernel updates break Secure Boot

The sbctl pacman hook should auto-re-sign. If it doesn't:

```bash
sudo sbctl sign -s /boot/vmlinuz-linux
sudo sbctl sign -s /efi/EFI/GRUB/grubx64.efi
```

### Need to start over

1. Disable Secure Boot in BIOS
2. Boot into Arch
3. Run `./scripts/sbctl-sign.sh` again (it's idempotent)
4. Re-enable Secure Boot in BIOS