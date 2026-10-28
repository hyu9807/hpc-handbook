# Node01 Troubleshooting and Recovery

## Purpose

This document records problems encountered during the
initial deployment of Ye Lab HPC Node01.

The emphasis is on observed symptoms, validated fixes,
diagnostic procedures, and remaining limitations.

Do not apply Node01-specific workarounds to different
hardware without verification.

## 1. Slurm Incorrectly Detects Hybrid CPU Topology

### Symptoms

Node01 contains an Intel Core Ultra 7 265KF:

- 8 P-Cores
- 12 E-Cores
- 20 logical CPUs

Linux recognized all 20 CPUs.

However, the initial `slurmd -C` output reported
an unexpectedly small CPU topology, including
only two CPUs in the initial test.

### Investigation

Useful commands:

```bash
lscpu
nproc
cat /proc/self/status | grep Cpus_allowed_list
slurmd -C
```

The installed Slurm 23.11.4 and hwloc combination
did not handle the processor's heterogeneous CPU
kinds as required by the initial deployment.

### Validated Workaround

Apply the environment variable:

```ini
[Service]
Environment=HWLOC_CPUKINDS_HOMOGENEOUS=1
```

Through:

```text
/etc/systemd/system/slurmd.service.d/10-hwloc.conf
```

After a controlled service restart, Slurm reported
eight schedulable CPUs.

### Verification

Eight concurrent single-CPU Slurm tasks were
bound one-to-one to Linux CPUs 0-7.

This confirmed the intended P-Core mapping on Node01.

### Limitations

This is a compatibility workaround, not a universal
hybrid-CPU configuration.

Revalidate after changes to Slurm, hwloc, the CPU,
or system software.

## 2. Slurm Allocates a CPU But Linux Allows All CPUs

### Symptoms

An early job requested:

```text
--cpus-per-task=1
```

Slurm reported one allocated CPU, but the task showed:

```text
Cpus_allowed_list: 0-19
```

The task was observed running on Linux CPU 11,
an E-Core.

### Cause

The initial Slurm configuration did not have an
effective task CPU affinity plugin enabled.

Scheduling a CPU resource does not automatically
guarantee that Linux restricts the task's affinity.

### Validated Configuration

```ini
TaskPlugin=task/affinity,task/cgroup
ProctrackType=proctrack/cgroup
```

With cgroup v2:

```ini
ConstrainCores=yes
```

### Verification

Inside a Slurm task:

```bash
grep Cpus_allowed_list /proc/self/status
```

The validated single-CPU task returned:

```text
Cpus_allowed_list: 0
```

Eight concurrent single-CPU tasks subsequently
mapped to CPUs 0-7.

## 3. Child cgroup Reports memory.max=max

### Symptoms

During memory isolation verification, the task-level
cgroup returned:

```text
memory.max: max
```

This can appear to indicate that memory limits
are not enforced.

### Explanation

Linux cgroup v2 limits are hierarchical.

A child cgroup may report an unlimited local value
while still being restricted by a parent cgroup.

### Validated Observation

For a job requesting 512 MiB:

```text
job-level memory.max: 536870912
user-level memory.max: 536870912
task-level memory.max: max
```

The parent limits still apply.

### Verification

Inspect `/proc/self/cgroup`, then examine
`memory.max` along the full ancestor path.

Do not conclude that memory enforcement failed
based only on the task-level file.

## 4. GPU Is Visible But Slurm Scheduling Is Unverified

### Symptoms

`nvidia-smi` detects the GPU, but this alone does
not demonstrate Slurm GPU allocation.

### Verification

Request a GPU through Slurm:

```bash
srun --partition=debug \
  --ntasks=1 \
  --cpus-per-task=1 \
  --mem=1024M \
  --gres=gpu:1 \
  --time=00:02:00 \
  bash -c 'echo "$CUDA_VISIBLE_DEVICES"; nvidia-smi'
```

Validated result:

```text
CUDA_VISIBLE_DEVICES=0
NVIDIA GeForce RTX 5080
```

A subsequent PyTorch CUDA batch job completed
a GPU matrix multiplication successfully.

### Important Limitation

The current configuration uses:

```ini
ConstrainDevices=no
```

Slurm GPU allocation does not prevent external
non-Slurm host processes from accessing the GPU.

## 5. GPU Job Does Not Start Immediately

### Investigation

```bash
squeue
scontrol show job <JOB_ID>
```

A pending job may be waiting for requested resources,
including the GPU.

### Validated Behavior

Jobs 9 and 10 each requested the only RTX 5080.

Job 9:

```text
Start:  23:35:43
Finish: 23:37:13
```

Job 10:

```text
Start:  23:37:43
Finish: 23:37:48
```

The execution intervals did not overlap.

The observed 30-second interval between jobs
must not be treated as a required scheduling delay.

## 6. Batch Job Log File Cannot Be Found

### Symptoms

A job was successfully submitted:

```text
Submitted batch job 11
```

But attempting to read:

```text
gpu-queue-11.out
```

returned a file-not-found error.

### Cause

The wrong script's log filename was used.

The smoke-test script writes:

