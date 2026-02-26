#!/bin/bash
# ~/.claude/hooks/sf-delete-guard.sh
# Pre-tool hook: block org deletion by default

echo "🛑 ORG DELETION BLOCKED. This hook prevents accidental org deletion."
echo "To override, temporarily remove this hook from settings.json."
exit 1
