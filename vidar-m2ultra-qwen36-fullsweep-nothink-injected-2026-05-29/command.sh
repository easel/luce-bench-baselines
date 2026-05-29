#!/usr/bin/env bash
# Reproduces vidar-m2ultra-qwen36-fullsweep-nothink-injected-2026-05-29 on 2026-05-29T04:49:27Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    http://vidar:1237 \
    --model \
    Qwen3.6-27B-MLX-8bit \
    --areas \
    all \
    --no-think \
    --timeout \
    600 \
    --name \
    vidar-m2ultra-qwen36-fullsweep-nothink-injected-2026-05-29 \
    --out-dir \
    /Users/erik/Projects/luce-bench-baselines \
    --prompt-thinking-control \
    on \

