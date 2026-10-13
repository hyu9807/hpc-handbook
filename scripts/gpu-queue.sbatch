#!/usr/bin/env bash
#SBATCH --job-name=gpu-queue
#SBATCH --partition=debug
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=512M
#SBATCH --gres=gpu:1
#SBATCH --time=00:03:00
#SBATCH --output=/scratch/huawei/slurm-logs/gpu-queue-%j.out

set -euo pipefail

echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "GPU: $CUDA_VISIBLE_DEVICES"
echo "Start: $(date -Is)"

sleep "${HOLD_SECONDS:-10}"

echo "Finish: $(date -Is)"
