# ISAC — 5G SA Testbed (free5GC + OAI)

End-to-end 5G Standalone testbed. All components **built from source** in Docker.

## Architecture

```
                     ┌─────────────────────────────────────────────┐
                     │           Docker network: isac_net           │
                     │              172.22.0.0/24                   │
                     │                                              │
  ┌──────────────┐   │  ┌────────┐  ┌────────┐  ┌──────────────┐  │
  │  OAI NR-UE   │   │  │  AMF   │  │  SMF   │  │  UPF (gtp5g) │  │
  │ .24 (rfsim)  │   │  │  .10   │  │  .07   │  │     .08      │  │
  └──────┬───────┘   │  └───┬────┘  └───┬────┘  └──────┬───────┘  │
         │ ZMQ:4043  │      │N2/NGAP     │PFCP          │GTP-U     │
  ┌──────┴───────┐   │  ┌───┴──────────────────────┐    │          │
  │  OAI gNB     ├───┤  │       Control Plane       │    │          │
  │  .23 (rfsim) │   │  │  NRF·AUSF·UDM·UDR        │    │          │
  └──────────────┘   │  │  PCF·NSSF                 │    │          │
                     │  └───────────────────────────┘    │          │
                     │                                   │          │
                     │  ┌─────────┐   10.60.0.0/16 ◄────┘          │
                     │  │ MongoDB │   (UE IP pool via gtp5g)        │
                     │  │   .02   │                                 │
                     │  └─────────┘  WebConsole :5000               │
                     └─────────────────────────────────────────────┘
```

| Component      | Source / Image                    | IP           |
|----------------|-----------------------------------|--------------|
| MongoDB        | `mongo:6.0`                       | 172.22.0.2   |
| NRF            | built from `free5gc/free5gc`      | 172.22.0.12  |
| AUSF           | built from `free5gc/free5gc`      | 172.22.0.11  |
| UDM            | built from `free5gc/free5gc`      | 172.22.0.13  |
| UDR            | built from `free5gc/free5gc`      | 172.22.0.14  |
| AMF            | built from `free5gc/free5gc`      | 172.22.0.10  |
| SMF            | built from `free5gc/free5gc`      | 172.22.0.7   |
| UPF            | built from `free5gc/free5gc`      | 172.22.0.8   |
| PCF            | built from `free5gc/free5gc`      | 172.22.0.27  |
| NSSF           | built from `free5gc/free5gc`      | 172.22.0.28  |
| WebConsole     | built from `free5gc/free5gc`      | 172.22.0.26  |
| OAI gNB        | built from `openairinterface5g`   | 172.22.0.23  |
| OAI NR-UE      | built from `openairinterface5g`   | 172.22.0.24  |

**PLMN:** MCC=001, MNC=01 · **TAC:** 1 · **SST:** 1 · **SD:** 010203 · **DNN:** internet  
**Band:** n78 (3.5 GHz) · **BW:** 40 MHz · **SCS:** 30 kHz · **RF:** ZMQ rfsimulator

## Prerequisites

- Docker Engine ≥ 22 + Docker Compose v2
- Ubuntu 22.04 (target: `ubuntu@rt-vm-1`)
- Kernel headers (for gtp5g module build)
- Internet access on build host (clones OAI + free5GC repos)

## Quick Start

```bash
# 1. Install gtp5g kernel module (HOST, as root — once per boot)
make gtp5g

# 2. Build all images from source (~30-60 min first time)
make build

# 3. Start 5G core
make core-up

# 4. Register default UE subscriber
make add-subscriber

# 5. Start gNB
make ran-up

# 6. Start NR-UE
make ue-up
```

Or all in one (after gtp5g + build):
```bash
make up
```

## Default UE Credentials

| Field | Value |
|-------|-------|
| IMSI  | `001010000000001` |
| Key   | `fec86ba6eb707ed08905757b1bb44b8f` |
| OPC   | `C42449363BBAD02B66D16BC975D77CC1` |
| DNN   | `internet` |
| SST/SD | `1 / 010203` |

Change in `.env` and update `docker-compose.ue.yaml` CMD flags accordingly.

## WebConsole

free5GC subscriber management UI: `http://<host>:5000`

## Useful Commands

```bash
make status           # all container states
make logs-core        # all core NF logs
make logs-amf         # AMF (UE registration, NG setup)
make logs-upf         # UPF (PDU sessions, GTP-U)
make logs-gnb         # OAI gNB
make logs-ue          # OAI NR-UE
make add-subscriber   # add default UE
make down             # stop everything
```

## Verify UE Connectivity

```bash
# UE tunnel interface
docker exec oai-nr-ue ip addr show oaitun_ue1

# Ping from UE through UPF
docker exec oai-nr-ue ping -I oaitun_ue1 -c3 8.8.8.8
```

## Build Versions

| Component | Version |
|-----------|---------|
| free5GC   | `v3.4.3` (set `FREE5GC_VERSION` in `.env`) |
| OAI RAN   | `develop` branch (set `OAI_BRANCH` in `.env`) |
| gtp5g     | `v0.9.3` (set `GTP5G_VERSION` in env before `make gtp5g`) |

## Reference

- [free5GC](https://github.com/free5gc/free5gc)
- [free5GC compose reference](https://github.com/free5gc/free5gc-compose)
- [gtp5g kernel module](https://github.com/free5gc/gtp5g)
- [OpenAirInterface5G](https://gitlab.eurecom.fr/oai/openairinterface5g)
