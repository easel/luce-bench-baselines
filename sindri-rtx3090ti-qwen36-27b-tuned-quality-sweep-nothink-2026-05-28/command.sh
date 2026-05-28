#!/usr/bin/env bash
# Reproduces sindri-rtx3090ti-qwen36-27b-tuned-quality-sweep-nothink-2026-05-28 on 2026-05-28T12:55:28Z
uvx --refresh --from git+https://github.com/easel/lucebox-hub@feat/lucebox-docker#subdirectory=luce-bench luce-bench \
    --base-url \
    http://localhost:8080 \
    --model \
    dflash \
    --areas \
    all \
    --name \
    sindri-rtx3090ti-qwen36-27b-tuned-quality-sweep-nothink-2026-05-28 \
    --out-dir \
    /tmp/luce-bench-baselines \
    --no-think \

