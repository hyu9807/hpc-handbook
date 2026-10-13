# Ye Lab HPC Handbook

Infrastructure documentation, operational procedures, and
reproducible deployment standards for the Ye Lab high-performance
computing environment.

## Mission

Build and maintain a reliable research computing environment
that allows lab members to focus on research rather than
hardware configuration, software environments, and resource
management.

## Infrastructure Status

| Node | Role | Status |
|---|---|---|
| yelab-node01 | Slurm controller + GPU compute | Operational |
| yelab-node02 | GPU compute | Planned |
| yelab-node03 | GPU compute | Planned |
| yelab-node04 | GPU compute | Planned |

## Node01 - Verified Capabilities

- Ubuntu 24.04.5 LTS with NVIDIA CUDA
- Intel Core Ultra 7 265KF hybrid CPU architecture
- NVIDIA GeForce RTX 5080 (16 GB)
- SSH remote administration
- Windows 11 engineering VM via KVM/QEMU
- Shared research directories with Unix group permissions and ACLs
- MUNGE authentication
- Single-node Slurm scheduling
- Eight P-Cores allocated to Slurm (Linux CPUs 0-7)
- CPU affinity and cgroup v2 memory enforcement
- NVIDIA GPU GRES scheduling
- PyTorch CUDA batch execution through Slurm
- Exclusive scheduling of one GPU among Slurm jobs
- Automatic startup configured for HPC services

## Validation Milestones

| Test | Job | Result |
|---|---|---|
| Basic Slurm execution | 3 | PASS |
| Single CPU affinity | 4 | PASS |
| Eight P-Core mapping | 5 | PASS |
| cgroup CPU and RAM enforcement | 6 | PASS |
| GPU GRES allocation | 7 | PASS |
| PyTorch CUDA batch computation | 8 | PASS |
| Exclusive GPU scheduling | 9, 10 | PASS |
| Post-reboot CUDA batch execution | 11 | PASS |

## Current Limitations

- Slurm manages eight P-Cores; E-Cores are not exposed as
  schedulable Slurm resources.
- Slurm cgroups constrain jobs, not unrelated host processes
  or the Windows VM.
- GPU device isolation is not enabled. Slurm GPU scheduling
  does not prevent non-Slurm programs from accessing the GPU.
- Slurm accounting and persistent job history are not yet deployed.
- Multi-node authentication, networking, and shared storage
  are not yet configured.
- The existing hybrid-CPU workaround requires validation
  on future nodes.

## Documentation

- [System Architecture](docs/architecture.md)
- [Node01 Configuration](docs/node01.md)
- [Architecture Decisions](docs/decisions.md)
- [Slurm Workload Management](docs/slurm.md)
- [GPU Computing](docs/gpu-computing.md)
- [Troubleshooting and Recovery](docs/troubleshooting.md)

Additional Slurm, GPU, operations, and troubleshooting
documentation is under development.

## Principles

1. Research workloads take priority over convenience workloads.
2. Linux retains ownership of NVIDIA GPUs for CUDA computing.
3. Resource allocation must be verified at the operating-system level.
4. Infrastructure must be reproducible and maintainable.
5. Credentials and private authentication material must never
   be committed to the repository.
6. Architectural decisions and known limitations must be documented.

## Project Phases

1. Node01 single-node HPC prototype: core compute validation complete.
2. Operational hardening and documentation: in progress.
3. Multi-node Slurm cluster: planned.
4. Monitoring, accounting, maintenance, and user onboarding: planned.

## Repository Scope

This repository documents infrastructure and operational
procedures. Research datasets, GPU model weights, private
credentials, virtual machine disks, and temporary job outputs
are not part of this repository.
