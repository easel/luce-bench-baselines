#!/usr/bin/env bash
# run-quality-cell.sh — start a lucebox container with custom DFLASH_*
# env, sanity-check /props, then run a ds4-eval-92 nothink baseline.
#
# Usage:
#   scripts/run-quality-cell.sh \
#       --label kv-target-pflash-slug \
#       --target /home/erik/.local/share/lucebox/models/Qwen3.6-27B-Q4_K_M.gguf \
#       --kv tq3_0|q8_0|f16 \
#       --pflash off|auto \
#       [--max-ctx 65536]
#
# Container is named `lucebox`; we forcibly `docker rm -f lucebox`
# before starting (assumes the caller has already waited for the
# previous workload to finish).

set -euo pipefail

IMAGE="ghcr.io/luce-org/lucebox-hub:cuda12"
CONTAINER="lucebox"
MODELS_DIR="/home/erik/.local/share/lucebox/models"
PORT=8080
BASELINES_DIR="/tmp/luce-bench-baselines"

LABEL=""
TARGET=""
KV=""
PFLASH="off"
MAX_CTX="65536"

while [ $# -gt 0 ]; do
    case "$1" in
        --label)    LABEL="$2"; shift 2 ;;
        --target)   TARGET="$2"; shift 2 ;;
        --kv)       KV="$2"; shift 2 ;;
        --pflash)   PFLASH="$2"; shift 2 ;;
        --max-ctx)  MAX_CTX="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

[ -n "$LABEL" ]  || { echo "--label required" >&2; exit 2; }
[ -n "$TARGET" ] || { echo "--target required" >&2; exit 2; }
[ -n "$KV" ]     || { echo "--kv required" >&2; exit 2; }

# Map "tq3_0" -> "" (empty triggers server default, which IS tq3_0; the
# decode-tuning sweep specifically said tq3_0 is the heuristic default
# and benchmarked fastest exactly with empty envs).
KV_ENV="$KV"
if [ "$KV" = "tq3_0" ]; then
    KV_ENV=""
fi

TARGET_CONT="/opt/lucebox-hub/server/models/$(basename "$TARGET")"
DRAFT_CONT="/opt/lucebox-hub/server/models/draft/dflash-draft-3.6-q4_k_m.gguf"

echo "[cell] label=$LABEL  target=$(basename "$TARGET")  kv=$KV  pflash=$PFLASH  max_ctx=$MAX_CTX"

# 1) Stop any existing container, wait for VRAM to drop.
echo "[cell] stopping existing $CONTAINER (if any)"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
for i in 1 2 3 4 5 6 7 8 9 10; do
    mem_mib=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1 | tr -d ' ')
    if [ "${mem_mib:-99999}" -lt 3000 ]; then
        echo "[cell] GPU mem=${mem_mib}MiB, ready"
        break
    fi
    echo "[cell] GPU mem=${mem_mib}MiB, waiting..."
    sleep 3
done

# 2) Launch container with the cell's envs.
echo "[cell] starting container"
docker run -d \
    --name "$CONTAINER" \
    --gpus all \
    -p "${PORT}:8080" \
    -v "${MODELS_DIR}:/opt/lucebox-hub/server/models" \
    -v /home/erik:/home/erik \
    -e DFLASH_BUDGET=16 \
    -e DFLASH_MAX_CTX="$MAX_CTX" \
    -e DFLASH_PREFIX_CACHE_SLOTS=0 \
    -e DFLASH_PREFILL_CACHE_SLOTS=0 \
    -e DFLASH_THINK_MAX=15488 \
    -e DFLASH_PORT=8080 \
    -e DFLASH_LAZY=0 \
    -e DFLASH_TARGET="$TARGET_CONT" \
    -e DFLASH_DRAFT="$DRAFT_CONT" \
    -e DFLASH_CACHE_TYPE_K="$KV_ENV" \
    -e DFLASH_CACHE_TYPE_V="$KV_ENV" \
    -e DFLASH_PREFILL_MODE="$PFLASH" \
    "$IMAGE" >/dev/null

