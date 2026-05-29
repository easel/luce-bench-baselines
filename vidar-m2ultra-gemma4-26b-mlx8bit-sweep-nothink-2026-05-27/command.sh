#!/usr/bin/env bash
# Reproduces vidar-m2ultra-gemma4-26b-mlx8bit-sweep-nothink-2026-05-27 on 2026-05-28T00:32:10Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    http://vidar:1237 \
    --model \
    gemma-4-26B-A4B-it-MLX-8bit \
    --areas \
    all \
    --no-think \
    --timeout \
    600 \
    --name \
    vidar-m2ultra-gemma4-26b-mlx8bit-sweep-nothink-2026-05-27 \
    --out-dir \
    /Users/erik/Projects/luce-bench-baselines \

