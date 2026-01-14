FROM ubuntu:latest AS builder
ENV DEBIAN_FRONTEND=noninteractive
ENV CCACHE_DIR=/ccache
ENV CCACHE_COMPRESS=1
ENV CCACHE_MAXSIZE=5G
ARG builddeps="libevent-dev libboost-dev libcapnp-dev capnproto libzmq3-dev systemtap-sdt-dev"
RUN apt update && apt install -y build-essential git wget cmake pkgconf ccache $builddeps
# The Bitcoin Core signing keys
# Commit is just the latest I picked, could be any trusted commit, we just want to avoid main
RUN git clone https://github.com/bitcoin-core/guix.sigs.git && cd guix.sigs && git checkout 6490653f3135584f13db6df113318371f9876633
RUN gpg --import guix.sigs/builder-keys/*.gpg
# Let's start gathering sources
ARG version=30.2
RUN wget https://bitcoincore.org/bin/bitcoin-core-$version/bitcoin-$version.tar.gz
RUN wget https://bitcoincore.org/bin/bitcoin-core-$version/SHA256SUMS
RUN wget https://bitcoincore.org/bin/bitcoin-core-$version/SHA256SUMS.asc
# Check if the hash matches the file
RUN sha256sum --check --ignore-missing SHA256SUMS
# Check the hash signature
RUN gpg --verify SHA256SUMS.asc SHA256SUMS
# Let's go build stuff
RUN tar -xzf bitcoin-$version.tar.gz
WORKDIR /bitcoin-$version
RUN --mount=type=cache,target=/ccache cmake -B build -DENABLE_WALLET=OFF -DBUILD_GUI=OFF -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
WORKDIR /bitcoin-$version/build
RUN --mount=type=cache,target=/ccache make -j$(nproc)
RUN --mount=type=cache,target=/ccache ccache -s
WORKDIR /bitcoin-$version
RUN cmake --install build

FROM ubuntu:latest AS runner
COPY --from=builder /usr/local/bin /usr/local/bin
ARG rundeps="libevent-core-2.1-7t64 libevent-extra-2.1-7t64 libevent-pthreads-2.1-7t64"
RUN apt update && apt install -y $rundeps
ENTRYPOINT ["bitcoind"]
