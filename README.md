# HeyJobs Salesforce Project

Central repository for all Salesforce metadata, development workflows, and deployment automation.

## Prerequisites

Before you start, make sure you have:

- [ ] [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) installed (`sf --version`)
- [ ] [Claude Code](https://claude.com/claude-code) installed
- [ ] GitHub access to this repo
- [ ] Salesforce org credentials (ask your admin)

## Quick Setup

### Step 1: Clone the repo

```bash
git clone https://github.com/hj-xi-lin/salesforce.git
cd salesforce
```

### Step 2: Configure your backup folder

Add these to your `~/.zshrc` (or `~/.bashrc`):

```bash
# Salesforce auto-backup config
export SF_BACKUP_DIR=~/SF_Backups      # Change to your preferred folder
export SF_ORG_ALIAS=heyjobs            # Default org alias
```

Then reload:

```bash
source ~/.zshrc
```

### Step 3: Make the hook script executable

```bash
chmod +x .claude/hooks/sf-pre-deploy-backup.sh
```

### Step 4: Authenticate to the Salesforce org

```bash
sf org login web -a heyjobs
```

### Step 5: Start Claude Code

```bash
claude
```

The auto-backup hook is now active. Every time you deploy metadata through Claude Code, the current org state is automatically backed up before the deploy proceeds.

## How the Auto-Backup Works

```
You ask Claude to deploy  →  Hook fires  →  Retrieves current org state
                                          →  Saves to $SF_BACKUP_DIR/deploy_<timestamp>/
                                          →  If backup fails: deploy is BLOCKED
                                          →  If backup succeeds: deploy proceeds
```

- Backups are saved to: `$SF_BACKUP_DIR/deploy_<timestamp>_<label>/`
- Deployment audit log: `$SF_BACKUP_DIR/deploy-log.csv`
- Hook script: `.claude/hooks/sf-pre-deploy-backup.sh`
- Hook config: `.claude/settings.json`

## Development Workflow

### For each change (feature, bug fix, etc.):

```
1. git checkout -b feature/RO-XXXX-description
2. Build in a Dev Sandbox (Setup UI or VS Code)
3. Retrieve your changes:  sf retrieve metadata
4. Review the metadata files — only include what you changed
5. Include permission set / profile metadata for new fields (FLS!)
6. git add → git commit → git push
7. Open a Pull Request → CI validates → team reviews
8. Merge → deploy to production
```

### Important Rules

- **Never commit directly to `main`** — always use a feature branch + PR
- **Always include FLS** when adding new fields (permission sets or profile metadata)
- **Test in sandbox first** before deploying to production

See [docs/development-lifecycle.md](docs/development-lifecycle.md) for the full guide.

## Rollback

If a deployment goes wrong:

```bash
# Find your backup
ls $SF_BACKUP_DIR/

# Redeploy the backup
sf deploy metadata --source-dir $SF_BACKUP_DIR/deploy_<timestamp>_<label>/force-app/ \
  --target-org heyjobs
```

See [docs/rollback-strategy.md](docs/rollback-strategy.md) for all rollback scenarios.

## CI/CD Pipelines

### PR Validation (automatic)

Every PR that touches `force-app/` triggers a dry-run deployment against the sandbox. Check the PR status for results.

**Setup required (one-time, by admin):**
1. In GitHub repo Settings > Secrets, add `SF_SANDBOX_AUTH_URL` (run `sf org display --verbose --json -o <sandbox>` to get the sfdxAuthUrl)

### Production Deployment (manual)

1. Go to Actions > "Deploy to Production"
2. Click "Run workflow"
3. Select test level
4. Approve in the GitHub environment gate

**Setup required (one-time, by admin):**
1. In GitHub repo Settings > Secrets, add `SF_PRODUCTION_AUTH_URL`
2. In GitHub repo Settings > Environments, create "production" with required reviewers

## Repo Structure

```
salesforce/
├── force-app/main/default/        ← All Salesforce metadata (source of truth)
│   ├── classes/                     Apex classes
│   ├── triggers/                    Apex triggers
│   ├── flows/                       Flows
│   ├── objects/                     Custom objects & fields
│   ├── layouts/                     Page layouts
│   ├── permissionsets/              Permission sets
│   ├── profiles/                    Profiles
│   └── ...                          Other metadata types
├── manifest/package.xml            ← Full org manifest
├── config/project-scratch-def.json ← Scratch org definition
├── .claude/                        ← Claude Code hooks (auto-backup)
├── .github/workflows/              ← CI/CD pipelines
└── docs/                           ← Team documentation
```

## Troubleshooting

### "Deploy is blocked" error
The auto-backup hook couldn't retrieve the current org state. Common causes:
- **Org auth expired** → Run `sf org login web -a heyjobs`
- **Network issue** → Check your internet connection and retry
- **Invalid sourceDir** → The paths being deployed don't exist in the org yet (new metadata). If the hook shows "SKIPPED_NEW_METADATA", this is expected and the deploy should proceed.

### "SF_BACKUP_DIR not set" or backups going to wrong folder
- Check your `~/.zshrc` has `export SF_BACKUP_DIR=...`
- Run `source ~/.zshrc` to reload
- Default is `~/SF_Backups` if not set

### Hook not firing
- Make sure you're running Claude Code from inside this repo directory
- Check `.claude/settings.json` exists and has the hook config
- Ensure `.claude/hooks/sf-pre-deploy-backup.sh` is executable: `chmod +x .claude/hooks/sf-pre-deploy-backup.sh`
