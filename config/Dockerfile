ARG SUITE
FROM arm64v8/debian:${SUITE}
ARG SUITE
ARG DESKTOP
ARG ADDITIONAL
ARG USERNAME
ARG PASSWORD
ARG KERNEL
ARG HEADERS
ARG NVME

ENV SUITE=$SUITE
ENV HEADERS=$HEADERS
ENV KERNEL=$KERNEL
ENV NVME=$NVME
ENV DESKTOP=$DESKTOP
ENV ADDITIONAL=$ADDITIONAL
ENV USERNAME=$USERNAME
ENV PASSWORD=$PASSWORD
ENV DEBIAN_FRONTEND=noninteractive

## ACTIVATING NON-FREE-SOURCES
RUN sed -i '/^Components:/ s/$/ contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
SHELL ["/bin/bash", "-c"]

## INSTALL ESSETNIALS AND OFTEN USED TOOLS
RUN apt update -y && apt upgrade -y && apt install -y apt-utils dialog aptitude
RUN aptitude install -y '?priority(required)' '?priority(important)' '?priority(standard)'
RUN apt install -y nano wget curl sudo gpg gpg-agent network-manager zip unzip e2fsprogs git zsh zsh-autosuggestions zsh-syntax-highlighting kmod wireless-tools net-tools iproute2 inetutils-ping inetutils-traceroute inetutils-tools initramfs-tools network-manager usbutils tar zip unzip bzip2 u-boot-menu pulseaudio pulseaudio-module-bluetooth ntpsec locales parted util-linux u-boot-tools firmware-brcm80211 iw wireless-regdb bluetooth bluez rsync nvme-cli

## INSTALLATION OF THE DEB-PACKAGES in 'apt-packages.txt'
COPY config/apt-packages.txt /root
RUN xargs apt install -y < /root/apt-packages.txt
RUN rm /root/apt-packages.txt

## Copy the autoinstaller for the Radxa Metapackage
COPY config/autoinstaller.sh /usr/local/bin
RUN chmod +x /usr/local/bin/autoinstaller.sh

## INSTALL WECHAT FOR LINUX
RUN curl -L -o /tmp/wechat.deb "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb" \
 && apt-get install -y /tmp/wechat.deb || true \
 && apt-get install -fy \
 && rm -f /tmp/wechat.deb

## INSTALL FCITX5 + GOOGLE PINYIN INPUT METHOD
RUN apt-get install -y fcitx5 fcitx5-chinese-addons fcitx5-pinyin fcitx5-config-qt fcitx5-frontend-gtk3 fcitx5-frontend-qt5 fcitx5-module-emoji im-config \
 && im-config -n fcitx5
RUN mkdir -p /etc/profile.d \
 && cat > /etc/profile.d/fcitx5.sh <<'EOF'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
EOF

## DESKTOP INSTALLATION
RUN if [[ $DESKTOP == "xfce4" ]]; then \
    apt install -y xfce4 lightdm xorg firefox-esr network-manager-gnome gvfs-backends pulseaudio pulseaudio-module-bluetooth blueman \
    ; fi
RUN if [[ $DESKTOP == "gnome" ]]; then \
    apt install -y gdm* gnome-shell \
    ; fi
RUN if [[ $DESKTOP == "mate" ]]; then \
    apt install -y mate-desktop-environment-core lightdm xorg firefox-esr \
    ; fi
RUN if [[ $DESKTOP == "cinnamon" ]]; then \
    apt install -y cinnamon-common cinnamon-desktop-environment lightdm xorg firefox-esr \
    ; fi
RUN if [[ $DESKTOP == "lxqt" ]]; then \
    apt install -y lightdm xorg lxqt-core  \
    ; fi
RUN if [[ $DESKTOP == "lxde" ]]; then \
    apt install -y lxde* lightdm xorg firefox-esr mintstick gimp transmission winff libreoffice ufw gufw synaptic gnome-software \
    ; fi
