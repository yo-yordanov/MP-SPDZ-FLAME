#!/bin/bash

ENV_PATH="local/flame_env"

# Check if the environment exists and make one if it doesn't
if [ -d "$ENV_PATH" ]; then
    echo "✅ Virtual environment already exists. Activating..."
    source "$ENV_PATH/bin/activate"
else
    echo "🚧 Virtual environment not found. Creating one..."

    python3 -m venv "$ENV_PATH"
    source "$ENV_PATH/bin/activate"

    pip install --upgrade pip
    pip install gmpy2

    echo "✅ Environment created and gmpy2 installed."
fi


./compile.py flame 1
if [ $? -eq 0 ]; then
    echo "✅ Compilation succeeded"
    Scripts/setup-ssl.sh 2
    Scripts/setup-clients.sh 3
    PLAYERS=2 Scripts/mascot.sh flame-1 &
    python Flame/flame-client.py 0 2 5 0 &
    python Flame/flame-client.py 1 2 5 0 &
    python Flame/flame-client.py 2 2 5 1
else
    echo "❌ Compilation failed"
fi