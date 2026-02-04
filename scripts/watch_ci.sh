#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_NAME="${1:-CI Unit Tests}"
BRANCH_NAME="${2:-main}"
COMMIT_SHA="${COMMIT_SHA:-$(git rev-parse HEAD)}"
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-900}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-10}"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required but not installed."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login"
  exit 1
fi

echo "Waiting for workflow '$WORKFLOW_NAME' on branch '$BRANCH_NAME' for commit $COMMIT_SHA"

run_id=""
elapsed=0
while [[ "$elapsed" -lt "$MAX_WAIT_SECONDS" ]]; do
  run_id="$(gh run list \
    --workflow "$WORKFLOW_NAME" \
    --branch "$BRANCH_NAME" \
    --limit 30 \
    --json databaseId,headSha \
    --jq ".[] | select(.headSha==\"$COMMIT_SHA\") | .databaseId" \
    | head -n 1 || true)"

  if [[ -n "$run_id" ]]; then
    break
  fi

  sleep "$POLL_INTERVAL_SECONDS"
  elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
done

if [[ -z "$run_id" ]]; then
  echo "Timed out after ${MAX_WAIT_SECONDS}s waiting for workflow run."
  exit 1
fi

echo "Found run: $run_id"

if ! gh run watch "$run_id" --exit-status; then
  mkdir -p ci-logs
  gh run view "$run_id" --json displayTitle,status,conclusion,url,headSha
  gh run view "$run_id" --log-failed > "ci-logs/${run_id}-failed.log" || true
  echo "Workflow failed. Failed logs saved to ci-logs/${run_id}-failed.log"
  exit 1
fi

gh run view "$run_id" --json displayTitle,status,conclusion,url,headSha
echo "Workflow succeeded."
