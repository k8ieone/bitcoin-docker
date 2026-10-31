#!/bin/bash

docker buildx build . -t registry.mcld.eu/pub/bitcoind:v0.32.1 --push
