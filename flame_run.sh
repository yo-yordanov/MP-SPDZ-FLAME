#!/bin/bash
set -Eeuo pipefail

ENV_PATH="local/env"

# Check if the environment exists and make one if it doesn't
if [ -d "$ENV_PATH" ]; then
    echo "==> Virtual environment already exists. Activating..."
    source "$ENV_PATH/bin/activate"
else
    echo "==> Virtual environment not found. Creating one..."

    python3 -m venv "$ENV_PATH"
    source "$ENV_PATH/bin/activate"

    pip install --upgrade pip

    echo "==> Environment created and activated."
fi

# Check if required packages are installed
REQUIRED_PACKAGES=("gmpy2" "numpy")
for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! python -c "import $package" &> /dev/null; then
        echo "==> Package '$package' is not installed. Installing..."
        pip install "$package"
        echo "==> Package '$package' installed."
    else
        echo "==> Package '$package' is already installed."
    fi
done

# Check for correct number of arguments
if [ $# -lt 3 ]; then
  echo "==> Usage: $0 <leaky|private> <model_size> <clients>"
  exit 1
fi

variant=$1
model_size=$2
clients=$3
parties=2
base_prog="flame"

# Validate arguments
case "$variant" in
  leaky|private) ;;
  *) echo "==> Error: first argument must be 'leaky' or 'private'."; exit 1 ;;
esac

if ! [[ "$model_size" =~ ^[1-9][0-9]*$ ]]; then
  echo "==> Error: model_size must be an integer > 0"; exit 1
fi

if ! [[ "$clients" =~ ^[1-9][0-9]*$ ]]; then
  echo "==> Error: clients must be an integer > 0"; exit 1
fi
program="${base_prog}-${variant}-${model_size}-${clients}"

# Set up cleanup function to kill background jobs on error or exit
pids=()
cleanup() {
  local code=$?
  if [ $code -ne 0 ]; then
    echo "==> Error encountered (exit code $code). Killing background jobs..."
    for pid in "${pids[@]:-}"; do
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
      fi
    done
  fi
  exit $code
}
trap cleanup EXIT INT TERM

# Compile the program
echo "==> Compiling ($base_prog) with variant=$variant model_size=$model_size clients=$clients (R=64)"
./compile.py -R 64 "$base_prog" "$variant" "$model_size" "$clients"

echo "==> Compilation succeeded: program name will be: $program"

# Launch the MPC core
echo "==> Launching MPC core"
( PLAYERS="$parties" Scripts/spdz2k.sh "$program" ) &
mpc_pid=$!
pids+=("$mpc_pid")
echo "==> MPC PID: $mpc_pid"

# Wait a moment and check if the MPC core is still running
sleep 2
if ! kill -0 "$mpc_pid" 2>/dev/null; then
  echo "==> MPC process terminated early"
  wait "$mpc_pid" || true
  exit 1
fi
echo "==> MPC core seems alive; launching clients..."

# Launch the clients
for ((i=0; i<clients; i++)); do
  last=$(( i == clients - 1 ? 1 : 0 ))
  python Flame/flame-client.py "$i" "$parties" "$model_size" "$last" &
  pids+=("$!")
done

# Wait for all processes to finish
echo "==> Waiting for all processes..."
fail=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    echo "==> Process PID $pid failed."
    fail=1
  fi
done

if [ $fail -ne 0 ]; then
  echo "==> One or more processes failed."
  exit 1
fi

echo "==> All done successfully."