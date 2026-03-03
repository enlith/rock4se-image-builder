# Build Environment Setup on macOS (Apple Silicon)

This guide sets up a Debian arm64 VM on an Apple Silicon Mac for building Rock 4 SE images natively.

## Prerequisites
- Mac with Apple Silicon (M1/M2/M3/M4)
- [Homebrew](https://brew.sh) installed

## 1. Install UTM

```bash
brew install --cask utm
```

## 2. Download Debian arm64 ISO

```bash
curl -L -o ~/Downloads/debian-arm64-netinst.iso \
  https://cdimage.debian.org/cdimage/release/current/arm64/iso-cd/debian-13.3.0-arm64-netinst.iso
```

## 3. Create the VM in UTM

1. Open UTM → "Create a New Virtual Machine"
2. Select **Virtualize** (not Emulate — gives native M1 speed)
3. Select **Linux**
4. Boot ISO: browse to `~/Downloads/debian-arm64-netinst.iso`
5. Hardware:
   - Memory: **8192 MB**
   - CPU Cores: **6** (leave some for macOS)
6. Storage: **64 GB**
7. Name: `debian-rock4se-builder`
8. Save and Start

## 4. Install Debian

- Choose "Install" (text mode)
- Hostname: `rock4se-builder`
- Create a user account (e.g., `rock4se` / `builder`)
- Partitioning: "Guided - use entire disk" → all files in one partition
- Software selection: check only **SSH server** and **standard system utilities**
- Install GRUB to the virtual disk

After install completes, **stop the VM**, remove the ISO from the CD drive in UTM settings, then start again.

## 5. Configure Port Forwarding

1. Stop the VM
2. Edit VM → Network → add port forward rule:
   - Protocol: **TCP**
   - Guest Port: **22**
   - Host Port: **2222**
3. Save and start the VM

## 6. Set Up the Build Environment

From your Mac terminal:

```bash
# Install sudo (minimal Debian doesn't include it)
ssh -p 2222 rock4se@localhost "su -c 'apt update -y && apt install -y sudo && /usr/sbin/usermod -aG sudo rock4se' root"
# Enter root password when prompted, then reconnect for group change:

# Clone and install
ssh -p 2222 rock4se@localhost bash <<'EOF'
echo 'builder' | sudo -S apt install -y git
git clone -b arm64-native-build https://github.com/enlith/rock4se-image-builder.git
cd rock4se-image-builder
chmod +x install.sh build.sh config/*
echo 'builder' | sudo -S ./install.sh
EOF
```

## 7. Build an Image

```bash
ssh -p 2222 rock4se@localhost "cd rock4se-image-builder && echo 'builder' | sudo -S ./build.sh -s bookworm -d none -k radxa -H no -u debian -p builder -b"
```

## 8. Copy Image to Mac

```bash
scp -P 2222 rock4se@localhost:"rock4se-image-builder/output/*/Debian*.img" ~/Downloads/
```

Then follow [FLASH_SD_CARD.md](FLASH_SD_CARD.md) to flash it to an SD card.

## Troubleshooting

**VM has no network during Debian install:**
Press `Alt+F2` for a shell, run `ping -c 2 8.8.8.8`. If it works but DNS fails, run `echo "nameserver 8.8.8.8" > /etc/resolv.conf` then `Alt+F1` to retry. You can also skip the mirror step and configure apt after first boot.

**After Debian install, installer starts again:**
Stop the VM, edit settings, remove/eject the ISO from the CD drive, then start again.

**SSH connection refused:**
Ensure port forwarding is configured (guest 22 → host 2222) and the VM is fully booted.
