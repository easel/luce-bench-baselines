# luce-bench sweep — vidar-m2ultra-gemma4-26b-mlx8bit-sweep-nothink-2026-05-27

- url:   `http://vidar:1237`
- model: `gemma-4-26B-A4B-it-MLX-8bit`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 3 | 100.0% | 23s | 0.2s |
| ds4-eval | 92 | 73 | 79.3% | 5466s | 23.3s |
| code | 10 | 10 | 100.0% | 13s | 1.1s |
| longctx | 6 | 6 | 100.0% | 125s | 10.2s |
| agent | 4 | 1 | 25.0% | 39s | 7.0s |
| forge | 30 | 0 | 0.0% | 29s | 0.8s |
