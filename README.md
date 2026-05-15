# ISAC — 5G SA Testbed (Open5GS + OAI)

End-to-end 5G Standalone testbed. All components run in Docker.

## Architecture

```
                     ┌─────────────────────────────────────────┐
                     │          Docker network: isac_net        │
                     │             172.22.0.0/24                │
                     │                                          │
  ┌──────────────┐   │  ┌────────┐  ┌────────┐  ┌──────────┐  │
  │  OAI NR-UE   │   │  │  AMF   │  │  SMF   │  │   UPF    │  │
  │ .24 (rfsim)  │   │  │  .10   │  │  .07   │  │  .08     │  │
  └──────┬───────┘   │  └───┬────┘  └───┬────┘  └────┬─────┘  │
         │ ZMQ       │      │N2/NGAP     │PFCP        │GTP-U   │
  ┌──────┴───────┐   │  ┌───┴────────────────────┐    │        │
  │  OAI gNB     ├───┤  │     Control Plane       │    │        │
  │  .23 (rfsim) │   │  │  NRF·SCP·AUSF·UDM·UDR  │    │        │
  └──────────────┘   │  │  PCF·BSF·NSSF           │    │        │
                     │  └────────────────────────┘    │        │
                     │                                │        │
                     │  ┌────────┐      ogstun ◄──────┘        │
                     │  │ MongoDB│      10.45.0.0/16            │
                     │  │  .02   │                              │
                     │  └────────┘  WebUI :9999                 │
                     └─────────────────────────────────────────┘
```

| Component       | Image                               | IP           |
|----------------|-------------------------------------|--------------|
| MongoDB         | `mongo:6.0`                         | 172.22.0.2   |
| NRF             | `open5gs:local`                     | 172.22.0.12  |
| SCP             | `open5gs:local`                     | 172.22.0.35  |
| AUSF            | `open5gs:local`                     | 172.22.0.11  |
| UDM             | `open5gs:local`                     | 172.22.0.13  |
| UDR             | `open5gs:local`                     | 172.22.0.14  |
| AMF             | `open5gs:local`                     | 172.22.0.10  |
| SMF             | `open5gs:local`                     | 172.22.0.7   |
| UPF             | `open5gs:local`                     | 172.22.0.8   |
| PCF             | `open5gs:local`                     | 172.22.0.27  |
| BSF             | `open5gs:local`                     | 172.22.0.29  |
| NSSF            | `open5gs:local`                     | 172.22.0.28  |
| WebUI           | `open5gs:local`                     | 172.22.0.26  |
| OAI gNB         | `oaisoftwarealliance/oai-gnb`       | 172.22.0.23  |
| OAI NR-UE       | `oaisoftwarealliance/oai-nr-ue`     | 172.22.0.24  |

**PLMN:** MCC=001, MNC=01 · **TAC:** 1 · **SST:** 1 · **DNN:** internet  
**Band:** n78 (3.5 GHz) · **BW:** 40 MHz · **SCS:** 30 kHz · **RF:** ZMQ rfsimulator

## Prerequisites

- Docker Engine ≥ 22 + Docker Compose v2
- Ubuntu 22.04 (target: `ubuntu@rt-vm-1`)
- Kernel with `/dev/net/tun` (for UPF)

## Quick Start

```bash
# 1. Build Open5GS image
make build

# 2. Start 5G core
make core-up

# 3. Add default UE subscriber (IMSI 001010000000001)
make add-subscriber

# 4. Start gNB (RF simulator)
make ran-up

# 5. Start NR-UE (RF simulator, connects to gNB)
make ue-up
```

Or bring everything up in sequence:
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
| SST   | `1` |

Edit in `.env` and `config/oai-ue/ue.uicc.conf` before starting.

## WebUI

Open5GS subscriber management: `http://<host>:9999`

## Useful Commands

```bash
make status          # all container states
make logs-core       # tail all core NF logs
make logs-amf        # AMF only
make logs-gnb        # OAI gNB
make logs-ue         # OAI NR-UE
make add-subscriber  # add default UE
make down            # stop everything
```

## Verify UE Connectivity

```bash
# Check UE got a PDU session IP
docker exec oai-nr-ue ip addr show oaitun_ue1

# Ping from UE to internet via UPF tun
docker exec oai-nr-ue ping -I oaitun_ue1 -c3 8.8.8.8
```

## Reference

- [docker_open5gs](https://github.com/herlesupreeth/docker_open5gs)
- [Open5GS docs](https://open5gs.org/open5gs/docs/)
- [OAI RAN](https://gitlab.eurecom.fr/oai/openairinterface5g)
