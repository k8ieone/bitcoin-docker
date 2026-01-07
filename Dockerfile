FROM ubuntu:latest AS builder

RUN apt update && apt install -y build-essential cmake pkgconf python3 git libevent-dev libboost-dev libcapnp-dev capnproto libzmq3-dev systemtap-sdt-dev
RUN git clone https://github.com/bitcoin/bitcoin.git
WORKDIR /bitcoin
# TODO: verify signature
RUN git checkout v30.1
RUN cmake -B build -DENABLE_WALLET=OFF -DBUILD_GUI=OFF
WORKDIR /bitcoin/build
# TODO: Add ccache caching
RUN make -j9
WORKDIR /bitcoin
RUN cmake --install build

FROM ubuntu:latest AS runner
COPY --from=builder /usr/local/bin /usr/local/bin
RUN apt update && apt install -y libevent-dev libboost-dev libcapnp-dev capnproto libzmq3-dev systemtap-sdt-dev
ENTRYPOINT ["bitcoind"]
