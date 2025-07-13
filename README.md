# FLAME Protocol Implementation with MPC

## Overview

This repository implements the FLAME (Federated Learning) protocol using Multi-Party Computation (MPC) for privacy preservation. The implementation is built directly inside a fork of the MP-SPDZ framework, leveraging its secure computation primitives for federated learning. All computations maintain privacy except the clustering algorithm, which uses DBSCAN instead of the original HDBSCAN for performance optimization in the MPC environment.

## Architecture

- **MP-SPDZ Integration**: Built as a direct fork of the MP-SPDZ repository for seamless MPC operations
- **MPC Implementation**: All gradient computations and aggregations are performed using secure multi-party computation to ensure privacy
- **Clustering**: DBSCAN algorithm is executed in plaintext as the bottleneck component (HDBSCAN would be computationally prohibitive in MPC)
- **Client Simulation**: Supports federated learning with multiple clients

## Repository Structure

```
├── Programs/
|   ├── Source/
|   │   └── flame.mpc        # Main FLAME protocol implementation
├── Flame/
│   └── flame-client.py      # Client implementation
├── flame_run.sh             # Automated setup script
└── README.md
```

## Quick Start

The repository includes an automated setup script that handles all dependencies and environment configuration:

```bash
./flame_run.sh
```

This script will:
- Create and activate a virtual environment and install required dependencies
- Launch the federated learning system with 4 clients

## Key Features

- **MP-SPDZ Foundation**: Built on proven secure computation framework for reliability
- **Privacy-Preserving**: MPC-based implementation ensures gradient privacy during aggregation
- **Robust Aggregation**: FLAME's clustering-based approach filters malicious clients effectively
- **Scalable Setup**: Easy deployment with automated configuration
- **Performance Optimized**: DBSCAN clustering balances security and computational efficiency

## Links

- [FLAME MPC](/Programs/Source/flame.mpc)
- [Flame Client](/Flame/flame-client.py)
- [Shell Script](/flame_run.sh)
---