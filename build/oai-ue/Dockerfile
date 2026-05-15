FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && apt-get install -y git ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ARG OAI_BRANCH=develop
WORKDIR /oai-ran

RUN git clone --depth 1 --branch ${OAI_BRANCH} \
    https://gitlab.eurecom.fr/oai/openairinterface5g.git .

WORKDIR /oai-ran/cmake_targets

# -I  installs all build dependencies
# --nrUE  build NR-UE
# -w SIMU  rfsimulator (ZMQ, no SDR hardware)
# --noavx512  portable binary for VMs without AVX-512
# --ninja  faster build via Ninja
RUN ./build_oai -I --nrUE -w SIMU --noavx512 --ninja 2>&1 | tee /tmp/build-ue.log

WORKDIR /opt/oai-ue

ENTRYPOINT ["/oai-ran/cmake_targets/ran_build/build/nr-uesoftmodem"]
CMD ["--sa", "--rfsim", \
     "-r", "106", "--numerology", "1", "--band", "78", \
     "-C", "3619200000", \
     "--rfsimulator.serveraddr", "172.22.0.23"]
