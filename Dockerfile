# daemon runs in the background
# run something like tail /var/log/bitcoinnovad/current to see the status
# be sure to run with volumes, ie:
# docker run -v $(pwd)/bitcoinnovad:/var/lib/bitcoinnovad -v $(pwd)/wallet:/home/bitcoinnova --rm -ti bitcoinnova:0.2.2
#
# Copyright (c) 2018, The Bitcoin Nova Developers 
#
FROM ubuntu:18.04 AS base

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.2/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ADD https://github.com/just-containers/socklog-overlay/releases/download/v2.1.0-0/socklog-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/socklog-overlay-amd64.tar.gz -C /

ARG BITCOINNOVA_BRANCH=master
ENV BITCOINNOVA_BRANCH=${BITCOINNOVA_BRANCH}

# install build dependencies
# checkout the latest tag
# build and install

RUN sudo apt update && \
    apt -y install \
    software-properties-common \
    dirmngr \
    apt-transport-https \
    lsb-release 
    ca-certificates && \
    add-apt-repository "deb https://apt.llvm.org/bionic/ llvm-toolchain-bionic 6.0 main" && \
    apt-get update && \
    apt-get install aptitude -y && \
    aptitude install -y \
      -o Aptitude::ProblemResolver::SolutionCost='100*canceled-actions,200*removals' \
      build-essential \
      clang-6.0 \
      libstdc++-7-dev \
      git \
      python-pip \
      libboost-all-dev && \
    pip install cmake && \
    export CC=clang-6.0 && \
    export CXX=clang++-6.0 && \
    git clone -b master --single-branch https://github.com/IB313184/Bitcoinnova-dev.git  /bitcoinnova && \
    cd bitcoinnova && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    mkdir -p /usr/local/bin && \
    cp src/Bitcoinnovad /usr/local/bin/Bitcoinnovad && \
    cp src/walletd /usr/local/bin/walletd && \
    cp src/zedwallet /usr/local/bin/zedwallet && \
    cp src/miner /usr/local/bin/miner && \
    strip /usr/local/bin/Bitcoinnovad && \
    strip /usr/local/bin/walletd && \
    strip /usr/local/bin/zedwallet && \
    strip /usr/local/bin/miner && \
    cd / && \
    rm -rf /src/bitcoinnova && \
    apt-get remove -y build-essential python-dev gcc-7 g++-7 git cmake libboost-all-dev && \
    apt-get autoremove -y  
#   apt-get install -y  \
#      libboost-system1.65.1 \
#      libboost-filesystem1.65.1 \
#      libboost-thread1.65.1 \
#      libboost-date-time1.65.1 \
#      libboost-chrono1.65.1 \
#      libboost-regex1.65.1 \
#      libboost-serialization1.65.1 \
#      libboost-program-options1.65.1 \
#      libicu55

# setup the bitcoinnovad service
RUN useradd -r -s /usr/sbin/nologin -m -d /var/lib/bitcoinnovad bitcoinnovad && \
    useradd -s /bin/bash -m -d /home/bitcoinnova bitcoinnova && \
    mkdir -p /etc/services.d/bitcoinnovad/log && \
    mkdir -p /var/log/bitcoinnovad && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/bitcoinnovad/run && \
    echo "fdmove -c 2 1" >> /etc/services.d/bitcoinnovad/run && \
    echo "cd /var/lib/bitcoinnovad" >> /etc/services.d/bitcoinnovad/run && \
    echo "export HOME /var/lib/bitcoinnovad" >> /etc/services.d/bitcoinnovad/run && \
    echo "s6-setuidgid bitcoinnovad /usr/local/bin/Bitcoinnovad" >> /etc/services.d/bitcoinnovad/run && \
    chmod +x /etc/services.d/bitcoinnovad/run && \
    chown nobody:nogroup /var/log/bitcoinnovad && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/bitcoinnovad/log/run && \
    echo "s6-setuidgid nobody" >> /etc/services.d/bitcoinnovad/log/run && \
    echo "s6-log -bp -- n20 s1000000 /var/log/bitcoinnovad" >> /etc/services.d/bitcoinnovad/log/run && \
    chmod +x /etc/services.d/bitcoinnovad/log/run && \
    echo "/var/lib/bitcoinnovad true bitcoinnovad 0644 0755" > /etc/fix-attrs.d/bitcoinnovad-home && \
    echo "/home/bitcoinnova true bitcoinnova 0644 0755" > /etc/fix-attrs.d/bitcoinnova-home && \
    echo "/var/log/bitcoinnovad true nobody 0644 0755" > /etc/fix-attrs.d/bitcoinnovad-logs

VOLUME ["/var/lib/bitcoinnovad", "/home/bitcoinnova","/var/log/bitcoinnovad"]

ENTRYPOINT ["/init"]
CMD ["/usr/bin/execlineb", "-P", "-c", "emptyenv cd /home/bitcoinnova export HOME /home/bitcoinnova s6-setuidgid bitcoinnova /bin/bash"]
