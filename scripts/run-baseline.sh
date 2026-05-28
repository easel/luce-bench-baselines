#!/usr/bin/env bash
# scripts/run-baseline.sh — Run luce-bench against a server and capture the
# snapshot in this repo using the canonical
# `<host>-<gpu>-<label>-<date>/` directory format.
#
# luce-bench is fetched on demand via uvx from the easel fork
# (feat/lucebox-docker until luce-bench lands on main). The host and GPU
# slug are auto-detected so most runs reduce to:
#
#   scripts/run-baseline.sh \
#       --url http://localhost:8080 \
#       --api-model dflash \
#       --label qwen36-nothink-ds4eval
#
# That produces e.g.
#   sindri-rtx3090ti-qwen36-nothink-ds4eval-2026-05-27/
#     result.json     # JSON rows the bench wrote
#     bench.stdout    # captured stdout
#     bench.stderr    # captured stderr
#     props.json      # /props snapshot at run start (lucebox servers only)
#     command.sh      # the exact uvx invocation, for reproducibility
#
# After it lands the snapshot, you commit + push manually:
#   cd luce-bench-baselines
#   git add <new-dir> && git commit -m "..." && git push

set -euo pipefail

# --- pin: ref of easel/lucebox-hub that luce-bench is pulled from ----------
# Switch to `main` once the feat/lucebox-docker PR merges.
DEFAULT_REF="feat/lucebox-docker"

