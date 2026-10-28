# Node01 - As-Built System Configuration

## Overview

| Property | Value |
|---|---|
| Hostname | yelab-node01 |
| Role | Slurm controller + GPU compute node |
| Operating system | Ubuntu 24.04.5 LTS |
| CPU | Intel Core Ultra 7 265KF |
| GPU | NVIDIA GeForce RTX 5080 |
| Physical memory | 32 GB installed |
| Storage | 2 TB NVMe SSD |
| Network | Mines Research DMZ (wired Ethernet) |
| Node status | Single-node HPC prototype operational |

## Network and Remote Access

| Property | Configuration |
|---|---|
| Network zone | Mines Research DMZ |
| Physical interface | enp132s0 |
| NetworkManager connection | netplan-enp132s0 |
| Address assignment | DHCP |
| Remote access | GlobalProtect VPN + SSH |
| SSH authentication | ED25519 public key |
| macOS integration | Keychain and SSH config |
| Remote development | VS Code Remote-SSH |
| Last validation | October 28, 2026 |

Node01 was registered with Mines IT through the
Special Network Access Request process.

After Research DMZ authorization and reboot,
SSH connectivity through GlobalProtect was verified.

On the tested macOS 27 client, enabling Firewall
Stealth Mode resolved a GlobalProtect connection issue.

VS Code Remote-SSH was successfully validated.

IP addresses, hardware identifiers, and administrative
ticket information are maintained outside this
public repository.

See [Remote Access and Development](remote-access.md).

## Hardware and CPU Topology

Node01 uses an Intel hybrid processor containing:

- 8 Performance Cores (P-Cores)
- 12 Efficiency Cores (E-Cores)
- 20 logical CPUs
- 1 NUMA node

Observed Linux CPU mapping:

| Core type | Linux CPU IDs | Slurm allocation |
|---|---|---|
| P-Cores | 0-7 | Available to Slurm |
| E-Cores | 8-19 | Not advertised to Slurm |

This topology was verified on Node01. It must not be
assumed to apply to other hardware.

## Operating System

- Ubuntu 24.04.5 LTS
- Validated kernel: 7.0.0-38-generic
- NVIDIA driver: 595.99.02
- Filesystem: ext4
- SSH server: enabled
- Automatic system suspension: disabled
- systemd and unified cgroup v2

Kernel and driver versions describe the validated deployment
and should be rechecked following system upgrades.

## Storage Layout

| Path | Purpose |
|---|---|
| /home | User files and repositories |
| /srv/yelab/datasets | Shared research datasets |
| /srv/yelab/projects | Shared research projects |
| /srv/yelab/software | Shared software resources |
| /scratch | Node-local scratch space |

Shared research directories use the `yelab` Unix group,
SetGID permissions, and default ACLs.

Individual scratch directories may use private permissions.

Scratch space is not a substitute for backed-up storage.

## Windows Engineering VM

| Property | Configuration |
|---|---|
| Hypervisor | QEMU/KVM with libvirt |
| Guest OS | Windows 11 Pro for Workstations |
| VM name | win11-engineering |
| vCPU | 6 (1 socket x 6 cores) |
| Memory | 8 GiB |
| Virtual disk | 160 GiB qcow2 |
| Graphics | QXL / RDP |
| Network | libvirt NAT |
| GPU passthrough | Disabled |

The Windows VM is started on demand.

RDP client:
- FreeRDP 3
- 2560x1440 resolution
- 200% desktop scaling

Local launcher:
`~/.local/bin/yelab-windows`

The RTX 5080 remains under Ubuntu host ownership.

VM CPU and memory consumption must be considered alongside
Slurm workloads because host-level resource partitioning
between the VM and Slurm is not yet enforced.

## HPC Software Stack

