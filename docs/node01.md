# Node01 — System Configuration

## Hardware

| Component | Configuration |
|---|---|
| CPU | Intel Core Ultra 7 265KF |
| P-Cores | 8, Linux CPU IDs 0-7 |
| E-Cores | 12, Linux CPU IDs 8-19 |
| NUMA | 1 node |
| Memory | 32 GB installed |
| GPU | NVIDIA GeForce RTX 5080, 16 GB |
| Storage | 2 TB NVMe SSD |

## Operating System

- Hostname: yelab-node01
- Ubuntu 24.04.5 LTS
- Kernel: 7.0.0-38-generic
- NVIDIA Driver: 595.99.02
- Filesystem: ext4
- SSH Server: enabled

## Storage Layout

- /home: User files and repositories
- /srv/yelab/datasets: Shared research datasets
- /srv/yelab/projects: Shared research projects
- /srv/yelab/software: Shared software resources
- /scratch: Node-local temporary computation storage

## Windows Engineering VM

- Hypervisor: KVM/QEMU with libvirt
- Guest: Windows 11 Pro for Workstations
- vCPU: 6, topology 1 socket x 6 cores
- Memory: 8 GiB
- Disk: 160 GiB virtual disk
- Graphics: QXL and RDP
- GPU Passthrough: Disabled
- RDP: FreeRDP 3, 2560x1440, 200% scaling
- Launcher: ~/.local/bin/yelab-windows

## Planned HPC Services

- MUNGE authentication
- Slurm controller and compute daemon
- NVIDIA GPU GRES
- cgroup resource enforcement

Resource allocation and CPU isolation policy:
pending validation.