RUN if [[ $DESKTOP == "unity" ]]; then \
    wget -qO - https://hub.unity3d.com/linux/keys/public | gpg --dearmor | sudo tee /usr/share/keyrings/Unity_Technologies_ApS.gpg > /dev/null && sh -c 'echo "deb [signed-by=/usr/share/keyrings/Unity_Technologies_ApS.gpg] https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list' && apt update && apt-get install unityhub mintstick gimp transmission winff libreoffice ufw gufw synaptic gnome-software -y \
    ; fi
RUN if [[ $DESKTOP == "budgie" ]]; then \
    apt install -y budgie-desktop \
    ; fi
RUN if [[ $DESKTOP == "kde" ]]; then \
    apt install -y sddm kde-plasma-desktop xorg \
    ; fi

## ADDING RADXA REPOSITORY, INSTALL FIRMWARE AND 'rsetup'
RUN bash -c 'curl -L --output deb.deb "https://github.com/radxa-pkg/radxa-archive-keyring/releases/latest/download/radxa-archive-keyring_$(curl -L https://github.com/radxa-pkg/radxa-archive-keyring/releases/latest/download/VERSION)_all.deb"'
RUN dpkg -i deb.deb
RUN rm -f deb.deb
RUN if [ "$SUITE" = "bookworm" ]; then \
        tee /etc/apt/sources.list.d/radxa.list <<< "deb [signed-by=/usr/share/keyrings/radxa-archive-keyring.gpg] https://radxa-repo.github.io/bookworm/ bookworm main" \
     && tee /etc/apt/sources.list.d/radxa-rk3399t.list <<< "deb [signed-by=/usr/share/keyrings/radxa-archive-keyring.gpg] https://radxa-repo.github.io/rk3399t-bookworm/ rk3399t-bookworm main" \
     && apt update -y \
     && apt install -y radxa-firmware rsetup \
    ; elif [ "$KERNEL" = "radxa" ]; then \
        echo "Radxa BSP kernel is only supported with SUITE=bookworm" >&2 \
     && exit 1 \
    ; else \
        echo "Skipping bookworm-only Radxa repositories for SUITE=$SUITE" \
    ; fi

## Copy the overlay files into the boot folder
COPY config/overlays /boot

## CREATE SUDO USER
RUN useradd -m -s /bin/bash ${USERNAME}
RUN echo "${USERNAME}:${PASSWORD}" | chpasswd
RUN usermod -aG sudo ${USERNAME}

## SETTING UP ZSH
COPY config/.zshrc /home/${USERNAME}
RUN chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.zshrc
RUN cp /home/${USERNAME}/.zshrc /root
RUN chown root:root /root/.zshrc
RUN chsh -s /bin/zsh ${USERNAME}
RUN chsh -s /bin/zsh root

## ZRAM (variable names must match what /usr/sbin/zramswap expects)
RUN apt-get install -y zram-tools
RUN echo "ALGO=zstd" > /etc/default/zramswap \
 && echo "SIZE=1024" >> /etc/default/zramswap \
 && echo "PRIORITY=100" >> /etc/default/zramswap

## CONFIGURE THE KERNEL COMMANDLINE
RUN echo "root=LABEL=rootfs console=ttyFIQ0,1500000n8 quiet splash loglevel=1 rw consoleblank=0 console=tty1 coherent_pool=2M irqchip.gicv3_pseudo_nmi=0 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1 elevator=mq-deadline" > /etc/kernel/cmdline

## KERNEL INSTALLATION
RUN if [ "$KERNEL" = "radxa" ]; then \
        apt-get download linux-image-rock-4se linux-image-6.1.115-8-rk2501 radxa-overlays-dkms 2>/dev/null; \
        dpkg --force-depends --force-configure-any -i linux-image-6.1.115-8-rk2501_*.deb || true; \
        dpkg --force-depends --force-configure-any -i radxa-overlays-dkms_*.deb || true; \
        dpkg --force-depends --force-configure-any -i linux-image-rock-4se_*.deb || true; \
        rm -f *.deb \
    ; fi
