# Stage 1: Build free5GC from source
FROM golang:1.21-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV CGO_ENABLED=0
ENV GOFLAGS="-mod=mod"

ARG FREE5GC_VERSION=v3.4.3

RUN apt-get update && apt-get install -y \
    git make curl ca-certificates sudo \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && corepack enable \
    && apt-get clean

WORKDIR /free5gc
RUN git clone --recurse-submodules --depth 1 --branch ${FREE5GC_VERSION} \
    https://github.com/free5gc/free5gc.git .

# Build all core NFs (no webconsole — avoids yarn requirement)
RUN make amf ausf chf nrf nssf pcf smf udm udr upf

# Build webconsole; Makefile uses "sudo corepack enable" then yarn
RUN make webconsole

# Stage 2: Minimal runtime
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    iproute2 iptables ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=builder /free5gc/bin    /free5gc/bin
COPY --from=builder /free5gc/config /free5gc/config

COPY scripts/entrypoint-free5gc.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /free5gc
ENTRYPOINT ["/entrypoint.sh"]
