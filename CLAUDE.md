# CLAUDE.md — ISAC 5G Testbed

## Project

End-to-end 5G SA testbed: free5GC core + OAI RAN + OAI NR-UE, all built from source in Docker.  
Target host: `ubuntu@rt-vm-1`.

## Repo Layout

```
build/
  free5gc/Dockerfile        Multi-stage: golang:1.21 builder → Ubuntu 22.04 runtime. CGO_ENABLED=0.
  oai-gnb/Dockerfile        Single-stage Ubuntu 22.04; build_oai -I --gNB -w SIMU --noavx512 --ninja
  oai-ue/Dockerfile         Single-stage Ubuntu 22.04; build_oai -I --nrUE -w SIMU --noavx512 --ninja
config/
  free5gc/                  One YAML per NF (nrfcfg, amfcfg, smfcfg, upfcfg, etc.)
  oai-gnb/gnb.conf          Band n78, 40 MHz, ARFCN 641280, AMF 172.22.0.10, SD=0x010203
  oai-ue/ue.uicc.conf       UE SIM params (unused — credentials passed via CMD flags)
scripts/
  entrypoint-free5gc.sh     Routes COMPONENT_NAME → /free5gc/bin/<nf> -c <nf>cfg.yaml
  install-gtp5g.sh          Installs gtp5g kernel module on HOST (run as root before UPF)
  add-subscriber.sh         POST to webconsole :5000 REST API
docker-compose.core.yaml    free5GC 5G SA core (11 NFs + MongoDB + WebConsole)
docker-compose.ran.yaml     OAI gNB (build from source, external isac_net)
docker-compose.ue.yaml      OAI NR-UE (build from source, external isac_net)
.env                        Versions + PLMN + IP table + UE credentials
Makefile                    build / build-core / gtp5g / core-up / ran-up / ue-up / down / logs-*
```

## IP Allocation (172.22.0.0/24)

| .2 mongodb | .7 smf | .8 upf | .10 amf | .11 ausf | .12 nrf |
| .13 udm | .14 udr | .23 gnb | .24 ue | .26 webconsole | .27 pcf |
| .28 nssf |

## PLMN / Slice

MCC=001, MNC=01, TAC=1, **SST=1, SD=010203**, DNN=internet  
SBI port: **8000** (free5GC default)

## Key Design Decisions

- **free5GC core** instead of Open5GS; all NFs are pure-Go (CGO_ENABLED=0), compiled in golang:1.21 builder stage.
- **UPF requires gtp5g** kernel module on the HOST. Run `make gtp5g` (as root) before `make core-up`. The UPF container is privileged and uses the host-loaded module.
- **UPF UE pool**: `10.60.0.0/16` (free5GC default, different from Open5GS `10.45.0.0/16`).
- **OAI RAN built from source** in single-stage Ubuntu images. Build time ~20-30 min per image.
- **Slice SD**: both gNB conf and UE CMD flags include SD=010203 to match free5GC slice config.
- **No TLS**: all NFs use `scheme: http`; NRF has `oauth: false`. Test/research environment only.
- `docker-compose.ran.yaml` and `docker-compose.ue.yaml` use `isac_net` as `external: true`.
- UDM references TLS keys at `/free5gc/config/TLS/udm.key` — these come from the Docker build (copied from source repo), not mounted.
- `make build` builds all three images sequentially; `build-core` / `build-ran` / `build-ue` build individually.

## Startup Order

1. `make gtp5g` — install gtp5g on host kernel (once per host boot)
2. `make build` — build all images from source (takes time, cached after first run)
3. `make core-up` — start MongoDB + NRF + all NFs + WebConsole
4. `make add-subscriber` — register UE in free5GC
5. `make ran-up` — start OAI gNB (connects to AMF via N2 SCTP)
6. `make ue-up` — start OAI NR-UE (ZMQ rfsim to gNB, connects to core)

## Common Operations

```bash
make build-core         # rebuild only free5GC image
make build-ran          # rebuild only OAI gNB image
make build-ue           # rebuild only OAI NR-UE image
make core-up
make add-subscriber
make ran-up
make ue-up
make logs-amf           # watch AMF for NG setup + UE registration
make logs-upf           # watch UPF for PDU sessions / GTP-U
make logs-gnb           # OAI gNB logs
make logs-ue            # OAI NR-UE logs
docker exec oai-nr-ue ip addr show oaitun_ue1   # verify UE got IP
docker exec oai-nr-ue ping -I oaitun_ue1 -c3 8.8.8.8
```

## Adding a New UE

```bash
./scripts/add-subscriber.sh <IMSI> <KEY> <OPC>
# Then add a new UE container in docker-compose.ue.yaml with updated CMD flags
```

## Troubleshooting

- **UPF crash on start**: gtp5g module not loaded. Run `make gtp5g` on the host first, then `lsmod | grep gtp5g`.
- **AMF not reachable from gNB**: verify `amf_ip_address` in `config/oai-gnb/gnb.conf` and AMF container is up.
- **NRF registration fails**: check NF container logs, verify `nrfUri: http://172.22.0.12:8000` in each NF config.
- **PDU session fails**: check SMF logs for PFCP; check UPF logs for session establishment; verify `10.60.0.0/16` pool.
- **OAI build fails**: check `/tmp/build-gnb.log` inside the image; common issue: missing AVX support (already handled by `--noavx512`).
