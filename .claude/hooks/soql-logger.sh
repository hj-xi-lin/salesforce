#!/bin/bash
# ~/.claude/hooks/soql-logger.sh
# Post-tool hook: log SOQL queries

INPUT="$CLAUDE_HOOK_INPUT"
QUERY=$(echo "$INPUT" | jq -r '.query // empty')
ORG=$(echo "$INPUT" | jq -r '.usernameOrAlias // empty')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

echo "$TIMESTAMP | $ORG | $QUERY" >> "$LOG_DIR/soql-queries.log"
exit 0
