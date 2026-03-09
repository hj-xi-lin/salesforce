#!/usr/bin/env bash
#
# Salesforce Drift Detection
#
# Retrieves the current production org metadata and compares it against the
# git repository. Generates a drift-report.md summarising all differences.
#
# Usage:  ./scripts/detect-drift.sh
#
# Environment variables:
#   SF_ORG_ALIAS  — Salesforce org alias (default: heyjobs)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ORG_ALIAS="${SF_ORG_ALIAS:-heyjobs}"
REPORT_FILE="$PROJECT_DIR/drift-report.md"
KNOWN_PACKAGES="$SCRIPT_DIR/known-package-components.txt"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cd "$PROJECT_DIR"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { echo "[drift-detection] $(date -u +%H:%M:%S) $*"; }

count_lines() {
  local text="$1"
  if [ -z "$text" ]; then echo 0; else echo "$text" | wc -l | tr -d ' '; fi
}

write_section() {
  local title="$1" files="$2"
  if [ -n "$files" ]; then
    printf '\n#### %s\n' "$title" >> "$REPORT_FILE"
    echo "$files" | sed '/^$/d' | sed 's|^|- `|;s|$|`|' >> "$REPORT_FILE"
  fi
}

# ---------------------------------------------------------------------------
# 1. Verify authentication
# ---------------------------------------------------------------------------
log "Verifying authentication to org '$ORG_ALIAS'..."
if ! sf data query \
  --query "SELECT Id FROM Organization LIMIT 1" \
  --target-org "$ORG_ALIAS" --json >/dev/null 2>&1; then
  log "ERROR: Cannot authenticate to org '$ORG_ALIAS'"
  exit 1
fi
log "Authentication OK."

# ---------------------------------------------------------------------------
# 2. Retrieve org metadata
# ---------------------------------------------------------------------------
log "Retrieving org metadata (manifest/package.xml)..."
if ! sf project retrieve start \
  --manifest manifest/package.xml \
  --target-org "$ORG_ALIAS" \
  --ignore-conflicts \
  --wait 15; then
  log "ERROR: Metadata retrieve failed."
  exit 1
fi
log "Retrieve complete."

# ---------------------------------------------------------------------------
# 3. Detect file-level changes
# ---------------------------------------------------------------------------
log "Detecting drift..."

# Mark new untracked files so git diff can see them
git add -N force-app/

CHANGED_FILES="$(git diff --name-only -- force-app/ || true)"

if [ -z "$CHANGED_FILES" ]; then
  HAS_DRIFT=false
  TOTAL_CHANGED=0
  log "No file-level drift detected."
else
  HAS_DRIFT=true
  TOTAL_CHANGED=$(count_lines "$CHANGED_FILES")
  log "Drift detected: $TOTAL_CHANGED file(s) changed."
fi

# ---------------------------------------------------------------------------
# 4. Categorise changes
# ---------------------------------------------------------------------------
APEX_CLASSES="" APEX_TRIGGERS="" OBJECTS="" LAYOUTS="" FLOWS=""
PERMISSIONS="" LWC="" OTHER=""

