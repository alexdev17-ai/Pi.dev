#!/usr/bin/env bash
set -euo pipefail

RUNNER_DIR="$(cd "$(dirname "$0")/.." && pwd)/skills/playwright-safe/runner"

echo "=== Building Docker image ==="
docker build -t pi-playwright-runner "$RUNNER_DIR"

echo "=== Test: goto operation ==="
result=$(docker run --rm --init pi-playwright-runner \
  node /app/playwright-runner.js \
  --operation goto \
  --url "https://example.com" 2>/dev/null)

echo "Raw output: $result"

status=$(echo "$result" | jq -r '.status')
title=$(echo "$result" | jq -r '.data.title')

if [[ "$status" == "success" ]]; then
  echo "PASS: status is success"
else
  echo "FAIL: expected status=success, got $status"
  exit 1
fi

if [[ -n "$title" ]]; then
  echo "PASS: got page title: $title"
else
  echo "FAIL: page title is empty"
  exit 1
fi

echo ""
echo "Runner tests passed."
