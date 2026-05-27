# luce-bench sweep — bragi-rtx5090laptop-gemma4-26b-2026-05-26-sweep-nothink

- url:   `http://bragi:8080`
- model: `dflash`
- lucebench v0.2.3

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| ds4-eval | 92 | 72 | 78.3% | 2211s | 9.5s |
| code | 10 | 1 | 10.0% | 45s | 0.8s |
| longctx | 6 | 4 | 66.7% | 21s | 3.7s |
| agent | 4 | 3 | 75.0% | 58s | 7.1s |
