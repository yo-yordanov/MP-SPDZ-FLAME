#!/usr/bin/env bash

cleanup() {
    echo -e "\n==> Caught interrupt signal. Cleaning up..."
    
    pkill -f "spdz2k-party.x"
    pkill -f "flame-client.x"
    
    echo "==> Cleanup complete. Exiting."
    exit 1
}

trap cleanup SIGINT SIGTERM

setup_environment() {
    ENV_PATH="./venv"
    REQUIRED_PACKAGES=("gmpy2" "numpy")

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

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! python -c "import $package" &> /dev/null; then
            echo "==> Package '$package' is not installed. Installing..."
            pip install "$package"
            echo "==> Package '$package' installed."
        else
            echo "==> Package '$package' is already installed."
        fi
    done
}

function flame_private {
    NUM_CLIENTS=$1
    NUM_INPUTS=$2
    NUM_REP=$3
    LOG_DIR="$LOG"/flame_private/
    LOG_DIR_CLIENT="$LOG_DIR"/clients/
    LOG_DIR_PARTIES="$LOG_DIR"/parties/
    LOG_DIR_COMPILE="$LOG_DIR"/compile/
    mkdir -p $LOG_DIR_CLIENT $LOG_DIR_PARTIES $LOG_DIR_COMPILE

    >"$LOG_DIR_COMPILE"/compile_"$NUM_CLIENTS"_"$NUM_INPUTS".log
    >"$LOG_DIR_PARTIES"/parties_"$NUM_CLIENTS"_"$NUM_INPUTS".log
    for i in $(seq 0 $((NUM_CLIENTS - 1))); do
        >"$LOG_DIR_CLIENT"/client_"$NUM_CLIENTS"_"$NUM_INPUTS"_"$i".log
    done

    echo "==> Compiling private FLAME for $NUM_CLIENTS clients and $NUM_INPUTS inputs."
    ./compile.py -Y -O -I -l -R 64 flame_private $NUM_CLIENTS $NUM_INPUTS >> "$LOG_DIR_COMPILE"/compile_"$NUM_CLIENTS"_"$NUM_INPUTS".log 2>&1
    echo "==> Compilation finished."

    for i in $(seq 1 $NUM_REP); do
        echo "==> Starting repetition $i/$NUM_REP for $NUM_CLIENTS clients and $NUM_INPUTS inputs."

        PLAYERS=2 Scripts/spdz2k.sh flame_private-$NUM_CLIENTS-$NUM_INPUTS -F --batch-size 500 >> "$LOG_DIR_PARTIES"/parties_"$NUM_CLIENTS"_"$NUM_INPUTS".log 2>&1 &
        SPDZ_PID=$!

        for j in $(seq 0 $((NUM_CLIENTS - 2))); do
            ./flame-client.x "$j" "$NUM_CLIENTS" "$NUM_INPUTS" >> "$LOG_DIR_CLIENT"/client_"$NUM_CLIENTS"_"$NUM_INPUTS"_"$j".log 2>&1 &
        done
        ./flame-client.x $((NUM_CLIENTS - 1)) "$NUM_CLIENTS" "$NUM_INPUTS" >> "$LOG_DIR_CLIENT"/client_"$NUM_CLIENTS"_"$NUM_INPUTS"_$(($NUM_CLIENTS - 1)).log 2>&1

        wait
        echo "==> Completed repetition $i/$NUM_REP for $NUM_CLIENTS clients and $NUM_INPUTS inputs."
    done
}