RUN if [ "$KERNEL" = "radxa" ] && [ "$HEADERS" = "yes" ]; then \
        apt install -y linux-headers-rock-4se || true \
    ; fi
RUN if [ "$KERNEL" = "standard" ]; then \
        apt install -y linux-image-arm64 \
    ; fi
RUN if [ "$KERNEL" = "standard" ] && [ "$HEADERS" = "yes" ]; then \
        apt install -y linux-headers-arm64 \
    ; fi

## INSTALL AUTO RESIZE ROOT FILESYSTEM SERVICE
COPY config/rootresize.service /etc/systemd/system/
COPY config/rootresize /etc/init.d/
RUN chmod +x /etc/init.d/rootresize
RUN echo "0" > /etc/resize_status
RUN systemctl enable rootresize.service

## Inserting the rc.local boot script
COPY config/rc.local /etc
RUN chmod +x /etc/rc.local

## IF LATEST KERNEL IS CHOSEN ADDING A KERNEL UPDATER SCRIPT IN '/boot'
COPY config/kernelupdater.sh /boot
RUN chmod +x /boot/kernelupdater.sh
RUN if [[ $KERNEL != "latest" ]]; then \
    rm /boot/kernelupdater.sh \
    ; fi

## NVME ROOT MIGRATION (optional)
COPY config/migrate-to-nvme.sh /usr/local/bin/
COPY config/nvme-migrate.service /etc/systemd/system/
RUN chmod +x /usr/local/bin/migrate-to-nvme.sh
RUN if [ "$NVME" = "yes" ]; then \
        ln -sf /etc/systemd/system/nvme-migrate.service /etc/systemd/system/multi-user.target.wants/nvme-migrate.service \
    ; else \
        rm /usr/local/bin/migrate-to-nvme.sh /etc/systemd/system/nvme-migrate.service \
    ; fi

## INSTALL XRDP FOR WINDOWS REMOTE DESKTOP ACCESS
RUN apt-get install -y ssl-cert xrdp xorgxrdp \
 && adduser xrdp ssl-cert \
 && systemctl enable xrdp
RUN if [[ $DESKTOP == "xfce4" ]]; then \
        echo "xfce4-session" > /etc/skel/.xsession \
    ; fi
RUN if [[ $DESKTOP == "kde" ]]; then \
        echo "startplasma-x11" > /etc/skel/.xsession \
    ; fi
RUN if [[ $DESKTOP == "gnome" ]]; then \
        echo "gnome-session" > /etc/skel/.xsession \
    ; fi
RUN if [[ $DESKTOP == "cinnamon" ]]; then \
        echo "cinnamon-session" > /etc/skel/.xsession \
    ; fi
RUN if [[ $DESKTOP == "mate" ]]; then \
        echo "mate-session" > /etc/skel/.xsession \
    ; fi
RUN if [[ $DESKTOP == "lxqt" ]]; then \
        echo "startlxqt" > /etc/skel/.xsession \
    ; fi
RUN if [[ $DESKTOP == "lxde" ]]; then \
        echo "startlxde" > /etc/skel/.xsession \
    ; fi
RUN if [[ $DESKTOP == "budgie" ]]; then \
        echo "budgie-desktop" > /etc/skel/.xsession \
    ; fi
## POLKIT RULE TO ALLOW COLORD FOR XRDP (prevents auth dialog blocking RDP sessions)
RUN mkdir -p /etc/polkit-1/localauthority/50-local.d \
 && cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<'EOF'
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
## Also set .xsession for the created user
RUN if [ -f /etc/skel/.xsession ]; then \
        cp /etc/skel/.xsession /home/${USERNAME}/.xsession \
     && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.xsession \
    ; fi

