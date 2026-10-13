#!/bin/bash
#SBATCH --job-name=gpu-smoke
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2048M
#SBATCH --gres=gpu:1
#SBATCH --time=00:05:00
#SBATCH --output=/scratch/huawei/slurm-logs/%x-%j.out
#SBATCH --error=/scratch/huawei/slurm-logs/%x-%j.err

set -euo pipefail

echo "================================"
echo "Ye Lab HPC - GPU Smoke Test"
echo "================================"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES:-unset}"

echo
echo "===== CPU AFFINITY ====="
grep Cpus_allowed_list /proc/self/status

echo
echo "===== GPU ====="
nvidia-smi --query-gpu=name,memory.total,driver_version \
    --format=csv

echo
echo "===== PYTORCH CUDA TEST ====="

/home/huawei/hpc-tests/gpu-smoke/.venv/bin/python -u - <<'PY'
import time
import torch

print("PyTorch:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())

assert torch.cuda.is_available(), "CUDA unavailable!"

device = torch.device("cuda:0")
print("GPU:", torch.cuda.get_device_name(0))
print("Compute capability:", torch.cuda.get_device_capability(0))

# Small FP16 GPU matrix multiplication
N = 2048

a = torch.rand((N, N), device=device, dtype=torch.float16)
b = torch.rand((N, N), device=device, dtype=torch.float16)

torch.cuda.synchronize()
start = time.perf_counter()

result = torch.matmul(a, b)

torch.cuda.synchronize()
elapsed = time.perf_counter() - start

assert torch.isfinite(result).all().item()

print("Matrix size:", N, "x", N)
print("Elapsed:", round(elapsed, 4), "seconds")
print("Result mean:", result.float().mean().item())
print("Peak VRAM:", round(torch.cuda.max_memory_allocated() / 1024**2, 2), "MiB")

print("GPU COMPUTATION SUCCESS")
PY
