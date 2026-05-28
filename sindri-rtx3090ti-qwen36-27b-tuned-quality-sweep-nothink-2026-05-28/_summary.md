# luce-bench sweep — sindri-rtx3090ti-qwen36-27b-tuned-quality-sweep-nothink-2026-05-28

- url:   `http://localhost:8080`
- model: `dflash`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 3 | 100.0% | 1s | 0.2s |
| ds4-eval | 92 | 71 | 77.2% | 18663s | 117.0s |
| gsm8k | 100 | 87 | 87.0% | 2411s | 19.5s |
| truthfulqa-mc1 | 100 | 79 | 79.0% | 40s | 0.4s |
| hellaswag | 100 | 85 | 85.0% | 66s | 0.7s |
| code | 10 | 9 | 90.0% | 30s | 2.7s |
| longctx | 6 | 6 | 100.0% | 421s | 33.4s |
| agent | 4 | 3 | 75.0% | 95s | 21.4s |
| agent_recorded | 26 | 4 | 15.4% | 1670s | 63.7s |
| forge | 30 | 0 | 0.0% | 142s | 3.6s |
