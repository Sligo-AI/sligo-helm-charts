#!/usr/bin/env bash
# GitHub Pages serves /docs; Helm index and chart tarballs must live under docs/ for
# https://sligo-ai.github.io/sligo-helm-charts/ — not only repo root charts/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cp "${ROOT}/charts/"*.tgz "${ROOT}/docs/charts/"
helm repo index "${ROOT}/docs/charts" --url https://sligo-ai.github.io/sligo-helm-charts/charts
mv "${ROOT}/docs/charts/index.yaml" "${ROOT}/docs/index.yaml"
cp "${ROOT}/docs/index.yaml" "${ROOT}/index.yaml"
echo "OK: docs/index.yaml, root index.yaml, and docs/charts/*.tgz are aligned. Review and commit."