usage() {
    cat <<EOF
Usage: $(basename "$0") --url URL --api-model M --label LABEL [opts]

Required:
  --url URL              Server base URL (e.g. http://localhost:8080
                         or https://openrouter.ai/api).
  --api-model NAME       Model id sent to the server in the request body
                         (e.g. \`dflash\`, \`qwen/qwen3.6-27b\`).
  --label LABEL          Free-form trailing slug for the directory name
                         (e.g. \`qwen36-nothink-ds4eval\`,
                         \`gemma4-26b-think-forge\`).

Layout (auto-detected unless overridden):
  --host NAME            Host slug (default: \$(hostname -s), lowercased)
  --gpu SLUG             GPU slug (default: derived from nvidia-smi or
                         \`unknown\` if missing)
  --date YYYY-MM-DD      Run date (default: today, UTC)

Bench options (pass-through to luce-bench):
  --areas LIST           Default: ds4-eval. Use \`all\` for the full
                         sweep (lucebench writes per-area JSON files +
                         a _summary.md into the run dir instead of
                         result.json).
  --think                Set thinking mode on (omit for nothink).
  --auth-env NAME        Env var holding the auth token (e.g.
                         OPENROUTER_API_KEY).
  --questions N          Limit each area to N questions (smoke runs).
  --timeout N            Per-request timeout in seconds.
  --parallel N           Parallel request count (only for stateless
                         gateways like OpenRouter).

Plumbing:
  --ref REF              Git ref of easel/lucebox-hub to pull luce-bench
                         from (default: $DEFAULT_REF).
  --baselines-dir DIR    Where to drop the snapshot (default: this repo's
                         root, resolved from \$0).
  --dry-run              Print the resolved dir + command, don't execute.
  -h | --help            This message.

Everything after \`--\` is appended to the luce-bench argv verbatim.
EOF
}

# --- arg parsing -----------------------------------------------------------
URL=""
API_MODEL=""
LABEL=""
HOST_OVERRIDE=""
GPU_OVERRIDE=""
DATE_OVERRIDE=""
AREAS="ds4-eval"
THINK=0
AUTH_ENV=""
QUESTIONS=""
TIMEOUT=""
PARALLEL=""
REF="$DEFAULT_REF"
BASELINES_DIR=""
DRY_RUN=0
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --url) URL="$2"; shift 2 ;;
        --api-model) API_MODEL="$2"; shift 2 ;;
        --label) LABEL="$2"; shift 2 ;;
        --host) HOST_OVERRIDE="$2"; shift 2 ;;
        --gpu) GPU_OVERRIDE="$2"; shift 2 ;;
        --date) DATE_OVERRIDE="$2"; shift 2 ;;
        --areas) AREAS="$2"; shift 2 ;;
        --think) THINK=1; shift ;;
        --auth-env) AUTH_ENV="$2"; shift 2 ;;
        --questions) QUESTIONS="$2"; shift 2 ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        --parallel) PARALLEL="$2"; shift 2 ;;
        --ref) REF="$2"; shift 2 ;;
        --baselines-dir) BASELINES_DIR="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; EXTRA_ARGS+=("$@"); break ;;
        *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[ -n "$URL" ]       || { echo "--url is required" >&2; exit 2; }
[ -n "$API_MODEL" ] || { echo "--api-model is required" >&2; exit 2; }
[ -n "$LABEL" ]     || { echo "--label is required" >&2; exit 2; }

# --- auto-detect: host, gpu, date, baselines_dir ---------------------------
if [ -z "$HOST_OVERRIDE" ]; then
    HOST_OVERRIDE="$(hostname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')"
fi
if [ -z "$GPU_OVERRIDE" ]; then
    if command -v nvidia-smi &>/dev/null; then
        # First GPU's name, sluggified: lowercase, alnum-only.
        raw=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "")
        # "NVIDIA GeForce RTX 3090 Ti" → "rtx3090ti"
        GPU_OVERRIDE=$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' \
            | sed 's/nvidia geforce //;s/[[:space:]]//g;s/-//g')
    fi
    [ -n "$GPU_OVERRIDE" ] || GPU_OVERRIDE="unknown"
fi
if [ -z "$DATE_OVERRIDE" ]; then
    DATE_OVERRIDE="$(date -u +%Y-%m-%d)"
fi
if [ -z "$BASELINES_DIR" ]; then
    BASELINES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

DIR_NAME="${HOST_OVERRIDE}-${GPU_OVERRIDE}-${LABEL}-${DATE_OVERRIDE}"
RUN_DIR="${BASELINES_DIR}/${DIR_NAME}"

# --- compose the luce-bench argv -------------------------------------------
UVX_FROM="git+https://github.com/easel/lucebox-hub@${REF}#subdirectory=luce-bench"

LB_ARGS=(
    --base-url "$URL"
    --model "$API_MODEL"
    --areas "$AREAS"
)
[ "$THINK" = "1" ]      && LB_ARGS+=(--think)
[ -n "$AUTH_ENV" ]      && LB_ARGS+=(--auth-env "$AUTH_ENV")
[ -n "$QUESTIONS" ]     && LB_ARGS+=(--questions "$QUESTIONS")
[ -n "$TIMEOUT" ]       && LB_ARGS+=(--timeout "$TIMEOUT")
[ -n "$PARALLEL" ]      && LB_ARGS+=(--parallel "$PARALLEL")

# Layout choice: `--areas all` is a sweep → write the per-area JSON
# files + _summary.md into a named subdir of out-dir, which IS our run
# dir. Any other --areas value is a single-area run → emit one
# result.json directly into the run dir.
if [ "$AREAS" = "all" ]; then
    LB_ARGS+=(--name "$DIR_NAME" --out-dir "$BASELINES_DIR")
    # Sweep mode wants $BASELINES_DIR/$DIR_NAME/ to be writable; let
    # luce-bench create it so it owns the layout.
else
    mkdir -p "$RUN_DIR"
    LB_ARGS+=(--json-out "$RUN_DIR/result.json")
fi
LB_ARGS+=("${EXTRA_ARGS[@]}")

echo "[run-baseline] dir   : $RUN_DIR"
echo "[run-baseline] ref   : $REF"
echo "[run-baseline] argv  : luce-bench ${LB_ARGS[*]}"

if [ "$DRY_RUN" = "1" ]; then
    echo "(dry-run; not executing)"
    exit 0
fi

mkdir -p "$RUN_DIR"

# Snapshot the server's /props endpoint at run start (no-op on
# OpenRouter / vLLM which don't expose it). Keeps the bench result
# correlated with the exact server config we hit.
if command -v curl &>/dev/null; then
    curl --max-time 5 -sf "${URL%/}/props" -o "$RUN_DIR/props.json" 2>/dev/null \
        || rm -f "$RUN_DIR/props.json"
fi

# Capture the exact command for reproducibility — handy when re-running
# against a different ref / model later.
{
    echo "#!/usr/bin/env bash"
    echo "# Reproduces $DIR_NAME on $(date -u +%FT%TZ)"
    printf 'uvx --refresh --from %q luce-bench \\\n' "$UVX_FROM"
    for arg in "${LB_ARGS[@]}"; do
        printf '    %q \\\n' "$arg"
    done
    echo
} > "$RUN_DIR/command.sh"
chmod +x "$RUN_DIR/command.sh"

# Run. Tee both streams so the user sees live progress AND we capture
# them to disk for the snapshot.
uvx --refresh --from "$UVX_FROM" luce-bench "${LB_ARGS[@]}" \
    > >(tee "$RUN_DIR/bench.stdout") \
    2> >(tee "$RUN_DIR/bench.stderr" >&2)

echo
echo "[run-baseline] done: $RUN_DIR"
echo "[run-baseline] next: cd $BASELINES_DIR && git add $DIR_NAME && git commit && git push"
