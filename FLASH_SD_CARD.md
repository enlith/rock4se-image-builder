# Flashing the Image to an SD Card (macOS)

## Prerequisites
- A microSD card (8GB+ recommended)
- A USB SD card reader

## Steps

1. Insert the SD card and identify the device:
   ```bash
   diskutil list
   ```
   Look for your SD card (e.g., `/dev/disk4`). Verify by checking the size matches your card.

2. Unmount the SD card:
   ```bash
   diskutil unmountDisk /dev/diskN
   ```

3. Flash the image (use `rdiskN` for faster writes):
   ```bash
   sudo dd if=~/Downloads/Debian-bookworm-none-Kernel-standard.img of=/dev/rdiskN bs=4M status=progress
   ```

4. Eject the card:
   ```bash
   diskutil eject /dev/diskN
   ```

Replace `/dev/diskN` with your actual SD card device. **Double-check the device — writing to the wrong disk will destroy data.**

## First Boot

On first boot the device will automatically resize the root filesystem to fill the SD card and reboot once. After that it's ready to use.

Connect via serial console or SSH (if network is available). Default credentials are whatever you set during the build (`-u` / `-p` flags).

### Connecting to WiFi (headless builds)
```bash
nmcli device wifi connect "YOUR_NETWORK" --ask
```
