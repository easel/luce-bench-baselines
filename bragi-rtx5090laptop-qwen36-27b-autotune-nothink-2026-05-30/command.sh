#!/usr/bin/env bash
# Reproduces bragi-rtx5090laptop-qwen36-27b-autotune-nothink-2026-05-30 on 2026-05-30T07:41:37Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    http://localhost:8080 \
    --model \
    dflash \
    --areas \
    all \
    --no-think \
    --name \
    bragi-rtx5090laptop-qwen36-27b-autotune-nothink-2026-05-30 \
    --out-dir \
    /home/erik/Projects/luce-bench-baselines \

