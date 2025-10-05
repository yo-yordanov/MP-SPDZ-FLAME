#!/usr/bin/env bash

# Configure and compile MP-SPDZ for online-only benchmarking.
make -j8 Fake-Offline.x spdz2k-party.x flame-client.x

Scripts/setup-ssl.sh 2
Scripts/setup-clients.sh 50

# Prepare offline data
./Fake-Offline.x 2 -Z 64 -S 64 -e 1,14,15,16,30,31,32,33,47,64

