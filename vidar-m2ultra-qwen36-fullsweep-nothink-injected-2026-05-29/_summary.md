# luce-bench sweep — vidar-m2ultra-qwen36-fullsweep-nothink-injected-2026-05-29

- url:   `http://vidar:1237`
- model: `Qwen3.6-27B-MLX-8bit`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 2 | 66.7% | 25s | 0.9s |
| ds4-eval | 92 | 68 | 73.9% | 17067s | 99.2s |
| gsm8k | 100 | 93 | 93.0% | 2542s | 19.1s |
| truthfulqa-mc1 | 100 | 82 | 82.0% | 146s | 1.4s |
| hellaswag | 100 | 90 | 90.0% | 203s | 2.2s |
| code | 10 | 8 | 80.0% | 37s | 3.2s |
| longctx | 6 | 6 | 100.0% | 463s | 41.5s |
| agent | 4 | 3 | 75.0% | 112s | 26.6s |
| agent_recorded | 26 | 7 | 26.9% | 987s | 22.9s |
| forge | 30 | 0 | 0.0% | 761s | 19.5s |
