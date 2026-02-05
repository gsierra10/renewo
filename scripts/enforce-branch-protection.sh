#!/usr/bin/env bash
set -euo pipefail

OWNER_REPO="${OWNER_REPO:-}"
BRANCH="${BRANCH:-main}"

if [[ -z "$OWNER_REPO" ]]; then
  OWNER_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

if [[ -z "$OWNER_REPO" ]]; then
  echo "ERROR: Unable to determine OWNER_REPO. Set OWNER_REPO=<owner>/<repo>." >&2
  exit 1
fi

payload=$(cat <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "unit-tests",
      "build-release"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": false,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1,
    "require_last_push_approval": false
  },
  "required_conversation_resolution": {
    "enabled": true
  },
  "allow_force_pushes": {
    "enabled": false
  },
  "allow_deletions": {
    "enabled": false
  },
  "restrictions": {
    "users": [],
    "teams": [],
    "apps": []
  }
}
JSON
)

echo "Applying branch protection to ${OWNER_REPO}:${BRANCH}..."

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/${OWNER_REPO}/branches/${BRANCH}/protection" \
  --input - <<<"$payload" >/dev/null

echo "Branch protection applied."
