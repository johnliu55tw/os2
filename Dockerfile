FROM registry.opensuse.org/home/jliu/sle_15_sp3/johnliu55tw/rancher-node-image/5.2:embedded-rancherd AS base

COPY files/etc/luet/luet.yaml /etc/luet/luet.yaml

# Necessary for luet to run
RUN mkdir -p /run/lock

ARG CACHEBUST
RUN luet install -y \
    toolchain/yip \
    system/cos-setup \
    system/immutable-rootfs \
    system/grub2-config \
    selinux/k3s \
    selinux/rancher \
    utils/nerdctl \
    toolchain/yq

# Create the folder for journald persistent data
RUN mkdir -p /var/log/journal

# Create necessary cloudconfig folders so that elemental cli won't show warnings during installation
RUN mkdir -p /usr/local/cloud-config
RUN mkdir -p /oem

COPY files/ /
RUN mkinitrd

COPY os-release /usr/lib/os-release

# Remove /etc/cos/config to use default values
RUN rm -f /etc/cos/config
