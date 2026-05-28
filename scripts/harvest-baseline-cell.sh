#!/usr/bin/env bash
# Harvest the baseline cell (tq3_0 / Q4_K_M / pflash=off) from the
# in-flight quality-sweep dir into a per-cell dir matching the other
# cells in the matrix. Hard-links the per-area JSON + the props/command
# snapshots so disk usage doesn't double.

set -euo pipefail

SRC="/tmp/luce-bench-baselines/sindri-rtx3090ti-qwen36-27b-tuned-quality-sweep-nothink-2026-05-28"
DST="/tmp/luce-bench-baselines/sindri-rtx3090ti-qwen36-quality-tq3_0-Q4_K_M-off-2026-05-28"

[ -d "$SRC" ] || { echo "src not found: $SRC" >&2; exit 1; }
[ -e "$SRC/ds4-eval.json" ] || { echo "src ds4-eval.json missing — sweep hasn't completed ds4-eval yet" >&2; exit 2; }

mkdir -p "$DST"

# Hard-link the result + supporting files. ln -f is idempotent.
ln -f "$SRC/ds4-eval.json"   "$DST/ds4-eval.json"
ln -f "$SRC/props.json"      "$DST/props.json"
ln -f "$SRC/command.sh"      "$DST/command.sh"
# bench.stdout for THIS cell includes lines for OTHER areas too — copy
# the relevant slice for provenance.
awk '/=== area=ds4-eval/{flag=1} /area=ds4-eval pass_rate=/{print; flag=0; next} flag' \
    "$SRC/bench.stdout" > "$DST/bench.stdout"

# README pointing back to the source for the full sweep.
cat > "$DST/README.md" <<EOF
# Quality-grading baseline cell (tq3_0 KV / Qwen3.6-27B-Q4_K_M / pflash=off)

This cell is **harvested** from the broader \`--areas all\` sweep at
\`$SRC\`. The ds4-eval portion of that sweep was run with the exact
config that the rest of this matrix calls the baseline:

- KV cache:   tq3_0 (server default; \`DFLASH_CACHE_TYPE_K=\`)
- target:     Qwen3.6-27B-Q4_K_M.gguf
- drafter:    dflash-draft-3.6-q4_k_m.gguf (DFlash ON)
- pflash:     off
- max_ctx:    65536
- ddtree:     budget=16
- nothink

\`ds4-eval.json\`, \`props.json\`, and \`command.sh\` are hard-linked
from the source dir; \`bench.stdout\` is a slice of the area=ds4-eval
section of the source bench.stdout.

Source dir holds the other 8 areas (smoke / gsm8k / truthfulqa-mc1 /
hellaswag / code / longctx / agent / agent_recorded / forge).
EOF

echo "[harvest] wrote $DST"
ls -la "$DST"
