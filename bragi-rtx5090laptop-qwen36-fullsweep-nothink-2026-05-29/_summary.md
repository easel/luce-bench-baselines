# luce-bench sweep — eitri-unknown-qwen36-fullsweep-verify-wsl-2026-05-29

- url:   `http://bragi:8080`
- model: `dflash`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 2 | 66.7% | 4s | 0.2s |
| ds4-eval | 92 | 65 | 70.7% | 13075s | 82.8s |
| gsm8k | 100 | 88 | 88.0% | 1619s | 13.9s |
| truthfulqa-mc1 | 100 | 76 | 76.0% | 27s | 0.3s |
| hellaswag | 100 | 86 | 86.0% | 40s | 0.5s |
| code | 10 | 10 | 100.0% | 17s | 1.6s |
| longctx | 6 | 6 | 100.0% | 239s | 18.1s |
| agent | 4 | 4 | 100.0% | 108s | 13.7s |
| agent_recorded | 26 | 8 | 30.8% | 865s | 32.8s |
| forge | 30 | 0 | 0.0% | 86s | 2.3s |
