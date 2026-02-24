# Team Guide: Working with Claude Code and Salesforce

This guide explains what this repository is, how it works, and how the team should use Claude Code for Salesforce development at HeyJobs.

## What This Repo Is

This is the **single source of truth** for all Salesforce metadata at HeyJobs. Every custom field, page layout, Apex class, Flow, permission set, and automation that lives in our Salesforce org is version-controlled here.

Instead of making changes directly in Production and hoping nothing breaks, we follow a structured workflow:

```
Build in Sandbox → Pull into Git → Review via PR → Deploy to Production
```

Claude Code acts as the team's Salesforce deployment assistant. It handles metadata retrieval, deployment, data queries, and automatically backs up the org before every deploy.

## What's in the Repo

```
salesforce/
├── force-app/main/default/     ← All Salesforce metadata (the important stuff)
│   ├── classes/                  Apex classes and triggers
│   ├── objects/                  Custom objects, fields, record types
│   ├── layouts/                  Page layouts
│   ├── flows/                    Flows and process builders
│   ├── permissionsets/           Permission sets
│   ├── profiles/                 Profile metadata (FLS, layout assignments)
│   ├── lwc/                      Lightning Web Components
│   └── ...                       Other metadata types
│
├── manifest/package.xml         ← Lists all metadata types we track
├── config/project-scratch-def.json  ← Scratch org definition
├── .mcp.json                    ← Connects Claude Code to Salesforce CLI
│
├── .claude/                     ← Claude Code configuration
│   ├── settings.json              Hook config (auto-backup trigger)
│   └── hooks/
│       └── sf-pre-deploy-backup.sh  ← Backup script (runs before every deploy)
│
├── .github/workflows/           ← CI/CD pipelines
│   ├── validate-pr.yml            Validates PRs with dry-run deploy
│   └── deploy-production.yml      Manual production deployment
│
├── backups/                     ← Auto-backup storage (git-ignored)
├── docs/                        ← Team documentation (you are here)
├── CLAUDE.md                    ← Instructions that Claude follows
├── README.md                    ← Quick-start setup guide
└── sfdx-project.json            ← Salesforce project config
```

## Getting Started (New Team Member)

