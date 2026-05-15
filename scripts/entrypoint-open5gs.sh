#!/bin/bash
set -e

COMPONENT=${COMPONENT_NAME:?COMPONENT_NAME must be set}

mkdir -p /var/log/open5gs

if [ "$COMPONENT" = "webui" ]; then
    export DB_URI="${DB_URI:-mongodb://172.22.0.2/open5gs}"
    export PORT="${WEBUI_PORT:-9999}"
    cd /usr/lib/open5gs/webui
    exec node server/index.js

elif [ "$COMPONENT" = "upf" ]; then
    ip tuntap add name ogstun mode tun 2>/dev/null || true
    ip addr add 10.45.0.1/16 dev ogstun 2>/dev/null || true
    ip link set ogstun up
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
    exec /usr/bin/open5gs-upfd -c /etc/open5gs/upf.yaml

else
    exec /usr/bin/open5gs-${COMPONENT}d -c /etc/open5gs/${COMPONENT}.yaml
fi
