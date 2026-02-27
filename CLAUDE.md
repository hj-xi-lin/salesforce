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

## Core Principle: Repo = Salesforce Org

**The GitHub repo is the source of truth and must reflect the actual Salesforce production org.**
- NEVER remove files from the repo that exist in the org (even managed package child metadata like weblinks/fields on standard objects)
- The repo should contain ALL custom code, configuration, and org-owned metadata
- In the future, all development happens in GitHub first, then deploys to SF production

## Metadata Retrieve Rules (CRITICAL)

When retrieving metadata from the org (full or partial), follow these rules to avoid incomplete pulls.

### 1. Standard objects must be listed explicitly
`CustomObject: *` only retrieves custom objects (`__c`). Standard objects are **NOT included by wildcard**. Always list them explicitly in `manifest/package.xml`:
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

### 2. Child metadata types come via their parent object
These types are children of `CustomObject` and do NOT resolve independently with wildcard `*`:
- `ValidationRule`, `CustomField`, `RecordType`, `BusinessProcess`, `CompactLayout`, `FieldSet`, `ListView`, `WebLink`

If standard objects are not explicitly listed (rule 1), their child metadata will be **silently missing**.

### 3. Unlocked package components need explicit retrieval
The `*` wildcard does NOT retrieve components from **installed unlocked (2GP) packages**, even when they have no namespace. This affects:

| Package | What it installs | Managed separately |
|---|---|---|
| Trigger Actions Framework | `TriggerBase`, `TriggerAction*`, `MetadataTriggerHandler`, etc. | Yes — via `sf package install` |
| Nebula Logger | `Logger`, `Log*`, `LogEntry*`, 6 triggers | Yes — via `sf package install` |
| datatable | `ers_DatatableController`, `ers_EncodeDecodeURL`, `ers_QueryNRecords` | Yes — via `sf package install` |

**However**, custom code that extends these frameworks IS our code and must be retrieved explicitly:
```bash
sf project retrieve start \
  --metadata ApexTrigger:AccountTrigger \
  --metadata ApexTrigger:OpportunityTrigger \
  --metadata ApexClass:TA_Acc_UpdateOpps \
  --metadata ApexClass:TA_Opp_UpdateParentAccounts \
  --metadata ApexClass:Finalizer \
  --metadata ApexClass:FinalizerHandler \
  --metadata ApexClass:FinalizerHandlerTest \
  --target-org heyjobs
```
After any full retrieve, always run the SOQL comparison in rule 5 to catch these.

### 4. Keep managed package child metadata
When standard objects are retrieved, they include child metadata from installed packages (e.g., `LeanData__Status_Info__c` fields, `slackv2__Send_to_Slack` weblinks, `ONB2__*` fields). **Do NOT delete these.** They are part of the org's actual configuration and must stay in the repo.

### 5. Always verify retrieve completeness
After any full org retrieve, compare repo vs org using SOQL (not `sf apex list` which doesn't work reliably):

```bash
# Count custom classes in org (excluding managed packages with namespaces)
sf data query --query "SELECT COUNT(Id) FROM ApexClass WHERE NamespacePrefix = null" --target-org heyjobs

# Count custom triggers in org
sf data query --query "SELECT COUNT(Id) FROM ApexTrigger WHERE NamespacePrefix = null" --target-org heyjobs

# List all custom triggers (to diff against repo)
sf data query --query "SELECT Name FROM ApexTrigger WHERE NamespacePrefix = null ORDER BY Name" --target-org heyjobs

# Find classes in org but NOT in repo
sf data query --query "SELECT Name FROM ApexClass WHERE NamespacePrefix = null ORDER BY Name" --target-org heyjobs --result-format csv > /tmp/org_classes.txt
ls force-app/main/default/classes/*.cls | xargs -I{} basename {} .cls | sort > /tmp/repo_classes.txt
comm -23 <(sort /tmp/org_classes.txt) /tmp/repo_classes.txt
```

**Expected baselines (as of Feb 2025):**
- Custom classes (no namespace) in org: 267 total = 164 custom code + 103 installed unlocked package
- Custom classes in repo: 164
- Triggers (no namespace) in org: 20 total = 14 custom + 6 Nebula Logger
- Triggers in repo: 14
- Validation rules in repo: ~100
- Global value sets in repo: 41
- Standard object directories: Account, Opportunity, Lead, Contact, Case, Quote, Event, Task, User, Campaign, CampaignMember, ContentVersion — all with fields/ subdirectories

**If classes are in the org but not in the repo**, determine their source:
- Nebula Logger / TAF / datatable package classes → expected gap, managed via package install
- Custom classes (created by team members like Arun Kumar, Lisa Müller, xSalesfive) → retrieve explicitly

### 6. Installed packages reference
These packages are installed in the org and managed separately (NOT via GitHub):

| Package | Namespace | Type |
|---|---|---|
| Nebula Logger | _(none — unlocked)_ | Logging framework |
| Trigger Actions Framework | _(none — unlocked)_ | Trigger orchestration |
| datatable | _(none — unlocked)_ | LWC datatable component |
| Platform Event Toast | _(none — unlocked)_ | PE toast notifications |
| DLRS | `dlrs` | Rollup summaries (managed) |
| LeanData | `LeanData` | Lead routing (managed) |
| JustOn/ONB2 | `ONB2` | Billing (managed) |
| HelloSign | `HelloSign` | E-signatures (managed) |
| Slack | `slackv2` | Slack integration (managed) |
| Aircall | `aircall` / `aircall2gp` | CTI (managed) |
| ReplyApp | `replyapp` | Email outreach (managed) |

### 7. Run retrieve from the project directory
Always `cd` to the sfdx project root (`/Users/xi.lin/Documents/SF_Claude/salesforce`) before running retrieve commands. Running from other directories causes `InvalidProjectWorkspaceError`.

## Team Guidelines

- Follow the development lifecycle in `docs/development-lifecycle.md`
- Follow the rollback procedures in `docs/rollback-strategy.md`
- Always work on a feature branch — never commit directly to `main`
- Open a Pull Request for every change — CI will validate the deployment automatically
