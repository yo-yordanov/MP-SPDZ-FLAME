#!/bin/bash

ENV_PATH="local/env"

# Check if the environment exists and make one if it doesn't
if [ -d "$ENV_PATH" ]; then
    echo "✅ Virtual environment already exists. Activating..."
    source "$ENV_PATH/bin/activate"
else
    echo "🚧 Virtual environment not found. Creating one..."

    python3 -m venv "$ENV_PATH"
    source "$ENV_PATH/bin/activate"

    pip install --upgrade pip

    echo "✅ Environment created and gmpy2 installed."
fi

# Check if required packages are installed
REQUIRED_PACKAGES=("gmpy2" "numpy")
for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! python -c "import $package" &> /dev/null; then
        echo "🚧 Package '$package' is not installed. Installing..."
        pip install "$package"
        echo "✅ Package '$package' installed."
    else
        echo "✅ Package '$package' is already installed."
    fi
done


./compile.py flame
if [ $? -eq 0 ]; then
    echo "✅ Compilation succeeded"
    Scripts/setup-ssl.sh 2
    Scripts/setup-clients.sh 3
    PLAYERS=2 Scripts/mascot.sh flame &
    python Flame/flame-client.py 0 2 5 0 &
    python Flame/flame-client.py 1 2 5 0 &
    python Flame/flame-client.py 2 2 5 1
else
    echo "❌ Compilation failed"
fi