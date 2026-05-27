# luce-bench sweep — bragi-rtx5090laptop-gemma4-26b-2026-05-26-sweep-think

- url:   `http://bragi:8080`
- model: `dflash`
- lucebench v0.2.3

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| ds4-eval | 92 | 74 | 80.4% | 8569s | 100.5s |
| code | 10 | 0 | 0.0% | 139s | 19.6s |
| longctx | 6 | 4 | 66.7% | 15s | 2.0s |
| agent | 4 | 2 | 50.0% | 65s | 10.5s |
