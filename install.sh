#! /bin/bash

if [ "$UID" -ne 0 ]; then 
    echo "This program needs sudo rights."
    echo "Run it with 'sudo $0'"
    exit 1
fi

apt update -y && apt install -y git bc bison flex libssl-dev make libc6-dev libncurses5-dev build-essential docker.io apparmor whiptail
systemctl start docker
systemctl enable docker
chmod +x ./*
chmod +x config/*
 
