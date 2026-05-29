#!/usr/bin/env bash
# Reproduces openrouter-cloud-qwen36-fullsweep-nothink-injected-2026-05-29 on 2026-05-29T04:45:21Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    https://openrouter.ai/api \
    --model \
    qwen/qwen3.6-27b \
    --areas \
    all \
    --no-think \
    --auth-env \
    OPENROUTER_API_KEY \
    --timeout \
    600 \
    --parallel \
    4 \
    --name \
    openrouter-cloud-qwen36-fullsweep-nothink-injected-2026-05-29 \
    --out-dir \
    /Users/erik/Projects/luce-bench-baselines \
    --prompt-thinking-control \
    on \