| Component | Configuration |
|---|---|
| Slurm | 23.11.4 (Ubuntu package) |
| Authentication | MUNGE |
| Resource selection | select/cons_tres |
| CPU/memory selection | CR_CPU_Memory |
| CPU binding | task/affinity |
| Resource containment | task/cgroup |
| Process tracking | proctrack/cgroup |
| Control groups | cgroup v2 |
| GPU scheduling | GRES gpu:1 |

Validated PyTorch environment:

- PyTorch 2.13.0+cu130
- CUDA runtime available
- RTX 5080 compute capability 12.0

## Slurm Resource Policy

| Resource | Configured allocation |
|---|---|
| CPUs | 8 |
| CPU type | P-Cores |
| Linux CPU IDs | 0-7 |
| Slurm RealMemory | 16000 MiB |
| GPU | 1 x RTX 5080 |
| Default partition | debug |
| Partition MaxTime | 01:00:00 |

The 16000 MiB value is the memory capacity advertised to
Slurm. It is not a physical reservation that prevents
Ubuntu or the Windows VM from using system memory.

Memory limits are enforced for individual Slurm jobs
through cgroup v2.

## Intel Hybrid CPU Compatibility

Slurm 23.11.4 with the installed hwloc implementation
did not initially report the expected processor topology.

The following environment setting is applied to slurmd:

`HWLOC_CPUKINDS_HOMOGENEOUS=1`

Systemd drop-in:

`/etc/systemd/system/slurmd.service.d/10-hwloc.conf`

The workaround permits the current Slurm configuration
to expose eight CPUs.

Verification confirmed that eight concurrent single-CPU
Slurm tasks mapped one-to-one to Linux CPUs 0-7.

This workaround must be reconsidered when Slurm, hwloc,
or the processor architecture changes.

## CPU and Memory Isolation

The following were validated:

- Single-task CPU affinity restricted to CPU 0.
- Eight concurrent tasks mapped to CPUs 0-7.
- cgroup v2 effective cpuset matched task allocation.
- A job requesting 512 MiB had a memory.max limit
  of 536870912 bytes at the relevant cgroup levels.

Slurm job containment does not prevent non-Slurm
processes from using these same host resources.

## GPU Scheduling

Node01 advertises:

`Gres=gpu:1`

Device mapping:

`Name=gpu File=/dev/nvidia0`

GPU resource requests are made using:

`--gres=gpu:1`

GPU GRES allocation was validated with
`CUDA_VISIBLE_DEVICES=0`.

Two Slurm GPU jobs were observed executing sequentially,
without overlapping execution intervals.

GPU device isolation remains disabled:

`ConstrainDevices=no`

Therefore the GPU is exclusively scheduled among
cooperating Slurm jobs, not exclusively owned against
non-Slurm host processes.

## Batch Computing Validation

Validated workload:

- Slurm job name: gpu-smoke
- Resource request: 2 CPUs, 2048 MiB, 1 GPU
- Matrix multiplication: 2048 x 2048 FP16
- CUDA execution: successful
- Result finite-value check: passed

Validated jobs:

| Job ID | Validation |
|---|---|
| 4 | Single CPU affinity |
| 5 | Eight P-Core mapping |
| 6 | cgroup CPU and RAM limits |
| 7 | GPU GRES request |
| 8 | PyTorch CUDA batch job |
| 9-10 | GPU queue exclusivity |
| 11 | Post-reboot CUDA batch job |

## Service Management

The following services are enabled at boot:

- munge
- slurmctld
- slurmd

Verified systemd properties:

- Delegate=yes
- Environment=HWLOC_CPUKINDS_HOMOGENEOUS=1

The initial operating configuration was confirmed with:

- All three services active
- Slurm node state idle
- GPU GRES gpu:1
- Eight idle Slurm CPUs

## Outstanding Work

- Persistent Slurm accounting
- GPU device isolation policy
- Host/VM resource contention controls
- Monitoring and operational alerting
- Multi-node deployment
- Shared storage strategy across nodes
- Version upgrade and maintenance policy
- Disaster recovery and backup procedures
