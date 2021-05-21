FROM debian:stable-slim

# timezone
ENV TZ=US/Pacific
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# system dependencies
RUN apt-get update -y
RUN apt-get install -y \
    automake \
    build-essential \
    pkg-config \
    libffi-dev \
    libgmp-dev \
    libssl-dev \
    libtinfo-dev \
    libsystemd-dev \
    zlib1g-dev \
    make \
    g++ \
    tmux \
    git \
    jq \
    wget \
    libncursesw5 \
    libtool \
    autoconf


# cabal
ENV PATH="/root/.cabal/bin:/root/.ghcup/bin:/root/.local/bin:$PATH"
RUN wget https://downloads.haskell.org/~cabal/cabal-install-3.2.0.0/cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz \
    && tar -xf cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz \
    && rm cabal-install-3.2.0.0-x86_64-unknown-linux.tar.xz cabal.sig \
    && mkdir -p ~/.local/bin \
    && mv cabal ~/.local/bin/ \
    && cabal update && cabal --version

# GHC
RUN wget https://downloads.haskell.org/ghc/8.10.2/ghc-8.10.2-x86_64-deb9-linux.tar.xz \
    && tar -xf ghc-8.10.2-x86_64-deb9-linux.tar.xz \
    && rm ghc-8.10.2-x86_64-deb9-linux.tar.xz \
    && cd ghc-8.10.2 \
    && ./configure \
    && make install \
    && cd / \
    && rm -rf /ghc-8.10.2

# Libsodium
RUN git clone https://github.com/input-output-hk/libsodium && \
    cd libsodium && \
    git checkout 66f017f1 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Install cardano-node
ARG VERSION=1.26.2
RUN echo "Building tags/$VERSION..." \
    && echo tags/$VERSION > /CARDANO_BRANCH \
    && git clone https://github.com/input-output-hk/cardano-node.git \
    && cd cardano-node \
    && git fetch --all --recurse-submodules --tags \
    && git tag \
    && git checkout tags/$VERSION \
    && cabal configure --with-compiler=ghc-8.10.2 \
    && echo "package cardano-crypto-praos" >>  cabal.project.local \
    && echo "  flags: -external-libsodium-vrf" >>  cabal.project.local \
    && cabal build all \
    && mkdir -p /root/.local/bin/ \
    && cp -p dist-newstyle/build/x86_64-linux/ghc-8.10.2/cardano-node-${VERSION}/x/cardano-node/build/cardano-node/cardano-node /root/.local/bin/ \
    && cp -p dist-newstyle/build/x86_64-linux/ghc-8.10.2/cardano-cli-${VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli /root/.local/bin/ \
    && rm -rf /root/.cabal/packages \
    && rm -rf /usr/local/lib/ghc-8.6.5/ \
    && rm -rf /cardano-node/dist-newstyle/ \
    && rm -rf /root/.cabal/store/ghc-8.6.5

# Copy runner
COPY config /cardano/cardano-node
COPY runner.sh /cardano/

RUN apt-get install tcptraceroute procps curl vim lsof bc -y
RUN curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
RUN curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
RUN chmod 755 gLiveView.sh

ENV CARDANO_NODE_SOCKET_PATH /cardano/cardano-node/db/node.socket
ARG node-type

WORKDIR /generate
RUN wget https://hydra.iohk.io/build/3662127/download/1/cardano-wallet-shelley-2020.7.28-linux64.tar.gz
RUN tar -xvf cardano-wallet-shelley-2020.7.28-linux64.tar.gz && \
    rm cardano-wallet-shelley-2020.7.28-linux64.tar.gz
ENV PATH "${PATH}:/generate/cardano-wallet-shelley-2020.7.28"
COPY generateOwnerKeys.sh /generate
RUN chmod +x generateOwnerKeys.sh

CMD [ "/cardano/runner.sh", "cardano-node", "/cardano", ${node-type} ]
