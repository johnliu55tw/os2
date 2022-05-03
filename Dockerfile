FROM quay.io/costoolkit/releases-green:luet-toolchain-0.21.2 AS luet

FROM registry.suse.de/suse/containers/suse-microos/5.2/containers/suse/sle-micro-rancher/5.2:latest AS base

# Copy luet from the official images
COPY --from=luet /usr/bin/luet /usr/bin/luet

ARG ARCH=amd64
ENV ARCH=${ARCH}
RUN zypper ar --priority=200 http://download.opensuse.org/distribution/leap/15.3/repo/oss repo-oss
RUN zypper --no-gpg-checks ref
RUN zypper update -y
COPY files/etc/luet/luet.yaml /etc/luet/luet.yaml

FROM base as tools
ENV LUET_NOLOCK=true
COPY tools /
RUN luet install -y toolchain/luet-makeiso

FROM base
ARG RANCHERD_VERSION=v0.0.1-alpha07
# Some packages are already included in sle-micro-rancher image.
RUN zypper in -y \
    apparmor-parser \
    docker \
    # iotop \ TODO: Can't install
    ipmitool \
    kdump \
    kernel-firmware-amdgpu \
    kernel-firmware-nvidia \
    kernel-firmware-radeon \
    nano \
    nfs-utils \
    nginx \
    numactl \
    rng-tools \
    supportutils \
    tcpdump \
    traceroute \
    ucode-amd \
    ucode-intel \
    xorriso

RUN zypper clean

# Necessary for luet to run
RUN mkdir -p /run/lock

ARG CACHEBUST
RUN luet install -y \
    toolchain/yip \
    toolchain/luet \
    toolchain/elemental-cli \
    system/cos-setup \
    system/immutable-rootfs \
    system/grub2-config \
    selinux/k3s \
    selinux/rancher \
    utils/k9s \
    utils/nerdctl \
    toolchain/yq

# Download rancherd binary to pin the version
RUN curl -o /usr/bin/rancherd -sfL "https://github.com/rancher/rancherd/releases/download/${RANCHERD_VERSION}/rancherd-amd64" && chmod 0755 /usr/bin/rancherd

# Create the folder for journald persistent data
RUN mkdir -p /var/log/journal

# Create necessary cloudconfig folders so that elemental cli won't show warnings during installation
RUN mkdir -p /usr/local/cloud-config
RUN mkdir -p /oem

COPY files/ /
RUN mkinitrd

COPY os-release /usr/lib/os-release
