# luce-bench sweep — openrouter-cloud-qwen36-fullsweep-think-cb8k-mt32k-2026-05-30

- url:   `https://openrouter.ai/api`
- model: `qwen/qwen3.6-27b`
- lucebench v0.2.7.dev0

| area | n | pass | rate | wall_total | wall_median |
|------|---|------|------|------------|-------------|
| smoke | 3 | 3 | 100.0% | 214s | 2.9s |
| ds4-eval | 92 | 70 | 76.1% | 17165s | 162.7s |
| gsm8k | 100 | 96 | 96.0% | 4756s | 30.0s |
| truthfulqa-mc1 | 100 | 77 | 77.0% | 2032s | 12.5s |
| hellaswag | 100 | 88 | 88.0% | 1785s | 12.0s |
| code | 10 | 4 | 40.0% | 656s | 47.1s |
| longctx | 6 | 6 | 100.0% | 187s | 29.7s |
| agent | 4 | 2 | 50.0% | 12s | 2.8s |
| agent_recorded | 26 | 12 | 46.2% | 1194s | 40.7s |
| forge | 30 | 0 | 0.0% | 141s | 3.0s |