if [ "$HAS_DRIFT" = true ]; then
  while IFS= read -r file; do
    case "$file" in
      */classes/*)                          APEX_CLASSES+="$file"$'\n' ;;
      */triggers/*)                         APEX_TRIGGERS+="$file"$'\n' ;;
      */objects/*)                           OBJECTS+="$file"$'\n' ;;
      */layouts/*)                           LAYOUTS+="$file"$'\n' ;;
      */flows/*)                             FLOWS+="$file"$'\n' ;;
      */permissionsets/*|*/profiles/*)       PERMISSIONS+="$file"$'\n' ;;
      */lwc/*|*/aura/*)                      LWC+="$file"$'\n' ;;
      *)                                     OTHER+="$file"$'\n' ;;
    esac
  done <<< "$CHANGED_FILES"
fi

APEX_CLASSES_COUNT=$(count_lines "$APEX_CLASSES")
APEX_TRIGGERS_COUNT=$(count_lines "$APEX_TRIGGERS")
OBJECTS_COUNT=$(count_lines "$OBJECTS")
LAYOUTS_COUNT=$(count_lines "$LAYOUTS")
FLOWS_COUNT=$(count_lines "$FLOWS")
PERMISSIONS_COUNT=$(count_lines "$PERMISSIONS")
LWC_COUNT=$(count_lines "$LWC")
OTHER_COUNT=$(count_lines "$OTHER")

# ---------------------------------------------------------------------------
# 5. SOQL verification — class / trigger counts
# ---------------------------------------------------------------------------
log "Running SOQL verification..."

ORG_CLASS_COUNT=$(sf data query \
  --query "SELECT COUNT(Id) FROM ApexClass WHERE NamespacePrefix = null" \
  --target-org "$ORG_ALIAS" --json 2>/dev/null \
  | jq -r '.result.records[0].expr0 // "?"') || ORG_CLASS_COUNT="?"

ORG_TRIGGER_COUNT=$(sf data query \
  --query "SELECT COUNT(Id) FROM ApexTrigger WHERE NamespacePrefix = null" \
  --target-org "$ORG_ALIAS" --json 2>/dev/null \
  | jq -r '.result.records[0].expr0 // "?"') || ORG_TRIGGER_COUNT="?"

REPO_CLASS_COUNT=$(find force-app/main/default/classes -name "*.cls" 2>/dev/null | wc -l | tr -d ' ')
REPO_TRIGGER_COUNT=$(find force-app/main/default/triggers -name "*.trigger" 2>/dev/null | wc -l | tr -d ' ')

CLASS_DELTA=$((ORG_CLASS_COUNT - REPO_CLASS_COUNT)) 2>/dev/null || CLASS_DELTA="?"
TRIGGER_DELTA=$((ORG_TRIGGER_COUNT - REPO_TRIGGER_COUNT)) 2>/dev/null || TRIGGER_DELTA="?"

log "Classes  — org: $ORG_CLASS_COUNT  repo: $REPO_CLASS_COUNT  delta: $CLASS_DELTA"
log "Triggers — org: $ORG_TRIGGER_COUNT  repo: $REPO_TRIGGER_COUNT  delta: $TRIGGER_DELTA"

# ---------------------------------------------------------------------------
# 6. Identify classes in org but not in repo
# ---------------------------------------------------------------------------
log "Checking for classes in org but not in repo..."

ORG_CLASSES_CSV=$(sf data query \
  --query "SELECT Name FROM ApexClass WHERE NamespacePrefix = null ORDER BY Name" \
  --target-org "$ORG_ALIAS" --result-format csv 2>/dev/null | tail -n +2 || true)

REPO_CLASSES=$(find force-app/main/default/classes -name "*.cls" \
  -exec basename {} .cls \; 2>/dev/null | sort || true)

MISSING_CLASSES=""
if [ -n "$ORG_CLASSES_CSV" ]; then
  MISSING_CLASSES=$(comm -23 \
    <(echo "$ORG_CLASSES_CSV" | tr -d '\r' | sort) \
    <(echo "$REPO_CLASSES") || true)
fi

# Filter out known package components
UNKNOWN_MISSING=""
if [ -n "$MISSING_CLASSES" ] && [ -f "$KNOWN_PACKAGES" ]; then
  while IFS= read -r cls; do
    [ -z "$cls" ] && continue
    if ! grep -qx "$cls" "$KNOWN_PACKAGES" 2>/dev/null; then
      UNKNOWN_MISSING+="$cls"$'\n'
    fi
  done <<< "$MISSING_CLASSES"
elif [ -n "$MISSING_CLASSES" ]; then
  UNKNOWN_MISSING="$MISSING_CLASSES"
fi

UNKNOWN_MISSING_COUNT=$(count_lines "$UNKNOWN_MISSING")
TOTAL_MISSING_COUNT=$(count_lines "$MISSING_CLASSES")

# If there are unknown missing classes, that counts as drift too
if [ "$UNKNOWN_MISSING_COUNT" -gt 0 ] 2>/dev/null; then
  HAS_DRIFT=true
fi

# ---------------------------------------------------------------------------
# 7. Generate report
# ---------------------------------------------------------------------------
log "Generating report..."

cat > "$REPORT_FILE" << EOF
## Salesforce Org Drift Report

**Date**: $TIMESTAMP
**Org**: \`$ORG_ALIAS\`
**Total files changed**: $TOTAL_CHANGED
EOF

if [ "$HAS_DRIFT" = true ] && [ "$TOTAL_CHANGED" -gt 0 ]; then
  cat >> "$REPORT_FILE" << EOF

### Changed Files by Category

| Category | Files |
|----------|-------|
| Apex Classes | $APEX_CLASSES_COUNT |
| Apex Triggers | $APEX_TRIGGERS_COUNT |
| Objects / Fields | $OBJECTS_COUNT |
| Layouts | $LAYOUTS_COUNT |
| Flows | $FLOWS_COUNT |
| Permissions | $PERMISSIONS_COUNT |
| LWC / Aura | $LWC_COUNT |
| Other | $OTHER_COUNT |
EOF
fi

cat >> "$REPORT_FILE" << EOF

### SOQL Verification

| Metric | Org (no namespace) | Repo | Delta | Expected delta |
|--------|-------------------|------|-------|----------------|
| Apex Classes | $ORG_CLASS_COUNT | $REPO_CLASS_COUNT | $CLASS_DELTA | ~103 (unlocked packages) |
| Apex Triggers | $ORG_TRIGGER_COUNT | $REPO_TRIGGER_COUNT | $TRIGGER_DELTA | ~6 (Nebula Logger) |
EOF

if [ "$UNKNOWN_MISSING_COUNT" -gt 0 ] 2>/dev/null; then
  cat >> "$REPORT_FILE" << EOF

### Classes in Org but NOT in Repo (unknown origin)

These **$UNKNOWN_MISSING_COUNT** classes exist in the org without a namespace but are missing
from the repository and are **not** listed in \`scripts/known-package-components.txt\`.
They may be new custom code that needs to be retrieved, or newly installed package components
that should be added to the known-packages list.

$(echo "$UNKNOWN_MISSING" | sed '/^$/d' | sed 's/^/- `/' | sed 's/$/.cls`/')
EOF
elif [ "$TOTAL_MISSING_COUNT" -gt 0 ] 2>/dev/null; then
  cat >> "$REPORT_FILE" << EOF

> **$TOTAL_MISSING_COUNT** classes are in the org but not in the repo — all are recognised as
> installed package components (Nebula Logger, TAF, datatable, etc.).
EOF
fi

if [ "$HAS_DRIFT" = true ] && [ "$TOTAL_CHANGED" -gt 0 ]; then
  echo "" >> "$REPORT_FILE"
  echo "### Changed Files" >> "$REPORT_FILE"

  write_section "Apex Classes" "$APEX_CLASSES"
  write_section "Apex Triggers" "$APEX_TRIGGERS"
  write_section "Objects / Fields" "$OBJECTS"
  write_section "Layouts" "$LAYOUTS"
  write_section "Flows" "$FLOWS"
  write_section "Permissions" "$PERMISSIONS"
  write_section "LWC / Aura" "$LWC"
  write_section "Other" "$OTHER"
fi

cat >> "$REPORT_FILE" << 'EOF'

---

### About This PR

This PR was automatically generated by the **Salesforce drift detection pipeline**.

Changes represent modifications made directly in the Salesforce production org that are
not reflected in this repository.

**Review carefully before merging.** Some changes may be:
- Intentional admin changes that should be committed
- Managed package metadata updates (expected)
- Temporary changes that should be reverted in the org
EOF

log "Report saved to $REPORT_FILE"

# ---------------------------------------------------------------------------
# 8. Set GitHub Actions outputs
# ---------------------------------------------------------------------------
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "has_drift=$HAS_DRIFT" >> "$GITHUB_OUTPUT"
  echo "total_changed=$TOTAL_CHANGED" >> "$GITHUB_OUTPUT"
  echo "unknown_missing=$UNKNOWN_MISSING_COUNT" >> "$GITHUB_OUTPUT"
fi

log "Done. has_drift=$HAS_DRIFT  files_changed=$TOTAL_CHANGED  unknown_missing=$UNKNOWN_MISSING_COUNT"
