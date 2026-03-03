#!/bin/bash
# migrate-to-nvme.sh — runs once on first boot to move rootfs from SD to NVMe
set -e

NVME=/dev/nvme0n1
NVME_PART=${NVME}p1
LOG=/var/log/nvme-migrate.log

exec &> >(tee -a "$LOG")
echo "$(date): NVMe migration starting"

# Wait for NVMe to appear (up to 30s)
for i in $(seq 1 30); do
    [ -b "$NVME" ] && break
    sleep 1
done

if [ ! -b "$NVME" ]; then
    echo "ERROR: $NVME not found. Staying on SD card."
    systemctl disable nvme-migrate.service
    exit 0
fi

# Partition and format
echo "Partitioning $NVME..."
parted -s "$NVME" mklabel gpt mkpart primary ext4 1MiB 100%
sleep 2
mkfs.ext4 -L nvmeroot "$NVME_PART"

# Mount and copy
echo "Copying rootfs to NVMe..."
mkdir -p /mnt/nvme
mount "$NVME_PART" /mnt/nvme
rsync -axHAWXS --info=progress2 \
    --exclude='/mnt/*' --exclude='/proc/*' --exclude='/sys/*' \
    --exclude='/dev/*' --exclude='/run/*' --exclude='/tmp/*' \
    / /mnt/nvme/
mkdir -p /mnt/nvme/{proc,sys,dev,run,tmp,mnt}
chmod 1777 /mnt/nvme/tmp

# Update fstab on NVMe copy — SD partition becomes /boot
sed -i '/LABEL=rootfs/d' /mnt/nvme/etc/fstab
cat >> /mnt/nvme/etc/fstab <<EOF
/dev/nvme0n1p1  /      ext4  defaults,noatime  0 1
/dev/mmcblk1p2  /boot  ext4  defaults          0 2
EOF

# Update kernel cmdline on NVMe copy for NVMe-optimized settings
echo "root=/dev/nvme0n1p1 console=ttyFIQ0,1500000n8 quiet splash loglevel=1 rw consoleblank=0 console=tty1 coherent_pool=2M irqchip.gicv3_pseudo_nmi=0 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1" > /mnt/nvme/etc/kernel/cmdline

# NVMe-optimized sysctl (higher dirty ratios since NVMe is fast)
cat > /mnt/nvme/etc/sysctl.d/99-rock4se.conf <<EOF
# Rock 4 SE optimizations (NVMe root)
vm.swappiness=10
vm.dirty_ratio=20
vm.dirty_background_ratio=10
vm.vfs_cache_pressure=75
EOF

# Disable this service on the NVMe copy
rm -f /mnt/nvme/etc/systemd/system/multi-user.target.wants/nvme-migrate.service

umount /mnt/nvme

# Now update the SD card's extlinux to boot from NVMe
echo "Updating extlinux to boot from NVMe..."
sed -i 's|root=LABEL=rootfs|root=/dev/nvme0n1p1|' /boot/extlinux/extlinux.conf
# Remove mq-deadline (NVMe uses 'none' by default)
sed -i 's| elevator=mq-deadline||' /boot/extlinux/extlinux.conf

# Disable this service so it doesn't run again
systemctl disable nvme-migrate.service

echo "$(date): Migration complete. Rebooting..."
sync
reboot
