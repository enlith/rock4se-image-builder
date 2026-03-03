# rock4se-image-builder (arm64-native fork)

Build SD-Card images for Radxa Rock 4 SE on an arm64 host (e.g., Debian arm64 VM on Apple Silicon).

Forked from [byte4RR4Y/rock4se-image-builder](https://github.com/byte4RR4Y/rock4se-image-builder) with the following changes:
- Native arm64 build support (no cross-compilation or QEMU needed)
- Three kernel options: Radxa BSP, generic Debian, or mainline
- RK3399-T hardware-optimized kernel config for mainline builds
- OS-level performance tunings for SD/eMMC storage
- Bluetooth support

## How it works
1. Builds the root filesystem inside a Docker container
2. Installs the selected kernel
3. Flashes the u-boot bootloader and root filesystem to an SD-Card image

## Requirements
- Debian arm64 host (tested on Debian 13 arm64 VM via UTM on M1 Mac)
- Docker

## Installation
```bash
cd rock4se-image-builder
chmod +x install.sh
sudo ./install.sh
```

## Build
```bash
sudo ./build.sh
```
This launches an interactive menu. Or use CLI flags:

```bash
sudo ./build.sh -s bookworm -d none -k radxa -H no -u debian -p <password> -b
```

## Kernel Options

| Option | Flag | Description |
|---|---|---|
| Radxa BSP (recommended) | `-k radxa` | Radxa-patched kernel (6.1.x) with full Rock 4 SE hardware support: VPU, ISP, RGA, board-specific DTB |
| Generic Debian | `-k standard` | Stock Debian arm64 kernel. Works but lacks some Rockchip-specific drivers |
| Mainline | `-k latest` | Compiles latest mainline kernel from source. Add `-V 6.19.4` to pin a version. Partial RK3399 support |

## CLI Options
```
-h, --help                          Show help
-s, --suite SUITE                   Debian suite (bookworm, trixie, sid, etc.)
-k, --kernel radxa/standard/latest  Kernel to install
-V, --kernel-version VERSION        Pin mainline kernel version (e.g., 6.19.4)
-H, --headers yes/no                Install kernel headers
-d, --desktop DESKTOP               Desktop (none/xfce4/gnome/mate/cinnamon/lxqt/lxde/kde/budgie)
-u, --username USERNAME             Sudo user username
-p, --password PASSWORD             Sudo user password
-i, --interactive yes/no            Interactive shell in build container
-b                                  Build without prompting
```

## Examples
```bash
# Radxa BSP kernel, CLI only (recommended)
sudo ./build.sh -s bookworm -d none -k radxa -H no -u debian -p builder -b

# Generic Debian kernel with XFCE desktop
sudo ./build.sh -s bookworm -d xfce4 -k standard -H yes -u debian -p builder -b

# Mainline kernel 6.19.4
sudo ./build.sh -s bookworm -d none -k latest -V 6.19.4 -H no -u debian -p builder -b
```

## Hardware Optimizations
The following tunings are applied to all builds for the Rock 4 SE (RK3399-T):
- I/O scheduler: `mq-deadline` for SD/eMMC
- CPU governor: `schedutil` for big.LITTLE (A72 + A53)
- ZRAM: 1GB with zstd compression
- tmpfs on `/tmp` (256MB) to reduce SD card wear
- Sysctl: `vm.swappiness=10`, `vm.dirty_ratio=5`, `vm.dirty_background_ratio=2`

## Flashing
See [FLASH_SD_CARD.md](FLASH_SD_CARD.md) for instructions.

## Adding custom packages
Append package names (one per line) to `config/apt-packages.txt`.

## Supported desktops
none, xfce, gnome, mate, cinnamon, lxqt, lxde, unity, budgie, kde plasma

## Credits
Original project by [byte4RR4Y](https://github.com/byte4RR4Y/rock4se-image-builder) — byte4rr4y@gmail.com
