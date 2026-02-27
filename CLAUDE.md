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

## Metadata Retrieve Rules (CRITICAL)

When retrieving metadata from the org (full or partial), follow these rules to avoid incomplete pulls.

### 1. Standard objects must be listed explicitly
`CustomObject: *` only retrieves custom objects (`__c`). Standard objects like Account, Opportunity, Lead, Contact, Case, Quote, Event, Task are **NOT included by wildcard**. Always list them explicitly:
```xml
<types>
  <members>*</members>
  <members>Account</members>
  <members>Opportunity</members>
  <members>Lead</members>
  <members>Contact</members>
  <members>Case</members>
  <members>Quote</members>
  <members>Event</members>
  <members>Task</members>
  <members>User</members>
  <members>Campaign</members>
  <members>CampaignMember</members>
  <members>OpportunityContactRole</members>
  <members>OpportunityLineItem</members>
  <members>QuoteLineItem</members>
  <members>ContentVersion</members>
  <name>CustomObject</name>
</types>
```
This ensures custom fields, validation rules, record types, business processes, compact layouts, and field sets on standard objects are retrieved.

### 2. Child metadata types come via their parent object
These types are children of `CustomObject` and do NOT resolve independently with wildcard `*`:
- `ValidationRule` — only retrieved as part of the parent object
- `CustomField` — only retrieved as part of the parent object
- `RecordType`, `BusinessProcess`, `CompactLayout`, `FieldSet`, `ListView`, `WebLink` — same

If standard objects are not explicitly listed (see rule 1), their child metadata (validation rules, custom fields, etc.) will be silently missing.

### 3. Include all metadata types in package.xml
The following types were missing from the original package.xml and must be included:
```xml
<types><members>*</members><name>GlobalValueSet</name></types>
<types><members>*</members><name>StandardValueSet</name></types>
<types><members>*</members><name>GlobalValueSetTranslation</name></types>
<types><members>*</members><name>DuplicateRule</name></types>
<types><members>*</members><name>MatchingRules</name></types>
<types><members>*</members><name>QuickAction</name></types>
<types><members>*</members><name>PathAssistant</name></types>
```

### 4. Always verify retrieve completeness
After any full org retrieve, run these checks before committing:
1. **Apex classes:** compare count against `sf apex list class --target-org heyjobs | wc -l` (expect ~155 custom, excluding managed packages)
2. **Triggers:** confirm all 16 active triggers are present (check `AccountTrigger` and `OpportunityTrigger` specifically — these were missed before)
3. **Validation rules:** should be ~107 total across all objects. If only a handful appear, standard objects were not retrieved (see rule 1)
4. **Global value sets:** at minimum `A_B_Testing` must be present
5. **Standard object directories:** `force-app/main/default/objects/Account/`, `objects/Opportunity/`, etc. must exist with fields, validationRules, and recordTypes subdirectories

### 5. Managed package metadata is excluded by design
Wildcard `*` excludes installed/managed package components (Nebula Logger, Trigger Actions Framework, DLRS, LeanData, etc.). This is correct — do NOT commit managed package source to the repo. But always verify that custom triggers/classes on the same objects weren't accidentally excluded.

### 6. Run retrieve from the project directory
Always `cd` to the sfdx project root (`/Users/xi.lin/Documents/SF_Claude/salesforce`) before running retrieve commands. Running from `/Users/xi.lin` or `/tmp` causes `InvalidProjectWorkspaceError` or files landing in wrong locations.

## Team Guidelines

- Follow the development lifecycle in `docs/development-lifecycle.md`
- Follow the rollback procedures in `docs/rollback-strategy.md`
- Always work on a feature branch — never commit directly to `main`
- Open a Pull Request for every change — CI will validate the deployment automatically
