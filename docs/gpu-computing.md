# GPU Computing on Ye Lab HPC

## Overview

Node01 provides NVIDIA GPU computing through Slurm.

Validated hardware and software:

| Component | Configuration |
|---|---|
| GPU | NVIDIA GeForce RTX 5080 |
| GPU memory | 16303 MiB reported by nvidia-smi |
| NVIDIA driver | 595.99.02 |
| PyTorch | 2.13.0+cu130 |
| CUDA compute capability | 12.0 |
| GPU resources | gres/gpu=1 |

The GPU is owned by the Ubuntu host.

The Windows engineering VM does not use GPU passthrough.

## GPU Scheduling Policy

Node01 advertises one GPU:

```ini
GresTypes=gpu
```

Node configuration includes:

```ini
Gres=gpu:1
```

The GPU device is registered in `gres.conf`:

```ini
Name=gpu File=/dev/nvidia0
```

A job must explicitly request GPU resources:

```bash
#SBATCH --gres=gpu:1
```

Or when using srun:

```bash
srun --partition=debug \
  --ntasks=1 \
  --cpus-per-task=2 \
  --mem=2048M \
  --gres=gpu:1 \
  --time=00:05:00 \
  nvidia-smi
```

GPU requests are scheduled through Slurm's Generic
RESources (GRES) mechanism.

## GPU Visibility

A GPU job should receive the environment variable:

```text
CUDA_VISIBLE_DEVICES=0
```

This identifies the CUDA-visible GPU for the task.

On Node01, GPU 0 corresponds to the RTX 5080.

CUDA_VISIBLE_DEVICES is not a security boundary.
It does not guarantee exclusive device access by
processes outside Slurm.

## PyTorch Environment

The validated initial test environment is located at:

`/home/huawei/hpc-tests/gpu-smoke/.venv`

Check PyTorch and CUDA:

```bash
/home/huawei/hpc-tests/gpu-smoke/.venv/bin/python -c \
  'import torch; print(torch.__version__); print(torch.cuda.is_available())'
```

Validated output included:

```text
2.13.0+cu130
True
```

This is a Node01 test environment, not a shared
production Python installation.

Other researchers should use their own reproducible
environments or a future lab-managed software stack.

## Submit a GPU Batch Job

A validated script is included in this repository:

`scripts/gpu-smoke.sbatch`

Submit it:

```bash
cd ~/hpc-handbook
sbatch scripts/gpu-smoke.sbatch
```

Check the queue:

```bash
squeue -u "$USER"
```

Inspect standard output and error logs:

```bash
cat /scratch/huawei/slurm-logs/gpu-smoke-<JOB_ID>.out
cat /scratch/huawei/slurm-logs/gpu-smoke-<JOB_ID>.err
```

Replace `<JOB_ID>` with the job identifier returned
by sbatch.

The sample script currently contains an absolute path
to the original validated Python environment and a
user-specific log directory.

Adapt these paths before using it from another account
or on another compute node.

## Validated CUDA Workload

The GPU smoke test performs:

1. CUDA availability verification.
2. GPU device identification.
3. Allocation of FP16 CUDA tensors.
4. A 2048 x 2048 matrix multiplication.
5. CUDA synchronization.
6. Result finiteness verification.
7. GPU memory reporting.

Successful execution prints:

```text
GPU COMPUTATION SUCCESS
```

Observed validation results:

| Job | Result | Elapsed matrix operation |
|---|---|---|
| 8 | PASS | 0.1148 seconds |
| 11 | PASS | 0.1143 seconds |

These are smoke-test timings, not standardized
performance benchmarks.

Timing includes measurement conditions specific to
the test script and should not be used for GPU
comparisons or capacity planning.

## Exclusive GPU Scheduling

Node01 has one GPU GRES resource.

Two jobs independently requesting `--gres=gpu:1`
should not run concurrently under normal Slurm
resource scheduling.

This behavior was validated using:

`scripts/gpu-queue.sbatch`

Observed execution:

| Job | Start | Finish |
|---|---|---|
| 9 | 23:35:43 | 23:37:13 |
| 10 | 23:37:43 | 23:37:48 |

Both jobs were assigned GPU 0.

Their execution intervals did not overlap.

There was a 30-second interval between the end
of Job 9 and the beginning of Job 10.

This interval is an observation, not a guaranteed
or required scheduling delay.

The queue test reserves the GPU but does not
perform a sustained CUDA workload.

## GPU Isolation Limitations

Current cgroup configuration:

```ini
ConstrainDevices=no
```

This means that the GPU is scheduled exclusively
among cooperating Slurm jobs, but device access
is not restricted against non-Slurm processes.

For example, another process launched directly
on the Ubuntu host may still use the RTX 5080.

The Ubuntu graphical desktop also shares this GPU.

GPU device containment requires a separate
compatibility and operations review before
changing ConstrainDevices.

Do not assume that CUDA_VISIBLE_DEVICES alone
enforces exclusive access.

## Monitoring

Check GPU information:

```bash
nvidia-smi
```

Show utilization and memory:

```bash
nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total \
  --format=csv
```

Show active Slurm jobs:

```bash
squeue
```

Show node resource configuration:

```bash
scontrol show node yelab-node01
```

nvidia-smi reports activity on the physical GPU,
including processes not managed by Slurm.

## Research Workload Guidance

Use Slurm for GPU-intensive research workloads.

Keep project source code and reusable outputs
in appropriately managed project directories.

Use scratch space for temporary computation data.

Do not treat node-local scratch storage as a backup.

The current default partition is debug, with a
one-hour time limit.

Long-running research partitions and scheduling
policies have not yet been established.

## Known Limitations

- Only one GPU is installed on Node01.
- GPU device access restrictions are not enabled.
- Persistent Slurm accounting is not installed.
- Host desktop applications may compete for GPU memory.
- The Windows VM consumes host CPU and RAM resources.
- The test Python environment is user-specific.
- Multi-node GPU scheduling has not yet been validated.

## Future Work

- Standardized Python and CUDA environments
- Shared research job templates
- Production GPU partition and scheduling policies
- GPU health monitoring
- Persistent job accounting
- Multi-node GRES deployment
- Automated regression tests after driver upgrades
