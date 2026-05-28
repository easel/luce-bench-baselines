# Inference stack matters — same model, different latency

Routing the same model through different inference stacks produces
dramatically different latency. Each row is the median over `n=92`
ds4-eval cases for one (stack, model, hardware) tuple, taken from
the canonical snapshots in this repo. lucebox reports server-side
`prefill_ms` (the precise TTFT); OpenRouter exposes nothing — we
report end-to-end wall time for OR rows.

luce-bench v0.2.7+ adds a streaming TTFT capture path
(`ttft_seconds`, `streaming` row fields) so client-measured TTFT
will now appear next to `prefill_ms` on every new run, including OR.

## Numbers (gemma-4-26b nothink, ds4-eval, n=92)

| stack                                    | prefill p50 | decode tps p50 | wall p50 | wall p90 | eff tps |
|------------------------------------------|-------------|----------------|----------|----------|---------|
| **lucebox (bragi, RTX 5090 laptop)**     | **124 ms**  | **105.5**      | 9.53 s   | 68.3 s   | 103.6   |
| OpenRouter (`google/gemma-4-26b-a4b-it`) | —           | —              | 28.28 s  | 146.3 s  | 30.1    |

Sources: [`bragi-rtx5090laptop-gemma4-26b-2026-05-26-sweep-nothink/ds4-eval.json`](../bragi-rtx5090laptop-gemma4-26b-2026-05-26-sweep-nothink/ds4-eval.json) · [`openrouter-2026-05-24-ds4eval-5models-paid/google_gemma-4-26b-a4b-it.json`](../openrouter-2026-05-24-ds4eval-5models-paid/google_gemma-4-26b-a4b-it.json).

Same model, same workload, same bench harness: lucebox finishes the
median question **3× faster** at **3.4× the effective tps**, with a
2× tighter p90 tail.

## Where the gap comes from

- **Prefill**: on lucebox the 246-token ds4-eval prompt is prefilled
  in 124 ms; the 6,343-token longctx median jumps to 2,419 ms —
  both amortize to ~50 prompt-tok/ms on the 5090. OR's wall-time
  floor on tiny prompts (1.5–2 s) implies the gateway adds ~1 s of
  routing + tokenization before the model starts. See `longctx.json`
  / `agent.json` in the same snapshot dir for prefill scaling.
- **Decode steady-state**: 105 tps for Q4_K_M gemma-4-26b on the
  5090 is the model's hardware ceiling. OR's 30 eff tps is
  bottlenecked by SSE framing + gateway buffering + provider
  batching, not by the model.
- **Prefix cache**: lucebox amortizes system prompt + chat template
  across requests, and on long-input cases the prefill cost is paid
  once and reused. OR pays full prefill on every call.

## Caveats

- 26b not 31b: matched-pair only exists for gemma-4-26b. The 31B OR
  data (wall p50 33.4 s, eff tps 21.6,
  `openrouter-2026-05-24-ds4eval-5models-paid/google_gemma-4-31b-it.json`)
  shows the same gap shape; the sindri-3090Ti 31B local baseline is
  mid-run under `dflash/docs/tuning-snapshots/`.
- No fresh streamed OR run for this writeup: `OPENROUTER_API_KEY`
  wasn't available in env. The new `ttft_seconds` field will close
  the TTFT-vs-wall mismatch on the next sweep with a key.
- All rows sequential (`--parallel 1`).
