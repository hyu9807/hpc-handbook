# Architecture Decision Log

## ADR-001: Ubuntu as the Host OS

Ubuntu is the primary environment for CUDA,
research software, and HPC workloads.

## ADR-002: Windows as a KVM Guest

Windows-specific engineering tools run inside
an on-demand virtual machine.

## ADR-003: No GPU Passthrough

The RTX 5080 remains under Ubuntu host control.
Launching Windows must not require transferring
GPU ownership away from Linux compute workloads.

## ADR-004: Shared Storage Permissions

Shared lab directories use the yelab Unix group,
SetGID, and default ACLs.

Private temporary storage uses per-user directories.

## ADR-005: Slurm Resource Management

Slurm will coordinate research compute workloads.

CPU and memory reservations, GPU accounting, and
isolation rules must be tested before production use.
