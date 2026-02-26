#!/bin/bash
# ~/.claude/hooks/sf-deploy-guard.sh
# Pre-tool hook: guard SF deployments

INPUT="$CLAUDE_HOOK_INPUT"
ORG=$(echo "$INPUT" | jq -r '.usernameOrAlias // empty')

# Allow scratch org deployments without confirmation
if echo "$ORG" | grep -q "scratch\|test-"; then
  exit 0
fi

# For non-scratch orgs, log a warning (Claude will see this)
echo "⚠️ DEPLOYMENT GUARD: Deploying to '$ORG' (non-scratch org). Proceed with caution."
exit 0
