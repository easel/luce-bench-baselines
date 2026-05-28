# Qwen3.6-27B dense decode-tuning on sindri (RTX 3090 Ti, 24 GB, 225W)

Captured 2026-05-28 to investigate the user's reported "11-13 tok/s" baseline
versus club-3090's reported "52-60 tok/s". Power limit held at 225 W
throughout — not changed.

## Result

The current heuristic config (`budget=16, max_ctx=65536, lazy=true,
cache_type=tq3_0 default`) **already lands at ~50 tok/s decode** —
matching club-3090. The earlier "11-13 tok/s" figure looks like a
measurement artifact, not a hardware/tuning gap.

DFlash on vs off: **51 tok/s vs 20 tok/s**, ~2.5x speculative speedup.

## Layout

- `step0-control/` — DFlash on, default heuristic config. **51.07 tok/s**.
- `step0-dflashOFF/` — same config minus draft (AR floor). 20.47 tok/s.
- `sweep1-kv-budget-lazy/` — DFlash budget × KV quant × lazy.
- `sweep2-ctx-prefill/` — winning DFlash config × max-ctx × PFlash mode.
- `sweep3-quant/` — winning DFlash config × target GGUF variant.

Each cell directory holds:
- `props.json`     — `/props` snapshot post-startup.
- `probe.jsonl`    — per-probe `usage.timings` (3 prompts × 256 max-tokens).
- `summary.json`   — mean decode tok/s, ok-count, VRAM peak.
- `docker.stderr`  — server stderr (load + per-probe spec-decode telemetry).

## Findings

### Winner (Step 1 sweep)

```
DFLASH_BUDGET=16
DFLASH_MAX_CTX=65536   # 32k-98k all comparable; pick on VRAM headroom
DFLASH_LAZY=1          # ignored by binary unless prefill-drafter set
                       # (see entrypoint bug note below)
DFLASH_CACHE_TYPE_K="" # empty -> server default tq3_0 (the fastest)
DFLASH_CACHE_TYPE_V=""
DFLASH_PREFILL_MODE=off
DFLASH_TARGET=Qwen3.6-27B-Q4_K_M.gguf
DFLASH_DRAFT=draft/dflash-draft-3.6-q4_k_m.gguf
```

→ **51.07 tok/s** mean over 3 probes, 20723 MiB peak VRAM.

### Sweep 1 (budget × KV × lazy, ctx=65k, pfoff)

| budget | KV     | lazy | decode tok/s | VRAM MiB |
|--------|--------|------|--------------|----------|
| 16     | tq3_0  | 0    | **51.07**    | 20723    |
| 16     | tq3_0  | 1    | 47.33        | 20723    |
| 22     | tq3_0  | 0    | 44.13        | 21167    |
| 32     | tq3_0  | 0    | 42.17        | 21905    |
| 16     | q4_0   | 0    | 37.33        | 20929    |
| 16     | q8_0   | 0    | 35.30        | 21953    |
| 22     | q8_0   | 0    | 28.20        | 22397    |
| 32     | q8_0   | 0    | 25.27        | 23135    |
| 8      | q8_0   | 0    | 34.30        | 21879    |

KV `tq3_0` decisively beats `q8_0` / `q4_0` (server is tuned for tq3_0).
Budget = 16 beats 8/22/32. Lazy effectively no-op (see bug below).

### Sweep 2 (ctx × prefill, budget=16/tq3/lazy=0)

| ctx    | prefill | decode tok/s | VRAM MiB |
|--------|---------|--------------|----------|
| 32768  | off     | 36.67        | 20275    |
| 32768  | auto    | 48.00        | 19299    |
| 65536  | off     | 35.50        | 20723    |
| 65536  | auto    | 44.03        | 19747    |
| 98304  | off     | 40.20        | 21171    |

ctx between 32k and 98k makes no real difference for short prompts.
`prefill=auto` shows a modest improvement, but our prompts are 30-40
tokens (below the 8k threshold), so the gain is mostly variance.

### Sweep 3 (model-quant, winning DFlash config)

| quant   | decode tok/s | VRAM MiB |
|---------|--------------|----------|
| Q4_K_M  | 48.60        | 20275    |
| Q5_K_M  | 34.40        | 22691    |
| IQ4_XS  | 48.27        | 18963    |

IQ4_XS = same speed as Q4_K_M, **1.3 GB less VRAM**. Q5_K_M is
20% slower because of bandwidth pressure (no headroom for KV anyway).

## Notes

### `lazy_draft` is dead-on-arrival without `--prefill-drafter`

Even when `DFLASH_LAZY=1` (heuristic default), `props.json` reports
`runtime.lazy_draft: false`. Server stderr explains:

```
[server] --lazy-draft ignored: requires both --prefill-drafter and --draft
```

The lucebox heuristic sets `lazy = true` without a prefill-drafter, so
the `--lazy-draft` flag is silently dropped. Likely intentional in the
binary (lazy-draft + dual-drafter design), but the lucebox heuristic
should either set lazy = false or warn.

### Entrypoint `set -u` bug

`server/scripts/entrypoint.sh` references `DRAFT_FAMILY_GLOB` in the
"draft directory resolution" branch (around line 247), but the variable
was renamed to `FAMILY_GLOBS` (array). The image's entrypoint dies under
`set -u` when both 27B and 35B GGUFs are present and the qwen3.6
dir-resolution path is hit. **Workaround used here**: pass
`DFLASH_TARGET` and `DFLASH_DRAFT` as explicit file paths. This is also
why all probe-cell runs include those overrides — the heuristic's
docker_run.server_run_spec does **not** set them, so a vanilla
`lucebox start` on this host hits the bug.

### Why the user's earlier baseline was 11-13 tok/s

We can't recover it definitively, but candidate causes:
- The 31b run on :1236 was hot/full GPU at the same time the dense bench
  was run; back-to-back probes against a saturated GPU would queue.
- The `dflash_server` default `--cache-type-{k,v} tq3_0` only kicks in
  when `max_ctx > 6144`. A shorter max_ctx would land on q4_0 KV (one of
  our slowest measured cells).
- Single-probe variance is 12-70 tok/s on this prompt mix; one
  unfortunate `probe 2`-style measurement could yield 11-13 tok/s.

## Step 3 (ds4-eval baselines) — deferred

Running `scripts/run-baseline.sh ... --areas ds4-eval` on both
qwen3.6-27b and the matched gemma-4-26b control would take ~3-6 hours
(92 cases × ~30-180 s each, two models). Not run in this session.
When run, both directories should pick up the winning config above:

```
DFLASH_BUDGET=16 DFLASH_MAX_CTX=65536 DFLASH_LAZY=0
DFLASH_CACHE_TYPE_K= DFLASH_CACHE_TYPE_V=
DFLASH_TARGET=/opt/lucebox-hub/server/models/Qwen3.6-27B-Q4_K_M.gguf
DFLASH_DRAFT=/opt/lucebox-hub/server/models/draft/dflash-draft-3.6-q4_k_m.gguf
```

## 31B gemma-4 snapshot preserved

The mid-run 67/92 ds4-eval-nothink output that was active when this
session started was copied to
`../sindri-rtx3090ti-gemma4-31b-2026-05-27-ds4eval-nothink-67of92-snapshot/`
before the chain was killed (SIGTERM → SIGKILL on the long-suffering
21h `dflash_server` pid 737737, after the python wrappers exited).