function flame_leaky {
    NUM_CLIENTS=$1
    NUM_INPUTS=$2
    NUM_REP=$3
    LOG_DIR="$LOG"/flame_leaky/
    LOG_DIR_CLIENT="$LOG_DIR"/clients/
    LOG_DIR_PARTIES="$LOG_DIR"/parties/
    LOG_DIR_COMPILE="$LOG_DIR"/compile/
    mkdir -p $LOG_DIR_CLIENT $LOG_DIR_PARTIES $LOG_DIR_COMPILE

    >"$LOG_DIR_COMPILE"/compile_"$NUM_CLIENTS"_"$NUM_INPUTS".log
    >"$LOG_DIR_PARTIES"/parties_"$NUM_CLIENTS"_"$NUM_INPUTS".log
    for i in $(seq 0 $((NUM_CLIENTS - 1))); do
        >"$LOG_DIR_CLIENT"/client_"$NUM_CLIENTS"_"$NUM_INPUTS"_"$i".log
    done

    echo "==> Compiling leaky FLAME for $NUM_CLIENTS clients and $NUM_INPUTS inputs."
    ./compile.py -Y -O -I -l -R 64 flame_leaky $NUM_CLIENTS $NUM_INPUTS >> "$LOG_DIR_COMPILE"/compile_"$NUM_CLIENTS"_"$NUM_INPUTS".log 2>&1
    echo "==> Compilation finished."

    for i in $(seq 1 $NUM_REP); do
        echo "==> Starting repetition $i/$NUM_REP for $NUM_CLIENTS clients and $NUM_INPUTS inputs."

        PLAYERS=2 Scripts/spdz2k.sh flame_leaky-$NUM_CLIENTS-$NUM_INPUTS -F --batch-size 500 >> "$LOG_DIR_PARTIES"/parties_"$NUM_CLIENTS"_"$NUM_INPUTS".log 2>&1 &
        SPDZ_PID=$!

        for j in $(seq 0 $((NUM_CLIENTS - 2))); do
            ./flame-client.x "$j" "$NUM_CLIENTS" "$NUM_INPUTS" >> "$LOG_DIR_CLIENT"/client_"$NUM_CLIENTS"_"$NUM_INPUTS"_"$j".log 2>&1 &
        done
        ./flame-client.x $((NUM_CLIENTS - 1)) "$NUM_CLIENTS" "$NUM_INPUTS" >> "$LOG_DIR_CLIENT"/client_"$NUM_CLIENTS"_"$NUM_INPUTS"_$(($NUM_CLIENTS - 1)).log 2>&1

        wait
        echo "==> Completed repetition $i/$NUM_REP for $NUM_CLIENTS clients and $NUM_INPUTS inputs."
    done
}

function help {
    cat << EOF
Usage:
    bash Flame/benchmark.sh -b (private|leaky) -c [number of clients] -i [number of inputs] -r [number of repetitions]
    bash Flame/benchmark.sh -h
    bash Flame/benchmark.sh -t
Options:
    -b <target>         Specify the target to benchmark (private or leaky) (required)
    -c <clients>        Number of clients (default: 10)
    -i <inputs>         Number of inputs (default: 1000)
    -r <repetitions>    Number of repetitions (default: 1)
    -h                  Display this help message
    -t                  Print timing guide
EOF
}

timing_guide() {
    cat << 'EOF'
MP-SPDZ FLAME Benchmark Timing Guide
====================================
Time0: Client connections and input vector reception
Time1: Total secure computation time (Time2-8 combined)
Time2: L2 norm computation
Time3: Pairwise cosine distance matrix computation
Time4: DBSCAN clustering
Time5: Median computation
Time6: Gradient clipping
Time7: Secure aggregation of honest client updates
Time8: Differential privacy noising
Time9: Client connection cleanup

EOF
}

LOG="Flame/logs/"
target=""
clients=10
inputs=1000
repetitions=1

while getopts "b:c:i:m:r:ht" option; do
    case $option in
    b) # benchmarking
        target=$OPTARG
        ;;
    c) # number of clients
        clients=$OPTARG
        ;;
    i) # number of inputs
        inputs=$OPTARG
        ;;
    r) # repetition
        repetitions=$OPTARG
        ;;
    h) # display help
        help
        exit
        ;;
    t) # print timing guide
        timing_guide
        exit
        ;;
    \?) # Invalid option
        echo "Error: Invalid option. Use -h for help."
        exit
        ;;
    esac
done

setup_environment

case "$target" in
private)
    flame_private $clients $inputs $repetitions
    ;;
leaky)
    flame_leaky $clients $inputs $repetitions
    ;;
*) # Invalid target
    echo "Error: Unknown target '$target'. Use -h for help."
    exit
    ;;
esac