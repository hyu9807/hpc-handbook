# Slurm Workload Management

## Overview

Ye Lab uses Slurm to schedule and manage research workloads.

The current deployment is a single-node prototype:

- Controller: yelab-node01
- Compute node: yelab-node01
- Cluster name: yelab
- Default partition: debug
- Slurm version: 23.11.4
- Authentication: MUNGE
- Resource selection: select/cons_tres

Future nodes will join the same scheduling environment
after networking, authentication, and storage requirements
have been validated.

## Service Architecture

Three systemd services provide the core functionality:

| Service | Purpose |
|---|---|
| munge | Authentication between Slurm components |
| slurmctld | Scheduling and cluster control |
| slurmd | Execution and monitoring on compute nodes |

All three services are enabled at boot on Node01.

Check service status:

```bash
systemctl is-enabled munge slurmctld slurmd
systemctl is-active munge slurmctld slurmd
```

Check cluster availability:

```bash
sinfo
sinfo -N -o "%N %T %G %C"
scontrol show node yelab-node01
```

## Configuration Files

The active system configuration is stored under
`/etc/slurm/`.

| File | Purpose |
|---|---|
| slurm.conf | Cluster, node, partition, scheduling configuration |
| cgroup.conf | Linux resource containment |
| gres.conf | GPU device registration |

Configuration changes require validation and, depending
on the parameter, service reconfiguration or restart.

Do not restart Slurm services while active research
jobs are running without an approved maintenance plan.

## Node01 Resource Configuration

The following settings represent the validated deployment:

```ini
ClusterName=yelab
SlurmctldHost=yelab-node01
AuthType=auth/munge
CredType=cred/munge

SelectType=select/cons_tres
SelectTypeParameters=CR_CPU_Memory

ProctrackType=proctrack/cgroup
TaskPlugin=task/affinity,task/cgroup

GresTypes=gpu

NodeName=yelab-node01 CPUs=8 Sockets=1 CoresPerSocket=8 ThreadsPerCore=1 RealMemory=16000 State=UNKNOWN Gres=gpu:1
PartitionName=debug Nodes=yelab-node01 Default=YES MaxTime=01:00:00 State=UP
```

This is a configuration excerpt, not a complete replacement
for the active `slurm.conf`.

Resource availability:

| Resource | Advertised to Slurm |
|---|---|
| CPU | 8 P-Cores |
| RAM | 16000 MiB |
| GPU | 1 x NVIDIA RTX 5080 |

The configured RAM capacity does not prevent Ubuntu
or non-Slurm processes from consuming host memory.

## Hybrid CPU Architecture

The Intel Core Ultra 7 265KF contains:

- 8 P-Cores: Linux CPUs 0-7
- 12 E-Cores: Linux CPUs 8-19

The installed Slurm 23.11.4 and hwloc combination
required a compatibility workaround.

Systemd drop-in:

`/etc/systemd/system/slurmd.service.d/10-hwloc.conf`

Contents:

```ini
[Service]
Environment=HWLOC_CPUKINDS_HOMOGENEOUS=1
```

Validation confirmed that eight simultaneous single-CPU
Slurm tasks were assigned to CPUs 0-7, with no E-Core
allocation in that test.

This mapping must be revalidated after CPU topology,
Slurm, or hwloc changes.

## cgroup v2 Containment

Node01 uses Linux cgroup v2.

Validated configuration:

```ini
CgroupPlugin=autodetect
ConstrainCores=yes
ConstrainRAMSpace=yes
AllowedRAMSpace=100
ConstrainDevices=no
```

CPU affinity:

- task/affinity provides task-level CPU binding.
- task/cgroup constrains allocated CPU sets.
- proctrack/cgroup tracks job processes.

Memory:

- Jobs receive memory limits through cgroup v2.
- A 512 MiB job allocation produced a 536870912-byte
  memory.max limit in the job hierarchy.
- A child cgroup may report `memory.max=max` while
  remaining constrained by a parent cgroup.

Verify from inside a Slurm task:

```bash
srun --ntasks=1 --cpus-per-task=1 --mem=512M \
  --cpu-bind=cores \
  bash -c '
    grep Cpus_allowed_list /proc/self/status
    cat /proc/self/cgroup
  '
```

Important: cgroup containment applies to Slurm jobs.
It does not isolate host desktop processes or the
Windows engineering VM from those CPU and RAM resources.

## Basic Job Submission

Run an interactive command:

```bash
srun --partition=debug \
  --ntasks=1 \
  --cpus-per-task=1 \
  --mem=512M \
  --time=00:02:00 \
  hostname
```

Submit a batch script:

```bash
sbatch scripts/gpu-smoke.sbatch
```

Inspect the queue:

```bash
squeue
squeue -u "$USER"
```

Inspect a job:

```bash
scontrol show job <JOB_ID>
```

Cancel a job:

```bash
scancel <JOB_ID>
```

The debug partition currently has a one-hour time limit.

## Job States

Common Slurm states:

| State | Meaning |
|---|---|
| PENDING | Waiting for resources or scheduling |
| RUNNING | Executing |
| COMPLETED | Finished successfully |
| FAILED | Finished unsuccessfully |
| CANCELLED | Cancelled by user or administrator |
| TIMEOUT | Exceeded time limit |

Use `squeue` for active and pending jobs.

Persistent historical accounting is not yet deployed.
Completed jobs should not be assumed to remain queryable
indefinitely through the controller.

## Job Logs

Current smoke-test scripts use:

`/scratch/huawei/slurm-logs/`

Example:

```bash
cat /scratch/huawei/slurm-logs/gpu-smoke-11.out
cat /scratch/huawei/slurm-logs/gpu-smoke-11.err
```

Production templates should use user-specific writable
log locations rather than hard-coded personal directories.

Scratch data and logs are node-local and not guaranteed
to be persistent or backed up.

## Validated Tests

| Job | Purpose | Result |
|---|---|---|
| 4 | Single CPU affinity | PASS |
| 5 | Eight P-Core mapping | PASS |
| 6 | CPU and RAM cgroup enforcement | PASS |
| 7 | GPU resource allocation | PASS |
| 8 | PyTorch CUDA batch job | PASS |
| 9-10 | GPU resource queueing | PASS |
| 11 | Post-reboot GPU batch execution | PASS |

## Maintenance Considerations

Before modifying the active Slurm configuration:

1. Check for running jobs with `squeue`.
2. Back up the active configuration files.
3. Validate changes before restarting services.
4. Check systemd and Slurm logs if startup fails.
5. Run a CPU and GPU smoke test after major changes.

Useful diagnostic commands:

```bash
journalctl -u slurmd -n 100 --no-pager
journalctl -u slurmctld -n 100 --no-pager
scontrol show config
scontrol show node yelab-node01
```

Slurm 23.11.4 is an older release. Version upgrades
should be planned and tested rather than mixed casually
with distribution packages.

## Future Work

- Multi-node Slurm configuration
- Centralized user and authentication management
- Persistent Slurm accounting
- GPU device access policy
- Host and Windows VM resource coordination
- Monitoring and alerting
- Upgrade and rollback procedures
