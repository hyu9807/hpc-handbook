# Ye Lab HPC Handbook

Documentation and infrastructure standards for the
Ye Lab high-performance computing environment.

## Project Goals

1. Standardize individual Linux GPU workstations.
2. Build a reproducible multi-node computing environment.
3. Deploy Slurm for CPU and GPU workload scheduling.
4. Maintain reliable remote access and engineering tools.
5. Document installation, operations, and troubleshooting.

## Infrastructure

| Node | Status |
|---|---|
| yelab-node01 | Ubuntu + CUDA + KVM operational |
| yelab-node02 | Planned |
| yelab-node03 | Planned |
| yelab-node04 | Planned |

## Documentation

- [Architecture](docs/architecture.md)
- [Node01 Configuration](docs/node01.md)
- [Architecture Decisions](docs/decisions.md)

## Principles

- Research workloads take priority over convenience workloads.
- GPU resources remain available to Linux compute jobs.
- Infrastructure should be reproducible and maintainable.
- Credentials and sensitive configuration must not be published.

## Current Phase

Node01 standardization.

Next milestone: single-node Slurm deployment.
