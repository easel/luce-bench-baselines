# luce-bench sweep — openrouter-cloud-qwen36-fullsweep-think-2026-05-29

- url:   `https://openrouter.ai/api`
- model: `qwen/qwen3.6-27b`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 3 | 100.0% | 97s | 6.2s |
| ds4-eval | 92 | 45 | 48.9% | 25651s | 205.8s |
| gsm8k | 100 | 77 | 77.0% | 4284s | 27.5s |
| truthfulqa-mc1 | 100 | 51 | 51.0% | 1434s | 8.5s |
| hellaswag | 100 | 34 | 34.0% | 757s | 4.0s |
| code | 10 | 2 | 20.0% | 356s | 34.1s |
| longctx | 6 | 2 | 33.3% | 100s | 7.4s |
| agent | 4 | 3 | 75.0% | 37s | 4.1s |
| agent_recorded | 26 | 10 | 38.5% | 1879s | 41.2s |
| forge | 30 | 0 | 0.0% | 410s | 10.1s |
