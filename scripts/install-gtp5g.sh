#!/bin/bash
# Install gtp5g kernel module on the HOST (not inside container).
# Must run as root on the Ubuntu 22.04 host before starting the UPF container.
# Reference: https://github.com/free5gc/gtp5g

set -e

GTP5G_VERSION=${GTP5G_VERSION:-v0.8.9}

echo "[gtp5g] Installing kernel headers..."
apt-get update -qq
apt-get install -y linux-headers-$(uname -r) build-essential git

echo "[gtp5g] Cloning gtp5g ${GTP5G_VERSION}..."
TMPDIR=$(mktemp -d)
git clone --depth 1 --branch ${GTP5G_VERSION} \
    https://github.com/free5gc/gtp5g.git "${TMPDIR}/gtp5g"

echo "[gtp5g] Building..."
cd "${TMPDIR}/gtp5g"
make

echo "[gtp5g] Installing..."
make install

echo "[gtp5g] Loading module..."
modprobe gtp5g

lsmod | grep gtp5g && echo "[gtp5g] Module loaded OK." || echo "[gtp5g] WARNING: module not visible in lsmod"

rm -rf "${TMPDIR}"
