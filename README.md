# luce-bench-baselines

Reference snapshot data for [luce-bench](https://github.com/easel/luce-bench).
Each subdirectory is one sweep — per-area JSON rows plus a `_summary.json`
when the run went through the new `--sweep` path.

## Layout

```
<host>-<gpu>-<model>-<date>-<mode>/
  ds4eval.json | result.json      # per-area row data (luce-bench --sweep
                                  # uses {area}.json; older files use
                                  # ds4eval.json / result.json)
  run.log                         # capture of the bench's stdout
```

The naming convention is `<host>-<gpu>-<model>-<date>-<mode>`. `host`
is the machine that ran the sweep; `mode` is `think` / `nothink` /
`forge` / etc. For OpenRouter sweeps the host slot is just `openrouter`.

## What's here

Curated from luce-dflash's bench harness from 2026-05-24 through
2026-05-26. Three groups:

- **bragi (RTX 5090 Laptop, luce-dflash)** — qwen3.6, gemma-4-26b, laguna
- **openrouter** — same models for cross-provider comparison
- **forge tool-calling** — qwen3.6 and OR-hosted gemma + deepseek

Each row payload is the bench's standard ds4-eval-shaped dict:
`pass`, `wall_seconds`, `prompt_tokens`, `completion_tokens`, `content`,
`reasoning_content`, `finish_reason`, `timings` (when surfaced), etc.

## Using them

Diff your own sweep against a baseline:

```bash
luce-bench --sweep --name my-machine --base-url http://127.0.0.1:8000
git clone https://github.com/easel/luce-bench-baselines ../baselines
luce-bench-report ./snapshots/my-machine \
  ../baselines/bragi-rtx5090laptop-gemma4-26b-2026-05-25-ds4eval-think
```

## Attribution

Sweep data derives from running models on the bench fixtures vendored
by luce-bench. Upstream fixture licenses (all MIT) are reproduced in
`NOTICE`. The luce-bench code itself is Apache-2.0.
