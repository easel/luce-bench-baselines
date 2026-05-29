#!/usr/bin/env bash
# Reproduces vidar-m2ultra-qwen3.6-27b-mlx8bit-ds4eval-nothink-2026-05-27 on 2026-05-28T02:56:21Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    http://vidar:1237 \
    --model \
    Qwen3.6-27B-MLX-8bit \
    --areas \
    ds4-eval \
    --no-think \
    --timeout \
    600 \
    --json-out \
    /Users/erik/Projects/luce-bench-baselines/vidar-m2ultra-qwen3.6-27b-mlx8bit-ds4eval-nothink-2026-05-27/result.json \

