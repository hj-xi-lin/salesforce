#!/bin/bash
# ~/.claude/hooks/sf-deploy-logger.sh
# Post-tool hook: log deployments

INPUT="$CLAUDE_HOOK_INPUT"
ORG=$(echo "$INPUT" | jq -r '.usernameOrAlias // empty')
SOURCE=$(echo "$INPUT" | jq -r '.sourceDir // empty')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

echo "$TIMESTAMP | DEPLOY | $ORG | $SOURCE" >> "$LOG_DIR/sf-deployments.log"
exit 0
