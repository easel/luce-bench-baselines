#!/usr/bin/env bash
# Reproduces sindri-rtx3090ti-qwen36-fullsweep-nothink-2026-05-29 on 2026-05-29T05:17:24Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    http://sindri:8080 \
    --model \
    dflash \
    --areas \
    all \
    --no-think \
    --timeout \
    600 \
    --name \
    sindri-rtx3090ti-qwen36-fullsweep-nothink-2026-05-29 \
    --out-dir \
    /Users/erik/Projects/luce-bench-baselines \

