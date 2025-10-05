# FLAME Protocol Implementation with MPC

## Overview

This repository implements the FLAME (Federated Learning) protocol using Multi-Party Computation (MPC) for privacy preservation. The implementation is built directly inside a fork of the [MP-SPDZ framework](https://github.com/data61/MP-SPDZ), leveraging its secure computation primitives for federated learning. There are two different approaches to implementing the FLAME protocol:
- Leaky FLAME: everything is computed privately except for the sorting and clustering algorithm, which approximates HDBSCAN using DBSCAN.
- Private FLAME: everything including sorting and clustering is computed privately.

## Repository Structure

```
├── Programs/
|   ├── Source/
|   │   └── flame_leaky.mpc     # Leaky MPC implementation
|   │   └── flame_private.mpc   # Private MPC implementation
├── Flame/
│   ├── flame-client.py         # Python client
│   ├── flame-client.cpp        # C++ client
│   ├── setup.sh                # Setup script
│   ├── behcmark.sh             # Benchmark script
│   ├── run.sh                  # Run script
│   └── logs/                   # Logs folder
└── README.md
```

## Quick Start

### [Setup script](./Flame/setup.sh)

The repository includes an automated setup script that handles all dependencies and environment configuration. The script will:
- Make the required dependencies.
- Generate the needed certificates for MPC
- Generate preprocessing materials for MPC

```bash
./Flame/setup.sh
```

---
### [Benchmark script](./Flame/benchmark.sh)

The repository includes an automated benchmark script that runs the benchmark. The script will:

1. Create/activate a virtual env at `local/env`
2. Install required Python packages (`gmpy2`, `numpy`) if missing
3. Compile the MP-SPDZ program
4. Start MPC runtime and launch client processes (logging everything to `./Flame/logs/<variant>`)
5. Clean up background jobs on error and report failures

It includes the following options

- `-b`: Target variant: private or leaky (required)
- `-c`: Number of clients (default: 10)
- `-i`: Number of inputs/model dimension (default: 1000)
- `-r`: Number of repetitions (default: 1)
- `-h`: Help
- `-t`: Timing guide

Example usage:

```bash
# bash Flame/benchmark.sh -b (private|leaky) -c [number of clients] -i [number of inputs] -r [number of repetitions]

bash Flame/benchmark.sh -b private -c 10 -i 100000 -r 5
bash Flame/benchmark.sh -b leaky -c 20 -i 500000 -r 2
bash Flame/benchmark.sh -h
bash Flame/benchmark.sh -t
```

---
### [Run script](./Flame/run.sh)

The repository includes an automated run script that acts as a wrapper to run multiple configs, predefined values are the following:
- Clients: 10, 20, 30, 40, 50
- Parameters: 100 000, 300 000, 500 000

```bash
./Flame/run.sh
```

## Key Features

- **MP-SPDZ Foundation**: Built on proven secure computation framework for reliability
- **Privacy-Preserving**: MPC-based implementation ensures gradient privacy during aggregation
- **Robust Aggregation**: FLAME's clustering-based approach filters malicious clients effectively
- **Scalable Setup**: Easy deployment with automated configuration
- **Performance Optimized**: DBSCAN clustering balances security and computational efficiency

## Links

- [FLAME MPC](/Programs/Source/flame.mpc)
- [Python Client](/Flame/flame-client.py)
- [C++ Client](/Flame/flame-client.cpp)
- [Setup Script](/Flame/setup.sh)
- [Benchmark Script](/Flame/benchmark.sh)
- [Run Script](/flame_run.sh)
---