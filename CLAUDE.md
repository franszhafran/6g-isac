# CLAUDE.md — ISAC 5G Testbed

## Project

End-to-end 5G SA testbed: Open5GS core + OAI RAN + OAI NR-UE, all in Docker.  
Target host: `ubuntu@rt-vm-1`.

## Repo Layout

```
docker-compose.core.yaml   Open5GS 5G SA core (12 NFs + MongoDB + WebUI)
docker-compose.ran.yaml    OAI gNB (rfsimulator, ZMQ)
docker-compose.ue.yaml     OAI NR-UE (rfsimulator, connects to gNB)
Dockerfile.open5gs         Ubuntu 22.04 + open5gs PPA; entrypoint selects NF by COMPONENT_NAME
config/open5gs/            One YAML per NF; hardcoded to 172.22.0.x IPs
config/oai-gnb/gnb.conf    gNB LIBCONFIG; band n78, 40 MHz, ARFCN 641280, AMF at 172.22.0.10
config/oai-ue/ue.uicc.conf UE SIM params (IMSI/K/OPC); credentials also in docker-compose.ue.yaml env
scripts/entrypoint-open5gs.sh  Routes COMPONENT_NAME → binary; UPF also sets up ogstun + iptables
scripts/add-subscriber.sh  POST to WebUI REST API at :9999 to register UE
.env                       PLMN + IP table + UE credentials (source of truth for docs)
Makefile                   Targets: build, core-up/down, ran-up/down, ue-up/down, up, down, add-subscriber, logs-*
```

## IP Allocation (172.22.0.0/24)

| .2 mongo | .7 smf | .8 upf | .10 amf | .11 ausf | .12 nrf |
| .13 udm | .14 udr | .23 gnb | .24 ue | .26 webui | .27 pcf |
| .28 nssf | .29 bsf | .35 scp |

## PLMN

MCC=001, MNC=01, TAC=1, SST=1, DNN=internet

## Key Design Decisions

- Single Docker image (`open5gs:local`) for all NFs; `COMPONENT_NAME` env selects which binary runs.
- UPF runs `NET_ADMIN` + `/dev/net/tun` to create `ogstun` tun interface for UE traffic (`10.45.0.0/16`).
- OAI uses `--rfsim` (ZMQ rfsimulator) — no SDR hardware needed. gNB is server, UE is client.
- NRF → SCP → all NFs chain: SCP acts as proxy, simplifies NF discovery routing.
- All Open5GS configs hardcode IPs; if IPs change, update both `config/open5gs/*.yaml` and `.env`.
- `docker-compose.ran.yaml` and `docker-compose.ue.yaml` use `isac_net` as `external: true` network (created by core compose).

## Common Operations

```bash
make build            # build open5gs:local
make core-up          # start core; wait for healthy before adding subscriber or starting RAN
make add-subscriber   # register default UE (IMSI 001010000000001)
make ran-up           # start gNB
make ue-up            # start NR-UE
make logs-amf         # watch AMF for NG setup from gNB and UE registration
make logs-upf         # watch UPF for PDU session / GTP-U tunnels
docker exec oai-nr-ue ip addr show oaitun_ue1   # verify UE got PDU session IP
```

## Startup Order

1. `mongo` must be up before `udr`, `pcf`, `bsf`, `webui`
2. `nrf` must be up before `scp`
3. `scp` must be up before all other NFs
4. Core must be healthy before starting gNB (N2 SCTP to AMF at :38412)
5. gNB must be running before starting UE (ZMQ rfsimulator at :4043)

## Adding a New UE

```bash
./scripts/add-subscriber.sh <IMSI> <KEY> <OPC>
# Then update docker-compose.ue.yaml USE_ADDITIONAL_OPTIONS with new credentials
```

## Troubleshooting

- AMF not reachable from gNB: check `amf_ip_address` in `config/oai-gnb/gnb.conf` and that AMF container is running
- UE PDU session fails: check UPF logs for PFCP session, verify `ogstun` exists with `docker exec upf ip addr`
- Image build fails: ensure Docker can reach PPA (`ppa:open5gs/latest`) — needs internet on build host
