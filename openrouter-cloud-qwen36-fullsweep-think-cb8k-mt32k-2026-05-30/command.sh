#!/usr/bin/env bash
# Reproduces openrouter-cloud-qwen36-fullsweep-think-cb8k-mt32k-2026-05-30 on 2026-05-30T02:23:45Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    https://openrouter.ai/api \
    --model \
    qwen/qwen3.6-27b \
    --areas \
    all \
    --think \
    --auth-env \
    OPENROUTER_API_KEY \
    --timeout \
    600 \
    --parallel \
    4 \
    --name \
    openrouter-cloud-qwen36-fullsweep-think-cb8k-mt32k-2026-05-30 \
    --out-dir \
    /Users/erik/Projects/luce-bench-baselines \
    --max-tokens \
    32000 \
    --client-thinking-budget \
    8000 \

