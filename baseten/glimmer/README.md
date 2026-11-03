# Glimmer on Baseten (dedicated)

`config.yaml` is a complete Truss: vLLM serves `meta-models/Muse-Glimmer-30B`
(BF16, public, Apache 2.0) on 1xH100 with the `muse_glimmer` tool + reasoning
parsers, exposed as an OpenAI-compatible endpoint. No `model/` directory needed.

```bash
# from the repo root, with BASETEN_API_KEY in .env
export K=$(grep -E '^\s*BASETEN_API_KEY\s*=' .env | sed 's/^[^=]*=//;s/^["'\'']//;s/["'\'']$//' | tail -n 1)
HOME=/tmp/truss-home .venv/bin/truss login --api-key "$K" --non-interactive; unset K
HOME=/tmp/truss-home .venv/bin/truss push baseten/glimmer --no-wait
```

Call it like any OpenAI-compatible host (deployment URL + key from the
dashboard). Scale to zero or delete the deployment when idle: an H100 bills
per minute while a replica runs.
