#! /bin/bash

HEADERS=$1
KERNEL_VERSION=$2
CWD=$PWD
OUTDIR=${CWD}
CPUS=$(nproc)

if [ -n "$KERNEL_VERSION" ]; then
  git clone --depth=1 --branch "v${KERNEL_VERSION}" https://github.com/torvalds/linux
else
  git clone --depth=1 https://github.com/torvalds/linux
fi
cd linux

yes "" | make ARCH=arm64 defconfig

BUILD="$(sed -n 's|^.*\s\+\(\S\+\.\S\+\.\S\+\)\s\+Kernel Configuration$|\1|p' .config)"
echo "${BUILD}" > ${CWD}/config/release
KERNELDIR="KERNEL-${BUILD}"
mkdir -p "${KERNELDIR}"

# --- RK3399 SoC / Rock 4 SE hardware ---
scripts/config -e CONFIG_ARCH_ROCKCHIP
scripts/config -e CONFIG_ROCKCHIP_PM_DOMAINS
scripts/config -e CONFIG_ROCKCHIP_IOMMU
scripts/config -e CONFIG_ROCKCHIP_IODOMAIN
scripts/config -e CONFIG_ROCKCHIP_THERMAL
scripts/config -e CONFIG_ROCKCHIP_SARADC
scripts/config -e CONFIG_ROCKCHIP_TIMER

# CPU frequency scaling (big.LITTLE A72+A53)
scripts/config -e CONFIG_ARM_ROCKCHIP_CPUFREQ
scripts/config -e CONFIG_CPUFREQ_DT
scripts/config -e CONFIG_CPU_FREQ_GOV_ONDEMAND
scripts/config -e CONFIG_CPU_FREQ_GOV_SCHEDUTIL
scripts/config -e CONFIG_CPU_FREQ_GOV_CONSERVATIVE
scripts/config -e CONFIG_CPU_FREQ_DEFAULT_GOV_ONDEMAND
scripts/config -e CONFIG_ENERGY_MODEL

# GPU - Mali T860MP4
scripts/config -e CONFIG_DRM
scripts/config -e CONFIG_DRM_ROCKCHIP
scripts/config -e CONFIG_DRM_PANFROST

# Display / HDMI
scripts/config -e CONFIG_DRM_DW_HDMI
scripts/config -e CONFIG_DRM_DW_HDMI_CEC
scripts/config -e CONFIG_ROCKCHIP_VOP
scripts/config -e CONFIG_DRM_DISPLAY_CONNECTOR
scripts/config -e CONFIG_DRM_DW_MIPI_DSI

# PCIe (M.2 slot)
scripts/config -e CONFIG_PCIEPORT
scripts/config -e CONFIG_PCIE_ROCKCHIP_HOST
scripts/config -e CONFIG_PHY_ROCKCHIP_PCIE

# USB 3.0 / USB-C
scripts/config -e CONFIG_USB_DWC3
scripts/config -e CONFIG_USB_DWC3_OF_SIMPLE
scripts/config -e CONFIG_USB_XHCI_HCD
scripts/config -e CONFIG_PHY_ROCKCHIP_TYPEC
scripts/config -e CONFIG_TYPEC
scripts/config -e CONFIG_TYPEC_FUSB302

# eMMC / SD card
scripts/config -e CONFIG_MMC_DW
scripts/config -e CONFIG_MMC_DW_ROCKCHIP
scripts/config -e CONFIG_MMC_SDHCI_OF_ARASAN

# WiFi/BT (AP6256 - brcmfmac)
scripts/config -e CONFIG_BRCMFMAC
scripts/config -m CONFIG_BRCMFMAC_SDIO
scripts/config -e CONFIG_BT_HCIUART
scripts/config -e CONFIG_BT_BCM

# Ethernet (GMAC)
scripts/config -e CONFIG_STMMAC_ETH
scripts/config -e CONFIG_DWMAC_ROCKCHIP

# Audio
scripts/config -e CONFIG_SND_SOC_ROCKCHIP
scripts/config -e CONFIG_SND_SOC_ROCKCHIP_I2S
scripts/config -e CONFIG_SND_SOC_RT5651

# I2C / SPI / GPIO
scripts/config -e CONFIG_I2C_RK3X
scripts/config -e CONFIG_SPI_ROCKCHIP
scripts/config -e CONFIG_PINCTRL_ROCKCHIP
scripts/config -e CONFIG_GPIO_ROCKCHIP

# Power / PMIC (RK808)
scripts/config -e CONFIG_MFD_RK808
scripts/config -e CONFIG_REGULATOR_RK808
scripts/config -e CONFIG_RTC_DRV_RK808
scripts/config -e CONFIG_COMMON_CLK_RK808
scripts/config -e CONFIG_ROCKCHIP_EFUSE

# Watchdog / RTC
scripts/config -e CONFIG_DW_WATCHDOG
scripts/config -e CONFIG_RTC_CLASS

# ZRAM
scripts/config -e CONFIG_ZRAM
scripts/config -e CONFIG_ZSMALLOC
scripts/config -e CONFIG_CRYPTO_LZ4

# Virtio (QEMU emulation support)
scripts/config -e CONFIG_VIRTIO_PCI
scripts/config -e CONFIG_VIRTIO_MMIO
scripts/config -e CONFIG_VIRTIO_NET
scripts/config -e CONFIG_VIRTIO_CONSOLE
scripts/config -e CONFIG_VIRTIO_INPUT
scripts/config -e CONFIG_DRM_VIRTIO_GPU
scripts/config -e CONFIG_HW_RANDOM_VIRTIO
scripts/config -e CONFIG_MAILBOX

yes "" | make -j ${CPUS} ARCH=arm64 KERNELRELEASE="${BUILD}" Image.gz modules dtbs


env PATH=$PATH make KERNELRELEASE="${BUILD}" ARCH=arm64 INSTALL_MOD_PATH=${KERNELDIR} modules_install

mkdir -p "${KERNELDIR}/boot/" "${KERNELDIR}/lib/linux-image-${BUILD}/"rockchip/
echo "ffffffffffffffff B The real System.map is in the linux-image-<version>-dbg package" > "${KERNELDIR}/boot/System.map-${BUILD}"
cp .config "${KERNELDIR}/boot/config-${BUILD}"
cp arch/arm64/boot/Image.gz "${KERNELDIR}/boot/vmlinuz-${BUILD}"
cp -r arch/arm64/boot/dts/rockchip/*.dtb "${KERNELDIR}/lib/linux-image-${BUILD}/"rockchip/
ARCHIVE="kernel-$(sed -n 's|^.*\s\+\(\S\+\.\S\+\.\S\+\)\s\+Kernel Configuration$|\1|p' .config)$(sed -n 's|^CONFIG_LOCALVERSION=\"\(.*\)\"$|\1|p' .config).zip"
cd "${KERNELDIR}"
find lib -type l -exec rm {} \;
zip -q -r "${ARCHIVE}" *
if [ "${OUTDIR}" != "" ]; then
  if [ "${OUTDIR: -1}" != "/" ]; then
      OUTDIR+="/"
  fi
else
  if [ "${REALUSER}" = "root" ]; then
      OUTDIR="/root/"
  else
      OUTDIR="/home/${REALUSER}/"
  fi
fi
chown "${REALUSER}:${REALUSER}" "${ARCHIVE}"
cd ${CWD}/linux
mv "${KERNELDIR}/${ARCHIVE}" "${OUTDIR}"
rm -rf "${KERNELDIR}"
cd ${CWD}
rm -rf linux

echo "1" > ${CWD}/config/kernel_status
