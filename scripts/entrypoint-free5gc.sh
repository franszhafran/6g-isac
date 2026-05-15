#!/bin/bash
set -e

COMPONENT=${COMPONENT_NAME:?COMPONENT_NAME must be set}
CFG_DIR=${CONFIG_DIR:-/free5gc/config}

mkdir -p /var/log/free5gc

case "$COMPONENT" in
  webconsole)
    cd /free5gc/webconsole
    exec ./bin/webconsole -c ${CFG_DIR}/webuicfg.yaml
    ;;
  upf)
    sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
    exec /free5gc/bin/upf -c ${CFG_DIR}/upfcfg.yaml
    ;;
  *)
    exec /free5gc/bin/${COMPONENT} -c ${CFG_DIR}/${COMPONENT}cfg.yaml
    ;;
esac
