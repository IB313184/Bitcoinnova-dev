FROM ubuntu:18.04 as builder

# Allows us to auto-discover the latest release from the repo
ARG REPO=IB313184/Bitcoinnova-dev
ENV REPO=${REPO}

# BUILD_DATE and VCS_REF are immaterial, since this is a 2-stage build, but our build
# hook won't work unless we specify the args
ARG BUILD_DATE
ARG VCS_REF

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      curl \
      python-dev \
      gcc-8 \
      g++-8 \
      git \
      cmake \
      libboost-all-dev

RUN git clone --single-branch --branch master https://github.com/$REPO /opt/bitcoinnova && \
    cd /opt/bitcoinnova && \
    mkdir build && \
    cd build && \
    export CXXFLAGS="-w -std=gnu++11" && \
    cmake .. && \
    make -j$(nproc)

RUN mkdir -p /usr/local/bin
WORKDIR /usr/local/bin
COPY --from=builder /opt/bitcoinnova/build/src/Bitcoinnovad .
COPY --from=builder /opt/bitcoinnova/build/src/Bitcoinnova-service .
COPY --from=builder /opt/bitcoinnova/build/src/zedwallet .
COPY --from=builder /opt/bitcoinnova/build/src/miner .
COPY --from=builder /opt/bitcoinnova/build/src/wallet-api .
COPY --from=builder /opt/bitcoinnova/build/src/cryptotest .
COPY --from=builder /opt/bitcoinnova/build/src/zedwallet-beta .
RUN mkdir -p /var/lib/bitcoinnovad
WORKDIR /var/lib/bitcoinnovad
ADD https://github.com/bitcoinnova/checkpoints/raw/master/checkpoints.csv /var/lib/bitcoinnovad
ENTRYPOINT ["/usr/local/bin/Bitcoinnovad"]
CMD ["--no-console","--data-dir","/var/lib/Bitcoinnovad","--rpc-bind-ip","0.0.0.0","--rpc-bind-port","45223","--p2p-bind-port","45222","--enable-cors=*","--enable-blockexplorer","--load-checkpoints","/var/lib/bitcoinnovad/checkpoints.csv"]