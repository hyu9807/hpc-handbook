# Ye Lab HPC Architecture

## Mission

Provide a reproducible, maintainable research computing
environment that minimizes infrastructure-related overhead
for Ye Lab researchers.

The architecture evolves from individual GPU workstations
toward a shared, multi-node Slurm cluster.

## Current Deployment

Node01 is the first operational single-node HPC prototype.

```text
Ye Lab HPC
|
+-- yelab-node01 [OPERATIONAL]
|   |
|   +-- Ubuntu 24.04.5 LTS
|   +-- Intel Core Ultra 7 265KF
|   |   +-- 8 P-Cores: Slurm scheduling
|   |   +-- 12 E-Cores: not advertised to Slurm
|   |
|   +-- NVIDIA RTX 5080 (16 GB)
|   +-- 32 GB installed RAM
|   +-- 2 TB NVMe SSD
|   |
|   +-- MUNGE authentication
|   +-- Slurm controller (slurmctld)
|   +-- Slurm compute daemon (slurmd)
|   +-- cgroup v2 resource containment
|   +-- NVIDIA GPU GRES scheduling
|   |
|   +-- SSH remote administration
|   +-- Shared research directories
|   +-- Local scratch storage
|   |
|   +-- QEMU/KVM
|       +-- Windows 11 engineering VM
|
+-- yelab-node02 [PLANNED]
+-- yelab-node03 [PLANNED]
+-- yelab-node04 [PLANNED]
```

Node01 currently operates as both the Slurm controller
and a compute node.

This arrangement is appropriate for the initial prototype,
but creates a single point of failure for scheduling.

## Resource Management

### CPU

Node01 uses an Intel hybrid CPU architecture.

Slurm advertises eight CPUs corresponding to the
eight P-Cores (Linux CPUs 0-7).

The E-Cores (Linux CPUs 8-19) are not exposed as
Slurm scheduling resources.

Validated tests confirmed that eight concurrent
single-CPU tasks mapped to CPUs 0-7.

This does not prevent unrelated host processes from
running on those same CPUs.

### Memory

Node01 advertises 16000 MiB to Slurm.

Slurm cgroup v2 enforces per-job memory limits.

The remaining physical memory provides operating
headroom for Ubuntu and the Windows engineering VM,
but it is not exclusively reserved for them.

A future host-level resource policy may be required.

### GPU

Node01 exposes one GPU to Slurm:

NVIDIA GeForce RTX 5080, GRES gpu:1.

GPU requests are mutually scheduled among Slurm jobs.

Device-level isolation against processes outside Slurm
is not currently enabled.

The GPU remains available to the Ubuntu host,
including graphical desktop processes.

## Authentication and Identity

MUNGE authenticates Slurm components.

Node01 currently operates as a standalone system.

A multi-node deployment will require:

- Consistent user and group identities across nodes
- Secure distribution of the shared MUNGE key
- Reliable node hostname resolution
- Network connectivity for Slurm services
- Documented access and authorization policies

Authentication keys and user credentials must never
be committed to this repository.

## Networking

Node01 uses campus wired Ethernet.

SSH is operational on the host.

Cross-segment access from personal devices may be
restricted by campus networking policies.

Multi-node communication, hostname resolution,
firewall rules, and remote access must be validated
before expanding the cluster.

Do not assume that a successful local SSH test
guarantees reachability from other campus networks.

## Storage Architecture

Current directories:

| Location | Purpose |
|---|---|
| /home | User files |
| /srv/yelab/datasets | Shared datasets |
| /srv/yelab/projects | Research projects |
| /srv/yelab/software | Shared software |
| /scratch | Temporary computation |

These directories currently reside on Node01's
local storage.

They are not yet a distributed filesystem.

Future nodes will require an explicit strategy
for shared datasets, job inputs, outputs, and
environment reproducibility.

Node-local scratch space must not be treated
as permanent or backed-up storage.

## Windows Engineering Environment

Windows-specific engineering software runs inside
an on-demand QEMU/KVM virtual machine.

The guest uses virtual CPU, RAM, storage, and
display resources.

GPU passthrough is disabled so that Linux retains
ownership of the RTX 5080.

The Windows VM is not managed by Slurm.

Its host resource usage can compete with Slurm
workloads and requires an operational policy.

## Deployment Roadmap

### Phase 1: Workstation Standardization

Status: Core functionality validated on Node01.

Includes:

- Ubuntu installation
- NVIDIA drivers and CUDA
- SSH
- QEMU/KVM engineering VM
- Storage and permissions
- Reproducible system documentation

### Phase 2: Single-Node Slurm

Status: Core compute functionality validated.

Includes:

- MUNGE authentication
- Controller and compute services
- P-Core scheduling
- CPU affinity
- cgroup v2 CPU and memory containment
- GPU GRES
- PyTorch CUDA batch execution
- Exclusive GPU scheduling
- Reboot recovery testing

Operational hardening remains in progress.

### Phase 3: Multi-Node Cluster

Status: Planned.

Includes:

- Node02-04 installation
- Consistent software versions
- Network and firewall verification
- Cross-node authentication
- Shared user and group management
- Storage strategy
- GPU scheduling across multiple nodes

### Phase 4: Operations and Maintenance

Status: Partially implemented.

Includes:

- Monitoring and alerting
- Persistent Slurm accounting
- User onboarding
- Maintenance windows
- Configuration backups
- Upgrade and rollback procedures
- Hardware replacement procedures
- Disaster recovery
- Research environment management

## Design Principles

1. Research workloads receive scheduling priority.
2. NVIDIA GPUs remain controlled by Linux.
3. Resource allocation must be validated empirically.
4. Local workstations should remain maintainable.
5. Infrastructure changes must be documented.
6. Sensitive authentication material stays outside Git.
7. Multi-node expansion should reuse proven standards,
   not rely on undocumented manual configuration.
