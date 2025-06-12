#!/bin/bash

PLAYERS=3
./compile.py flame 2
Scripts/setup-ssl.sh 3
Scripts/setup-clients.sh 3
PLAYERS=3 Scripts/mascot.sh flame-2 &
python FlameSource/flame-client.py 0 "${PLAYERS}" 2 0 &
python FlameSource/flame-client.py 1 "${PLAYERS}" 2 0 &
python FlameSource/flame-client.py 2 "${PLAYERS}" 2 1