### 1. Install the tools

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli): `npm install -g @salesforce/cli`
- [Claude Code](https://claude.com/claude-code): follow the install guide
- [jq](https://jqlang.github.io/jq/): `brew install jq` (macOS) — needed by the backup hook
- Git and GitHub access

### 2. Clone and authenticate

```bash
git clone https://github.com/hj-xi-lin/salesforce.git
cd salesforce
sf org login web -a heyjobs
```

### 3. Start Claude Code

```bash
claude
```

That's it. The auto-backup hook activates automatically when you run Claude Code from inside this repo.

## How to Use Claude Code for Salesforce

Claude Code connects to your Salesforce org via the Salesforce MCP (Model Context Protocol). You talk to it in plain English, and it translates your requests into Salesforce CLI operations.

### What you can ask Claude to do

| Task | Example prompt |
|------|---------------|
| Query data | "How many Accounts have no Opportunities?" |
| Retrieve metadata | "Retrieve the Account object and its fields" |
| Deploy changes | "Deploy the new Churn_Risk__c field to the org" |
| Run tests | "Run the AccountTriggerTest Apex test" |
| Check org state | "What permission sets are assigned to my user?" |
| Create fields | "Add a Currency field called Annual_Revenue__c to Account" |
| Modify layouts | "Add the new field to the Direct Sales page layout" |
| Manage orgs | "List all my Salesforce orgs" |
| Open the org | "Open the org in my browser" |

### Example conversation

```
You:    "I need to add a checkbox field called Is_Strategic__c to the Account object"

Claude: Creates the field metadata, adds it to relevant page layouts,
        creates a permission set for FLS, and deploys everything.
        The backup hook automatically saves the current org state first.

You:    "Can you check if the field is visible on the Direct Sales layout?"

Claude: Queries the org and confirms the field placement.
```

### What happens when you deploy

Every time Claude deploys metadata, this sequence runs automatically:

```
1. You ask Claude to deploy something
2. The PreToolUse hook fires BEFORE the deploy
3. Hook retrieves the CURRENT org state of what's about to change
4. Backup is saved to backups/deploy_<timestamp>_<label>/
5. If backup succeeds → deploy proceeds
6. If backup fails → deploy is BLOCKED (protects the org)
7. After deploy, Claude tells you where the backup was saved
```

You don't need to think about backups — they happen automatically.

## Day-to-Day Development Workflow

### Making a change (the standard flow)

```
1. Create a feature branch
   git checkout -b feature/RO-XXXX-description

2. Build the change in a Dev Sandbox
   Use Setup UI for declarative changes (fields, layouts, flows)
   Use VS Code/Claude for code (Apex, LWC)

3. Retrieve your changes into the local project
   Ask Claude: "Retrieve the Account object from the org"
   Or run: sf project retrieve start --source-dir force-app/main/default/objects/Account

4. Review what was retrieved
   Only commit what you actually changed — don't include unrelated metadata

5. If you added new fields: include FLS metadata
   This is critical. Without field permissions, fields are invisible.
   Ask Claude: "Create a permission set that grants access to Is_Strategic__c"

6. Commit and push
   git add <specific files>
   git commit -m "Add Is_Strategic__c field to Account"
   git push -u origin feature/RO-XXXX-description

7. Open a Pull Request
   The CI pipeline (validate-pr.yml) automatically runs a dry-run deploy
   against the sandbox to catch errors before merging

8. After PR approval → merge to main

9. Deploy to production
   Either ask Claude to deploy, or use the GitHub Actions workflow
```

### The FLS rule (never forget this)

When you create a new custom field via the Metadata API (which is what Claude and the Salesforce CLI use), Salesforce does **NOT** automatically grant Field-Level Security to any profile. This is different from creating a field through the Setup UI.

Without FLS:
- The field is invisible on page layouts (even if you added it to the layout)
- The field doesn't appear in the report builder
- SOQL queries return "No such column" (not null — the field literally doesn't exist for that user)

**Always deploy a permission set or profile metadata alongside new fields.**

Ask Claude: "Deploy the new field and make sure FLS is set up" — it knows to handle this.

## CI/CD Pipelines

### PR Validation (automatic)

When you open a PR that changes files in `force-app/` or `manifest/`, GitHub Actions automatically:
1. Installs Salesforce CLI
2. Authenticates to the sandbox
3. Runs a **dry-run deploy** (validates without actually deploying)
4. Runs all local Apex tests
5. Reports pass/fail on the PR

If validation fails, fix the issue before merging.

### Production Deployment (manual, with approval gate)

For deploying to production via GitHub Actions:
1. Go to the repo's **Actions** tab
2. Select **"Deploy to Production"**
3. Click **"Run workflow"**
4. Choose the test level (RunLocalTests is the default)
5. A reviewer must approve in the GitHub environment gate before it proceeds

### Admin setup (one-time)

These need to be configured by a repo admin:

| Secret/Setting | Where | How to get it |
|---------------|-------|--------------|
| `SF_SANDBOX_AUTH_URL` | Repo > Settings > Secrets | `sf org display --verbose --json -o <sandbox>` → copy `sfdxAuthUrl` |
| `SF_PRODUCTION_AUTH_URL` | Repo > Settings > Secrets | `sf org display --verbose --json -o heyjobs` → copy `sfdxAuthUrl` |
| `production` environment | Repo > Settings > Environments | Create environment, add required reviewers |

## Rollback: When Things Go Wrong

### Using automatic backups (easiest)

```bash
# See what backups exist
ls backups/

# Check the audit log
cat backups/deploy-log.csv

# Redeploy a backup to restore the previous state
sf deploy metadata --source-dir backups/deploy_<timestamp>_<label>/force-app/ \
  --target-org heyjobs
```

### Using git (for anything committed)

```bash
# Revert a specific commit
git revert <commit-hash>
git push

# Then deploy the reverted state
sf project deploy start --source-dir force-app --target-org heyjobs
```

### Rollback difficulty by change type

| Change | Difficulty | Notes |
|--------|-----------|-------|
| Modified field/layout/class | Easy | Redeploy the backup |
| New field (no data yet) | Easy | Destructive deploy removes it |
| New field (data written) | Medium | Data is lost on delete |
| Deleted field | Hard | Goes to recycle bin for 15 days |
| Changed field type | Hard | Data may be lost or truncated |
| Data changes (via Flow/Trigger) | Very hard | No built-in undo |

### Emergency: something is broken NOW

Don't wait for metadata deploys. Go directly to **Setup UI**:
- Deactivate the Flow or Validation Rule
- Remove the field from the page layout
- Deactivate the Apex Trigger

Then do a proper rollback afterward.

See [rollback-strategy.md](rollback-strategy.md) for the full guide.

## CLAUDE.md: How Claude Behaves

The `CLAUDE.md` file in the repo root contains instructions that Claude follows automatically. Key rules:

1. **Never skips the backup hook** — if a deploy is blocked, Claude investigates instead of bypassing
2. **Always provides `sourceDir`** when deploying — keeps backups targeted and fast
3. **Always includes FLS** when deploying new fields
4. **Reports backup location** after every successful deploy

You don't need to remind Claude about these — it reads `CLAUDE.md` at the start of every session.

## Tips and Best Practices

### Do

- Use feature branches for every change, no matter how small
- Let Claude handle the Salesforce CLI commands — it knows the right flags
- Review the metadata files before committing (no accidental profile changes)
- Test in a sandbox before deploying to production
- Check `backups/deploy-log.csv` to see deployment history

### Don't

- Don't commit directly to `main`
- Don't deploy without FLS for new fields
- Don't hardcode Salesforce IDs (they differ between orgs/sandboxes)
- Don't ignore CI validation failures on PRs
- Don't delete the `backups/` folder — it's your safety net (it's git-ignored, won't bloat the repo)

### Keeping the repo in sync with the org

Over time, changes made directly in the org (via Setup UI) will drift from what's in Git. Periodically:

```
Ask Claude: "Retrieve all metadata from the org using the manifest"
```

This pulls the latest org state into `force-app/`. Review the diff, commit what's intentional, and discard accidental changes.

## Quick Reference

| I want to... | Do this |
|-------------|---------|
| Add a field | Build in sandbox → retrieve → add FLS → commit → PR → deploy |
| Fix a bug in Apex | Edit locally → deploy to sandbox → test → commit → PR → deploy to prod |
| Check field permissions | Ask Claude: "What FLS does the Sales profile have for Account?" |
| See deployment history | `cat backups/deploy-log.csv` |
| Roll back a deploy | `sf deploy metadata --source-dir backups/deploy_<timestamp>/force-app/ -o heyjobs` |
| Run Apex tests | Ask Claude: "Run all Apex tests" |
| Query data | Ask Claude: "Show me all Accounts created this month" |
| Open the org | Ask Claude: "Open the org" |

## Further Reading

- [README.md](../README.md) — Quick setup instructions
- [development-lifecycle.md](development-lifecycle.md) — Detailed development best practices
- [rollback-strategy.md](rollback-strategy.md) — All rollback scenarios and procedures
- [CLAUDE.md](../CLAUDE.md) — Rules Claude follows during deployments
