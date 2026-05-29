# luce-bench sweep — sindri-rtx3090ti-qwen36-fullsweep-nothink-2026-05-29

- url:   `http://sindri:8080`
- model: `dflash`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 3 | 100.0% | 1s | 0.2s |
| ds4-eval | 92 | 66 | 71.7% | 17271s | 109.1s |
| gsm8k | 100 | 81 | 81.0% | 2448s | 20.4s |
| truthfulqa-mc1 | 100 | 76 | 76.0% | 41s | 0.4s |
| hellaswag | 100 | 87 | 87.0% | 68s | 0.8s |
| code | 10 | 10 | 100.0% | 23s | 1.9s |
| longctx | 6 | 6 | 100.0% | 405s | 32.1s |
| agent | 4 | 2 | 50.0% | 64s | 13.3s |
| agent_recorded | 26 | 9 | 34.6% | 1309s | 57.4s |
| forge | 30 | 0 | 0.0% | 137s | 3.2s |
