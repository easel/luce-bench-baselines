#!/usr/bin/env bash
# queue-qwen36moe-on-sindri.sh
#
# One-shot queue script: wait for the currently-running 31b dflash_server
# bench on sindri to finish, then bring up a lucebox server pointed at the
# qwen3.6-moe preset (Qwen3.6-35B-A3B Q4_K_M, target-only — no DFlash MoE
# draft exists yet), wait for it to be ready, fire the full luce-bench
# sweep against it via scripts/run-baseline.sh, then stop the server.
#
# WHY:
#   sindri's GPU is currently saturated by a long-running gemma-4-31b
#   ds4-eval bench (PID 737737, ~16h+ in as of 2026-05-27). We don't want
#   to kill it. The user wants the qwen3.6-moe sweep to fire as soon as
#   the 31b run frees the GPU — this script is the "queue" piece.
#
# USAGE:
#   chmod +x scripts/queue-qwen36moe-on-sindri.sh
#   nohup ./scripts/queue-qwen36moe-on-sindri.sh \
#       > /tmp/queue-qwen36moe.log 2>&1 &
#
#   # Or to wait for a specific PID different from the default:
#   WAIT_PID=999999 ./scripts/queue-qwen36moe-on-sindri.sh
#
# ENV OVERRIDES:
#   WAIT_PID         PID to wait on (default: 737737 — the 31b dflash_server)
#   WAIT_FALLBACK    Process-name regex to also probe when WAIT_PID exits
#                    (default: dflash_server)
#   POLL_SEC         Seconds between WAIT_PID alive-checks (default: 60)
#   GGUF             Absolute path to the Qwen3.6 35B-A3B Q4_K_M GGUF
#                    (default: $XDG_DATA_HOME/lucebox/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf
#                    or ~/.local/share/lucebox/models/... if XDG unset)
#   PORT             Host port for the lucebox server (default: 1236)
#   READY_TIMEOUT_S  Max seconds to wait for /v1/models to return 200
#                    (default: 600 — MoE first load can be slow)
#   LABEL            Snapshot label slug (default: qwen36moe-sweep)
#   AREAS            luce-bench --areas value (default: all)
#   LUCEBOX_VARIANT  Container variant (default: cuda12)
#   DRY_RUN          1 = print steps + exit before launching server
#
# This script does NOT run the bench inline by default — it's safe to fire
# and forget; downloads + server bring-up happen here, and the bench runs
# the moment the GPU is free.

set -euo pipefail

# ── tunables ──────────────────────────────────────────────────────────────
WAIT_PID="${WAIT_PID:-737737}"
WAIT_FALLBACK="${WAIT_FALLBACK:-dflash_server}"
POLL_SEC="${POLL_SEC:-60}"

DEFAULT_MODELS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/lucebox/models"
GGUF="${GGUF:-$DEFAULT_MODELS_DIR/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf}"

PORT="${PORT:-1236}"
READY_TIMEOUT_S="${READY_TIMEOUT_S:-600}"
LABEL="${LABEL:-qwen36moe-sweep}"
AREAS="${AREAS:-all}"
export LUCEBOX_VARIANT="${LUCEBOX_VARIANT:-cuda12}"
DRY_RUN="${DRY_RUN:-0}"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUN_BASELINE="$REPO_DIR/scripts/run-baseline.sh"

log() { printf '[%(%FT%T%z)T] %s\n' -1 "$*"; }

# ── sanity ────────────────────────────────────────────────────────────────
[ -x "$RUN_BASELINE" ] || { echo "missing or non-exec: $RUN_BASELINE" >&2; exit 2; }
command -v curl >/dev/null      || { echo "curl is required"      >&2; exit 2; }
command -v lucebox >/dev/null   || { echo "lucebox CLI not on PATH" >&2; exit 2; }

log "config: WAIT_PID=$WAIT_PID POLL=${POLL_SEC}s GGUF=$GGUF PORT=$PORT"
log "config: LABEL=$LABEL AREAS=$AREAS LUCEBOX_VARIANT=$LUCEBOX_VARIANT"

if [ "$DRY_RUN" = "1" ]; then
    log "DRY_RUN=1 — exiting before any blocking work"
    exit 0
fi

