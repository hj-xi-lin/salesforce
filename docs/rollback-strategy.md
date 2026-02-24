# Rollback Strategy

## Automatic Backups

This repo has an auto-backup hook that retrieves the current org state before every deployment via Claude Code. Backups are saved to `backups/` in the project root (override with `SF_BACKUP_DIR` env var).

To rollback using an automatic backup:

```bash
sf deploy metadata --source-dir backups/deploy_<timestamp>_<label>/force-app/ \
  --target-org heyjobs
```

Check `backups/deploy-log.csv` for a history of all deployments and their backup locations.

## Manual Rollback (without auto-backup)

### The Golden Rule: Retrieve Before You Deploy

**Always** pull the current state of what you're about to change *before* deploying:

```bash
# Step 1: Retrieve current state as your backup
sf retrieve metadata --source-dir force-app/main/default/objects/Account \
  --target-org heyjobs \
  --output-dir ~/my-backup-folder/

# Step 2: Deploy your changes
sf deploy metadata --source-dir force-app/main/default/objects/Account \
  --target-org heyjobs

# If something goes wrong → redeploy the backup
sf deploy metadata --source-dir ~/my-backup-folder/ \
  --target-org heyjobs
```

## Rollback Scenarios

### Scenario A: You modified existing metadata (field, layout, flow, class)

Straightforward — redeploy the previous version from your backup:

```bash
sf deploy metadata --source-dir <backup-folder>/ --target-org heyjobs
```

### Scenario B: You added new components (new field, new class, new flow)

You can't just "not deploy" them — they already exist in prod. You need a **destructive deploy**:

1. Create a `destructiveChanges.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/schemas/metadata">
  <types>
    <members>Account.My_New_Field__c</members>
    <name>CustomField</name>
  </types>
  <version>62.0</version>
</Package>
```

2. Create an empty `package.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/schemas/metadata">
  <version>62.0</version>
</Package>
```

3. Deploy the destructive change:

```bash
sf deploy metadata --manifest package.xml \
  --post-destructive-changes destructiveChanges.xml \
  --target-org heyjobs
```

### Scenario C: You activated a Flow or Validation Rule

- **Flows:** deploy the previous version as "Active", or deactivate via Setup UI immediately
- **Validation Rules:** set `<active>false</active>` in the metadata and redeploy, or toggle off in Setup UI

### Scenario D: Emergency — something is broken NOW

Don't wait for metadata deploys. Go to **Setup UI** directly:

- Deactivate the Flow / Validation Rule / Trigger
- Remove field from page layout
- Deactivate the Apex Trigger (via deploy with `<status>Inactive</status>`)

Then do a proper rollback afterward.

## What You Can and Can't Easily Roll Back

| Change | Rollback Difficulty | Notes |
|--------|-------------------|-------|
| Modified field/layout/class | Easy | Redeploy backup |
| New field (no data yet) | Easy | Destructive deploy |
| New field (data written to it) | Medium | Data is lost on delete |
| Deleted field | Hard | Field goes to recycle bin for 15 days, then gone |
| Changed field type (e.g., text→number) | Hard | Data may be lost |
| Data changes (via Flow/Trigger) | Very hard | No built-in undo for data |

## Bottom Line Checklist

Before every production deploy:

1. **Auto-backup hook** handles the retrieve automatically (if using Claude Code)
2. **Deploy** your changes
3. **Smoke test** immediately
4. If broken → **redeploy backup** or **destructive deploy**

With Git, you also have `git revert` to undo any committed change and redeploy the previous state.
