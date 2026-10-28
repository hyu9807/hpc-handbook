# Architecture Decision Log

This document records major infrastructure decisions,
their rationale, and their known limitations.

## ADR-001: Ubuntu as the Host OS

**Status:** Accepted

Ubuntu is the primary environment for CUDA, research
software, and HPC workloads.

The Linux host retains administrative control of
GPU compute resources.

## ADR-002: Windows as a KVM Guest

**Status:** Accepted

Windows-specific engineering tools run inside an
on-demand QEMU/KVM virtual machine.

This avoids dual-boot requirements and allows
Linux HPC services to remain available.

## ADR-003: No GPU Passthrough

**Status:** Accepted

The RTX 5080 remains under Ubuntu host control.

Launching Windows must not require transferring
GPU ownership away from Linux compute workloads.

The Windows guest uses virtualized display resources.

## ADR-004: Shared Storage Permissions

**Status:** Accepted

Shared lab directories use the `yelab` Unix group,
SetGID permissions, and default ACLs.

Private temporary storage uses per-user directories.

This is currently node-local storage, not a shared
multi-node filesystem.

## ADR-005: Slurm Resource Management

**Status:** Implemented on Node01

Slurm coordinates CPU, memory, and GPU allocations
for research workloads.

The validated configuration includes:

- select/cons_tres with CR_CPU_Memory
- task/affinity and task/cgroup
- proctrack/cgroup
- cgroup v2 memory and CPU containment
- GPU GRES scheduling

Persistent job accounting has not yet been deployed.

## ADR-006: P-Core-Only Slurm Scheduling

**Status:** Implemented on Node01

**Context:**

Node01 uses an Intel hybrid processor containing
eight P-Cores and twelve E-Cores.

The installed Slurm 23.11.4 and hwloc combination
did not initially expose the desired CPU topology.

**Decision:**

Expose eight P-Cores to Slurm using:

`HWLOC_CPUKINDS_HOMOGENEOUS=1`

The setting is applied through a systemd drop-in
for slurmd.

**Validation:**

Eight simultaneous single-CPU Slurm tasks were
bound one-to-one to Linux CPUs 0-7.

**Limitations:**

This is a hardware- and software-specific workaround.

It must be revalidated after processor, kernel,
hwloc, or Slurm changes.

E-Cores remain outside the Slurm resource inventory.

Non-Slurm host processes are not automatically
restricted to E-Cores.

## ADR-007: cgroup v2 Resource Containment

**Status:** Implemented on Node01

**Context:**

Resource allocation by the scheduler alone does
not guarantee kernel-level enforcement.

**Decision:**

Use Slurm task/cgroup and proctrack/cgroup with
Linux cgroup v2.

Constrain CPU sets and job memory allocations.

**Validation:**

A one-CPU job was restricted to Linux CPU 0.

A 512 MiB allocation produced a 536870912-byte
memory limit in the job cgroup hierarchy.

**Limitations:**

Cgroup constraints apply to Slurm jobs.

Ubuntu desktop processes and the Windows VM
remain outside Slurm's resource containment.

## ADR-008: Single-GPU GRES Scheduling

**Status:** Implemented on Node01

**Context:**

Multiple researchers may independently submit
GPU workloads to a node containing one GPU.

**Decision:**

Register the RTX 5080 as:

`Gres=gpu:1`

Use `/dev/nvidia0` as the device mapping.

Require GPU workloads to request the GPU
through Slurm.

**Validation:**

PyTorch CUDA batch jobs completed successfully.

Two GPU-reserving jobs were scheduled sequentially,
with no execution interval overlap.

**Limitations:**

`ConstrainDevices=no` remains configured.

Slurm GPU reservations do not prevent unrelated
host processes from using the device.

## ADR-009: Combined Controller and Compute Node

**Status:** Accepted for prototype

**Context:**

The first deployment contains only one HPC node.

**Decision:**

Run both slurmctld and slurmd on yelab-node01.

This minimizes initial infrastructure complexity.

**Consequences:**

Node01 is a single point of failure for scheduling.

The controller placement should be reviewed
during multi-node deployment.

## ADR-010: Local-First Storage Architecture

**Status:** Accepted for prototype

**Context:**

Node01 initially operates independently.

A shared distributed filesystem has not yet
been selected or deployed.

**Decision:**

Use local `/srv/yelab` directories for research
data and `/scratch` for temporary job storage.

**Consequences:**

Other nodes will not automatically see Node01
files through these paths.

Multi-node deployment requires an explicit
storage, data movement, and backup strategy.

## ADR-011: Research DMZ and VPN-Gated Remote Access

**Status:** Implemented on Node01

**Context:**

Mines campus networking restricts remote SSH and RDP
access to non-Mines-managed devices on the standard
Ethernet network.

Node01 requires secure remote administration and
development access without converting the workstation
into a centrally managed endpoint.

**Decision:**

Register Node01 with the Mines Research Network
through the official Special Network Access Request.

Use GlobalProtect VPN as the approved access path,
with SSH public-key authentication for authorized users.

The validated remote workflow supports:

- SSH terminal access
- macOS Keychain integration
- VS Code Remote-SSH
- Remote Slurm job submission

**Validation:**

On October 28, 2026, the following were verified:

- Research DMZ registration completed
- GlobalProtect connected from macOS 27
- SSH public-key authentication succeeded
- VS Code Remote-SSH connected successfully

**Consequences:**

- VPN connectivity is required for the validated workflow.
- Node01 currently receives its IP address through DHCP.
- Research DMZ membership does not guarantee unrestricted
  communication between future compute nodes.
- Network access remains subject to Mines IT policies.
- SSH and RDP must not be exposed directly to the internet.

See [Remote Access and Development](remote-access.md).
