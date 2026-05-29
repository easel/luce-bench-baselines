#!/usr/bin/env bash
# Reproduces eitri-unknown-qwen36-fullsweep-verify-wsl-2026-05-29 on 2026-05-29T04:40:12Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    http://bragi:8080 \
    --model \
    dflash \
    --areas \
    all \
    --no-think \
    --name \
    eitri-unknown-qwen36-fullsweep-verify-wsl-2026-05-29 \
    --out-dir \
    /Users/erik/Projects/luce-bench-baselines \

