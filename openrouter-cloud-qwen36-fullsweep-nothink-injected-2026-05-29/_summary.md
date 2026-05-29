# luce-bench sweep — openrouter-cloud-qwen36-fullsweep-nothink-injected-2026-05-29

- url:   `https://openrouter.ai/api`
- model: `qwen/qwen3.6-27b`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 3 | 100.0% | 2s | 0.9s |
| ds4-eval | 92 | 67 | 72.8% | 8687s | 47.1s |
| gsm8k | 100 | 93 | 93.0% | 1097s | 6.8s |
| truthfulqa-mc1 | 100 | 80 | 80.0% | 209s | 1.1s |
| hellaswag | 100 | 86 | 86.0% | 175s | 1.1s |
| code | 10 | 9 | 90.0% | 33s | 1.3s |
| longctx | 6 | 6 | 100.0% | 49s | 7.4s |
| agent | 4 | 2 | 50.0% | 32s | 8.6s |
| agent_recorded | 26 | 8 | 30.8% | 476s | 11.7s |
| forge | 30 | 0 | 0.0% | 260s | 3.6s |