```text
gpu-smoke-%j.out
gpu-smoke-%j.err
```

The queue-test script writes:

```text
gpu-queue-%j.out
```

### Verification

For Job 11:

```bash
cat /scratch/huawei/slurm-logs/gpu-smoke-11.out
```

The correct file showed:

```text
GPU COMPUTATION SUCCESS
```

If a log is still missing, inspect the active job
and its configured standard output location:

```bash
squeue -j <JOB_ID>
scontrol show job <JOB_ID>
```

Completed job records may not remain available
without persistent Slurm accounting.

## 7. Slurm Does Not Recover After Reboot

### First Checks

```bash
systemctl is-enabled munge slurmctld slurmd
systemctl is-active munge slurmctld slurmd
sinfo
```

Inspect service errors:

```bash
sudo journalctl -u munge -n 50 --no-pager
sudo journalctl -u slurmctld -n 50 --no-pager
sudo journalctl -u slurmd -n 50 --no-pager
```

Confirm slurmd systemd properties:

```bash
systemctl show slurmd -p Environment -p Delegate
```

Expected Node01 settings:

```text
Delegate=yes
Environment=HWLOC_CPUKINDS_HOMOGENEOUS=1
```

### Validated Result

Node01 was configured with all three services
enabled at boot.

A subsequent post-reboot PyTorch CUDA batch job
completed successfully as Job 11.

Do not immediately modify configurations if a
node is temporarily in a transitional state.
Inspect daemon logs and allow normal registration
to complete first.

## 8. Campus SSH Connectivity

### Original Problem

SSH worked locally on Node01, but remote connections
from a MacBook on Mines WiFi could not be established.

Ubuntu SSH configuration was not the root cause.

Mines IT confirmed that the original campus subnet
restricted remote SSH and RDP access to unmanaged devices.

### Validated Resolution

Node01 was registered with the Mines Research Network
through a Special Network Access Request.

After IT approval and a system reboot, remote SSH
was successfully established through GlobalProtect VPN.

**Validation date:** October 28, 2026.

### Diagnostics

On Node01:

```bash
systemctl is-active ssh
sudo ss -lntp | grep ':22'
```

On the macOS client, with GlobalProtect connected:

```bash
ssh -o ConnectTimeout=10 \
  yelab-node01 'echo SSH_OK && hostname'
```

A successful connection confirms that the VPN,
SSH transport, and remote authentication are working.

Do not bypass campus network restrictions by
exposing SSH directly to the internet.

### macOS 27 GlobalProtect Connection Failure

**Symptom:**

GlobalProtect initially failed to connect from
the MacBook running macOS 27.

**Validated workaround:**

Mines IT recommended enabling macOS Firewall
Stealth Mode.

Navigate to:

System Settings > Network > Firewall >
Firewall Options > Stealth Mode

After enabling Stealth Mode, GlobalProtect
connected successfully.

This workaround was validated on the tested
MacBook and should not be assumed to apply
universally to all macOS installations.

### VS Code Remote-SSH Timeout

**Symptom:**

Terminal SSH worked, but VS Code Remote-SSH
reported:

`Error: Timeout (Connecting with SSH timed out)`

**Validated solution:**

In VS Code User Settings (JSON), configure:

```json
{
    "remote.SSH.showLoginTerminal": true,
    "remote.SSH.useLocalServer": false,
    "remote.SSH.connectTimeout": 60
}
```

Merge these entries with existing settings.

After applying the configuration, VS Code
successfully installed and started its remote
server under:

`~/.vscode-server/`

Remote development was subsequently confirmed
operational.

### Remaining Limitations

- GlobalProtect is required for the approved access path.
- Node01 currently uses DHCP.
- Direct inter-node connectivity has not been validated.
- A stable DNS name or DHCP reservation is not yet configured.

See [Remote Access and Development](remote-access.md)
for the complete setup procedure.

## 9. Windows VM Resource Competition

The Windows engineering VM operates outside Slurm.

Its CPU and memory allocations are not automatically
coordinated with Slurm jobs.

A running VM can therefore compete with research
workloads for host CPU cycles and system memory.

Before high-demand computation, check running VMs:

```bash
virsh -c qemu:///system list --state-running
```

Future work includes explicit host/VM resource
coordination and operational scheduling policies.

## 10. Safe Configuration Changes

Before modifying live infrastructure:

1. Check running jobs.
2. Back up the relevant configuration files.
3. Apply one controlled change at a time.
4. Verify configuration and daemon status.
5. Re-run the appropriate smoke tests.
6. Record successful changes in this handbook.

Useful commands:

```bash
squeue
sinfo
scontrol show node yelab-node01
systemctl status slurmd
nvidia-smi
```

Do not restart the scheduler or compute daemon
during active research jobs without coordinating
a maintenance window.

## Recovery Boundaries

This handbook documents the validated initial
Node01 configuration.

It does not yet provide a complete disaster
recovery, automated provisioning, or backup system.

Important remaining tasks include:

- Persistent Slurm accounting
- Automated monitoring and alerts
- Configuration change management
- VM and research data backups
- Multi-node recovery procedures
- Full infrastructure deployment automation