## CLEANING APT-FILES
RUN dpkg --configure -a --force-all 2>/dev/null; apt-get -f install -y 2>/dev/null; apt autoremove -y; apt autoclean

## DISABLE DUPLICATE SYSLOG (journald handles logging)
RUN systemctl disable inetutils-syslogd 2>/dev/null; \
    systemctl mask syslog.socket 2>/dev/null; \
    true

## FIX LOCALE
RUN sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && echo 'LC_CTYPE=en_US.UTF-8' >> /etc/default/locale

## REMOVE OPENIPMI (not needed on ARM SBC, wastes 17s at boot)
RUN apt-get remove -y openipmi 2>/dev/null; true

## SYSCTL TUNINGS FOR SD/eMMC AND 4GB RAM
RUN echo '# Rock 4 SE optimizations' > /etc/sysctl.d/99-rock4se.conf \
 && echo 'vm.swappiness=10' >> /etc/sysctl.d/99-rock4se.conf \
 && echo 'vm.dirty_ratio=5' >> /etc/sysctl.d/99-rock4se.conf \
 && echo 'vm.dirty_background_ratio=2' >> /etc/sysctl.d/99-rock4se.conf \
 && echo 'vm.vfs_cache_pressure=75' >> /etc/sysctl.d/99-rock4se.conf \
 && echo 'vm.dirty_writeback_centisecs=500' >> /etc/sysctl.d/99-rock4se.conf \
 && echo 'kernel.sched_autogroup_enabled=1' >> /etc/sysctl.d/99-rock4se.conf \
 && echo 'net.core.default_qdisc=fq' >> /etc/sysctl.d/99-rock4se.conf \
 && echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.d/99-rock4se.conf

## TMPFS FOR /tmp TO REDUCE SD CARD WEAR
RUN echo 'tmpfs /tmp tmpfs defaults,nosuid,nodev,size=256M 0 0' >> /etc/fstab

## DEFAULT HOSTNAME
RUN echo 'rock4se' > /etc/hostname

## CAP JOURNALD LOG SIZE
RUN mkdir -p /etc/systemd/journald.conf.d \
 && echo '[Journal]' > /etc/systemd/journald.conf.d/size.conf \
 && echo 'SystemMaxUse=100M' >> /etc/systemd/journald.conf.d/size.conf

## NVMe READ-AHEAD (256KB for sequential throughput)
RUN echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/read_ahead_kb}="256"' \
 > /etc/udev/rules.d/60-nvme-readahead.rules

## DISABLE USB AUTOSUSPEND FOR STORAGE DEVICES (prevents disconnects)
RUN echo 'ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="08", ATTR{power/autosuspend_delay_ms}="-1"' \
 > /etc/udev/rules.d/50-usb-no-autosuspend.rules

## ALLOW SUDO USERS TO MOUNT USB DRIVES WITHOUT PASSWORD
RUN mkdir -p /etc/polkit-1/localauthority/50-local.d \
 && cat > /etc/polkit-1/localauthority/50-local.d/10-udisks2-mount.pkla <<'EOF'
[Allow users to mount USB drives without password]
Identity=unix-group:sudo
Action=org.freedesktop.udisks2.filesystem-mount;org.freedesktop.udisks2.filesystem-mount-system;org.freedesktop.udisks2.filesystem-mount-other-seat
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF

## DEFAULT CPU GOVERNOR TO SCHEDUTIL FOR big.LITTLE EFFICIENCY
RUN mkdir -p /etc/tmpfiles.d \
 && echo 'w /sys/devices/system/cpu/cpufreq/policy0/scaling_governor - - - - schedutil' > /etc/tmpfiles.d/cpu-governor.conf \
 && echo 'w /sys/devices/system/cpu/cpufreq/policy4/scaling_governor - - - - schedutil' >> /etc/tmpfiles.d/cpu-governor.conf
