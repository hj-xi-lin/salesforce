#!/bin/bash
# ~/.claude/hooks/branch-name-check.sh
# Pre-tool hook: check branch naming for git operations

INPUT="$CLAUDE_HOOK_INPUT"
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

# Only check git checkout -b and git branch commands
if echo "$COMMAND" | grep -qE "git (checkout -b|branch) "; then
  BRANCH=$(echo "$COMMAND" | grep -oE "(feature|fix|chore|hotfix)/[a-z0-9-]+")
  if [ -z "$BRANCH" ]; then
    echo "⚠️ Branch name should follow convention: feature/*, fix/*, chore/*, hotfix/*"
    # Warning only, don't block
  fi
fi
exit 0
