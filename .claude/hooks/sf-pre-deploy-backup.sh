#!/bin/bash
# =============================================================================
# sf-pre-deploy-backup.sh
# PreToolUse hook for mcp__Salesforce_DX__deploy_metadata
#
# Automatically backs up the current org state of metadata about to be deployed.
# Exit 0 = allow deploy | Exit 2 = block deploy
#
# Environment variables (set in ~/.zshrc or ~/.bashrc):
#   SF_BACKUP_DIR  - Where backups are saved (default: ~/SF_Backups)
#   SF_ORG_ALIAS   - Default org alias (default: heyjobs)
# =============================================================================

set -euo pipefail

# --- Configuration via environment variables ---
BACKUP_ROOT="${SF_BACKUP_DIR:-$(cd "$(dirname "$0")/../.." && pwd)/backups}"
DEFAULT_ORG="${SF_ORG_ALIAS:-heyjobs}"
DEPLOY_LOG="${BACKUP_ROOT}/deploy-log.csv"
TIMESTAMP=$(date +%Y-%m-%dT%H%M%S)

# --- Read hook input from stdin ---
INPUT=$(cat)

# Parse tool_input fields from the JSON
SOURCE_DIR=$(echo "$INPUT" | jq -r '.tool_input.sourceDir // empty' 2>/dev/null || echo "")
MANIFEST=$(echo "$INPUT" | jq -r '.tool_input.manifest // empty' 2>/dev/null || echo "")
USERNAME=$(echo "$INPUT" | jq -r '.tool_input.usernameOrAlias // empty' 2>/dev/null || echo "")

# Use default org alias if no username provided
if [ -z "$USERNAME" ]; then
  USERNAME="$DEFAULT_ORG"
fi

# --- Ensure backup root exists ---
mkdir -p "$BACKUP_ROOT"

# Initialize deploy log with header if it doesn't exist
if [ ! -f "$DEPLOY_LOG" ]; then
  echo "timestamp,org,label,backup_path,status,details" > "$DEPLOY_LOG"
fi

# --- Determine what to back up ---
BACKUP_LABEL=""
RETRIEVE_ARGS=""

if [ -n "$SOURCE_DIR" ] && [ "$SOURCE_DIR" != "null" ]; then
  # sourceDir is a JSON array like ["force-app/main/default/objects/Account"]
  PATHS=$(echo "$SOURCE_DIR" | jq -r '.[]' 2>/dev/null || echo "$SOURCE_DIR")

  RETRIEVE_ARGS=""
  for p in $PATHS; do
    RETRIEVE_ARGS="$RETRIEVE_ARGS --source-dir $p"
  done

  # Create a short label from the first path
  FIRST_PATH=$(echo "$PATHS" | head -1)
  BACKUP_LABEL=$(echo "$FIRST_PATH" | sed 's|.*/default/||' | tr '/' '_' | cut -c1-30)
  if [ -z "$BACKUP_LABEL" ]; then
    BACKUP_LABEL="targeted"
  fi

elif [ -n "$MANIFEST" ] && [ "$MANIFEST" != "null" ]; then
  RETRIEVE_ARGS="--manifest $MANIFEST"
  BACKUP_LABEL="manifest"

else
  # No sourceDir and no manifest = deploy all tracked changes
  RETRIEVE_ARGS="--source-dir force-app"
  BACKUP_LABEL="full-changes"
fi

BACKUP_DIR="${BACKUP_ROOT}/deploy_${TIMESTAMP}_${BACKUP_LABEL}"

# --- Create backup directory with sfdx project scaffold ---
mkdir -p "$BACKUP_DIR/force-app"

cat > "$BACKUP_DIR/sfdx-project.json" << 'SFDX_EOF'
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true
    }
  ],
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "62.0"
}
SFDX_EOF

# --- Perform the retrieve (backup from org) ---
cd "$BACKUP_DIR"

RETRIEVE_OUTPUT=""
RETRIEVE_EXIT=0

RETRIEVE_OUTPUT=$(sf project retrieve start \
  --target-org "$USERNAME" \
  $RETRIEVE_ARGS \
  --output-dir "$BACKUP_DIR" \
  --json \
  --wait 10 2>&1) || RETRIEVE_EXIT=$?

# --- Evaluate result ---
if [ $RETRIEVE_EXIT -ne 0 ]; then
  # Check if this is new metadata (nothing to retrieve from org)
  if echo "$RETRIEVE_OUTPUT" | grep -qi "no results found\|no source to retrieve\|no files retrieved"; then
    # New metadata — no backup needed, allow deploy
    echo "${TIMESTAMP},${USERNAME},${BACKUP_LABEL},N/A,SKIPPED_NEW_METADATA,no_existing_org_metadata" >> "$DEPLOY_LOG"
    rm -rf "$BACKUP_DIR"
    exit 0
  fi

  # Genuine failure — block the deploy
  echo "BACKUP FAILED: Could not retrieve current org state before deployment." >&2
  echo "Error: $RETRIEVE_OUTPUT" >&2
  echo "Deploy is blocked to protect org metadata. Fix the issue and retry." >&2

  echo "${TIMESTAMP},${USERNAME},${BACKUP_LABEL},${BACKUP_DIR},FAILED,retrieve_error" >> "$DEPLOY_LOG"
  rm -rf "$BACKUP_DIR"
  exit 2
fi

# --- Count backed-up files ---
FILE_COUNT=$(echo "$RETRIEVE_OUTPUT" | jq -r '.result.files | length' 2>/dev/null || echo "unknown")

# --- Log success ---
echo "${TIMESTAMP},${USERNAME},${BACKUP_LABEL},${BACKUP_DIR},SUCCESS,${FILE_COUNT}_files" >> "$DEPLOY_LOG"

echo "Backup complete: $BACKUP_DIR ($FILE_COUNT files)"
exit 0
