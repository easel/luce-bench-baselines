#!/usr/bin/env bash
# Reproduces bragi-rtx5090laptop-gsm8k-2026-05-28-2026-05-28 on 2026-05-28T04:31:00Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    http://bragi:8080 \
    --model \
    dflash \
    --areas \
    gsm8k \
    --json-out \
    /tmp/luce-bench-baselines/bragi-rtx5090laptop-gsm8k-2026-05-28-2026-05-28/result.json \