# 3) Wait for /v1/models (up to ~120s).
echo "[cell] waiting for /v1/models"
ok=0
for i in $(seq 1 60); do
    if curl -sf --max-time 3 "http://localhost:${PORT}/v1/models" >/dev/null 2>&1; then
        ok=1
        echo "[cell] server up after ${i}*2s"
        break
    fi
    # Check the container is still alive — fail fast on early crash
    # (e.g. OOM at load time).
    if ! docker ps -q -f "name=^${CONTAINER}$" | grep -q .; then
        echo "[cell] container died during startup (exit=$(docker inspect -f '{{.State.ExitCode}}' "$CONTAINER" 2>/dev/null))"
        docker logs --tail 200 "$CONTAINER" 2>&1 | tail -100 || true
        exit 99
    fi
    sleep 2
done
if [ "$ok" != "1" ]; then
    echo "[cell] timeout waiting for /v1/models"
    docker logs --tail 200 "$CONTAINER" 2>&1 | tail -100 || true
    exit 98
fi

# 4) Sanity-check /props — make sure runtime matches request.
PROPS=$(curl -sf --max-time 5 "http://localhost:${PORT}/props")
got_k=$(printf '%s' "$PROPS" | python3 -c 'import json,sys; p=json.load(sys.stdin); print(p["runtime"]["kv_cache_k"])')
got_v=$(printf '%s' "$PROPS" | python3 -c 'import json,sys; p=json.load(sys.stdin); print(p["runtime"]["kv_cache_v"])')
got_pf=$(printf '%s' "$PROPS" | python3 -c 'import json,sys; p=json.load(sys.stdin); print(p["pflash"]["mode"])')
got_target=$(printf '%s' "$PROPS" | python3 -c 'import json,sys; p=json.load(sys.stdin); print(p["model_path"])')

expected_target_base="$(basename "$TARGET")"
got_target_base="$(basename "$got_target")"

echo "[cell] /props runtime.kv_cache_k=$got_k  v=$got_v  pflash.mode=$got_pf  target=$got_target_base"

mismatch=0
if [ "$got_k" != "$KV" ] || [ "$got_v" != "$KV" ]; then
    echo "[cell] MISMATCH: expected KV=$KV, got K=$got_k V=$got_v"
    mismatch=1
fi
if [ "$got_pf" != "$PFLASH" ]; then
    echo "[cell] MISMATCH: expected pflash=$PFLASH, got $got_pf"
    mismatch=1
fi
if [ "$got_target_base" != "$expected_target_base" ]; then
    echo "[cell] MISMATCH: expected target=$expected_target_base, got $got_target_base"
    mismatch=1
fi
if [ "$mismatch" = "1" ]; then
    echo "[cell] ABORT: /props doesn't match requested config"
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    exit 97
fi

# 5) Run the bench (ds4-eval, nothink). Use run-baseline.sh so the
#    output dir lands canonically and includes props.json + command.sh.
#
#    Start a background VRAM peak poller (samples nvidia-smi at 5s).
DATE_UTC="$(date -u +%Y-%m-%d)"
RUN_DIR="${BASELINES_DIR}/sindri-rtx3090ti-${LABEL}-${DATE_UTC}"
mkdir -p "$RUN_DIR"

VRAM_LOG="${RUN_DIR}/vram_peak.log"
nvidia-smi --query-gpu=timestamp,memory.used,power.draw --format=csv,nounits \
    --loop=5 > "$VRAM_LOG" 2>&1 &
VRAM_PID=$!

echo "[cell] starting ds4-eval bench (vram poller pid=$VRAM_PID)"
cd "$BASELINES_DIR"
set +e
scripts/run-baseline.sh \
    --url "http://localhost:${PORT}" \
    --api-model dflash \
    --host sindri --gpu rtx3090ti \
    --label "$LABEL" \
    --areas ds4-eval \
    -- --no-think
BENCH_RC=$?
set -e

# Stop VRAM poller.
kill "$VRAM_PID" 2>/dev/null || true
wait "$VRAM_PID" 2>/dev/null || true

# 6) Drop the container to release VRAM for the next cell.
echo "[cell] stopping container (bench exited $BENCH_RC)"
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true

# 7) Compute peak VRAM from log, write to RUN_DIR/peak.txt.
if [ -s "$VRAM_LOG" ]; then
    peak=$(awk -F',' 'NR>1 {gsub(/ /,"",$2); if ($2+0>m) m=$2+0} END {print m}' "$VRAM_LOG")
    echo "[cell] VRAM peak: ${peak} MiB"
    echo "$peak" > "$RUN_DIR/vram_peak_mib.txt"
fi

echo "[cell] done  -> $RUN_DIR"
