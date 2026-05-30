# luce-bench sweep — bragi-rtx5090laptop-qwen36-27b-autotune-nothink-2026-05-30

- url:   `http://localhost:8080`
- model: `dflash`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 3 | 100.0% | 1s | 0.1s |
| ds4-eval | 92 | 65 | 70.7% | 12352s | 68.1s |
| gsm8k | 100 | 89 | 89.0% | 1722s | 13.9s |
| truthfulqa-mc1 | 100 | 80 | 80.0% | 26s | 0.3s |
| hellaswag | 100 | 90 | 90.0% | 40s | 0.5s |
| code | 10 | 8 | 80.0% | 16s | 1.4s |
| longctx | 6 | 6 | 100.0% | 241s | 18.6s |
| agent | 4 | 3 | 75.0% | 30s | 6.3s |
| agent_recorded | 26 | 11 | 42.3% | 905s | 34.7s |
| forge | 30 | 0 | 0.0% | 87s | 2.3s |
