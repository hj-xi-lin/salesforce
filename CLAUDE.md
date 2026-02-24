# Salesforce Project

## Auto-Backup System (IMPORTANT)

A `PreToolUse` hook automatically backs up org metadata before every `deploy_metadata` call. The hook is configured in `.claude/settings.json` and runs `.claude/hooks/sf-pre-deploy-backup.sh`.

### How it works:
- Before every deploy, the hook retrieves the CURRENT org state of the metadata being deployed
- Backups are saved to `backups/deploy_<timestamp>_<label>/` in the project root (override with `SF_BACKUP_DIR` env var)
- If backup fails, the deploy is BLOCKED — you will see an error
- Audit log: `backups/deploy-log.csv`

### Rules for Claude:
1. **Do NOT skip or disable the hook.** If a deploy is blocked, investigate and fix the issue.
2. **Always provide `sourceDir`** when calling `deploy_metadata`. This keeps backups targeted and fast. Only omit `sourceDir` when deploying all tracked changes.
3. If a deploy is blocked due to backup failure:
   - Check if the org authentication is valid (try a SOQL query first)
   - Check if the paths in `sourceDir` exist in the project
   - Report the error to the user
4. After a successful deploy, inform the user where the backup was saved.

## Deployment Rules

- **Always deploy permission sets or profile metadata alongside new custom fields.** Salesforce does NOT auto-grant Field-Level Security via the Metadata API. Without FLS, fields are invisible on layouts, missing from reports, and SOQL returns "No such column."
- Default org alias: `heyjobs` (username: `xi.lin@heyjobs.de`)
- All output files (backups, reports, exports) should go to the user's preferred location.

## Team Guidelines

- Follow the development lifecycle in `docs/development-lifecycle.md`
- Follow the rollback procedures in `docs/rollback-strategy.md`
- Always work on a feature branch — never commit directly to `main`
- Open a Pull Request for every change — CI will validate the deployment automatically