# ── 1. wait for the running 31b bench to finish ──────────────────────────
# Use `kill -0 $pid` as the alive-check — sends signal 0 (no actual signal)
# and returns 0 iff the pid exists and we have permission to signal it.
# Idiomatic, race-free, and doesn't require parsing ps output.
log "waiting for PID $WAIT_PID (and any '$WAIT_FALLBACK' processes) to exit…"
while kill -0 "$WAIT_PID" 2>/dev/null; do
    sleep "$POLL_SEC"
done
log "PID $WAIT_PID has exited"

# Catch the case where the wait-pid died but a sibling/restart kept the
# GPU busy. Probe by name once and back off if anything matches.
while pgrep -f "$WAIT_FALLBACK" >/dev/null 2>&1; do
    log "still seeing '$WAIT_FALLBACK' processes — backing off ${POLL_SEC}s"
    sleep "$POLL_SEC"
done
log "no '$WAIT_FALLBACK' left running — GPU should be free"

# Small grace period: the dying server may still be releasing VRAM, and
# nvidia-smi sometimes lags by a few seconds. Cheap insurance.
sleep 10

# ── 2. configure lucebox for qwen3.6-moe ──────────────────────────────────
# `--overwrite` is safe here: this script is the canonical bring-up for the
# MoE sweep, and we want to be explicit about what's loaded.
log "writing .lucebox/config.toml for preset qwen3.6-moe"
lucebox configure --overwrite --preset qwen3.6-moe

# Make sure the GGUF is actually on disk. The download was kicked off
# separately (see lucebox-hub feat/lucebox-docker commit history); here we
# just refuse to start if it's missing.
if [ ! -f "$GGUF" ]; then
    log "ERROR: GGUF not found at $GGUF — pre-download did not complete"
    log "       hint: run 'lucebox download-models --preset qwen3.6-moe' first"
    exit 3
fi
gguf_size=$(stat -c%s "$GGUF")
log "GGUF present: $GGUF ($gguf_size bytes)"

# ── 3. start the lucebox server (background) ──────────────────────────────
LOG_DIR="${TMPDIR:-/tmp}/lucebox-qwen36moe"
mkdir -p "$LOG_DIR"
SERVE_LOG="$LOG_DIR/serve-$(date -u +%Y%m%dT%H%M%SZ).log"

log "launching 'lucebox serve' (variant=$LUCEBOX_VARIANT, log=$SERVE_LOG)"
# nohup + setsid so the server outlives this script if it crashes mid-run;
# we'll explicitly stop it at the end.
nohup setsid lucebox serve > "$SERVE_LOG" 2>&1 &
SERVE_PID=$!
log "lucebox serve PID=$SERVE_PID"

# Always try to bring the server down on exit, including failure paths.
cleanup() {
    log "stopping lucebox server (PID=$SERVE_PID)…"
    # The user-facing `lucebox stop` command tears down the docker
    # container cleanly; fall back to killing the wrapper if it's not
    # available (e.g. running under a different lucebox version).
    if command -v lucebox >/dev/null && lucebox stop >/dev/null 2>&1; then
        log "lucebox stop succeeded"
    else
        kill "$SERVE_PID" 2>/dev/null || true
        log "killed wrapper PID $SERVE_PID directly"
    fi
}
trap cleanup EXIT INT TERM

# ── 4. wait for /v1/models to return 200 ──────────────────────────────────
URL="http://127.0.0.1:$PORT"
log "waiting up to ${READY_TIMEOUT_S}s for $URL/v1/models to be ready…"
deadline=$(( $(date +%s) + READY_TIMEOUT_S ))
while [ "$(date +%s)" -lt "$deadline" ]; do
    if curl -fsS --max-time 5 "$URL/v1/models" >/dev/null 2>&1; then
        log "/v1/models is up"
        break
    fi
    if ! kill -0 "$SERVE_PID" 2>/dev/null; then
        log "ERROR: server process died before becoming ready — see $SERVE_LOG"
        exit 4
    fi
    sleep 5
done

if ! curl -fsS --max-time 5 "$URL/v1/models" >/dev/null 2>&1; then
    log "ERROR: server did not become ready within ${READY_TIMEOUT_S}s — see $SERVE_LOG"
    exit 5
fi

# ── 5. fire the bench sweep ───────────────────────────────────────────────
log "running luce-bench sweep against $URL (label=$LABEL areas=$AREAS)"
"$RUN_BASELINE" \
    --url "$URL" \
    --api-model dflash \
    --host sindri --gpu rtx3090ti \
    --label "$LABEL" \
    --areas "$AREAS"

log "bench complete — cleanup trap will stop the server"
exit 0
