# Salesforce Development Lifecycle - Best Practices

## 1. Requirements & Design

- Gather requirements in Jira/Confluence
- Classify the change: **declarative** (clicks) vs **programmatic** (code)
- Rule of thumb: if you can do it with Flows, Validation Rules, or Formula Fields — don't write Apex
- Document the objects, fields, and automations affected

## 2. Environment Strategy

```
Production (heyjobs)
    ↑ deploy
Staging / UAT Sandbox (full or partial copy)
    ↑ deploy
Dev Sandbox(es) (developer or developer pro)
```

- **Never develop directly in Production**
- Use **Developer Sandboxes** for individual work
- Use a **Partial/Full Copy Sandbox** for UAT and integration testing
- Refresh sandboxes regularly to keep test data realistic

## 3. Source Control (Critical)

- **Git repo** with your `sfdx-project.json` and `force-app/` source tree
- **Branch per feature** (e.g., `feature/RO-2840-churn-field`)
- **Pull Requests** for peer review before merging to `main`
- This gives you history, rollback capability, and collaboration

Repo structure:

```
salesforce/
├── sfdx-project.json
├── config/
│   └── project-scratch-def.json
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/          ← Apex
│           ├── triggers/         ← Apex triggers
│           ├── flows/            ← Flows
│           ├── objects/          ← Custom fields, objects
│           ├── layouts/          ← Page layouts
│           ├── permissionsets/   ← Permission sets
│           ├── profiles/         ← Profile metadata
│           └── lwc/              ← Lightning Web Components
├── .claude/                      ← Auto-backup hooks (see README)
├── .github/workflows/            ← CI/CD pipelines
└── docs/
```

## 4. Development Workflow

**For each ticket (e.g., RO-XXXX):**

1. **Create a branch** from `main`
2. **Build in a Dev Sandbox** — use Setup UI for clicks, VS Code for code
3. **Retrieve** your changes: `sf retrieve metadata` to pull what you built into your local project
4. **Review the metadata files** — make sure you're only including what you changed
5. **Add FLS/Permissions** — deploying fields without `fieldPermissions` means invisible fields. Always include a permission set or profile metadata
6. **Write tests** — Apex requires 75% code coverage minimum, but aim for meaningful assertions, not just coverage
7. **Commit & Push** to your feature branch
8. **Open a Pull Request** — team reviews the metadata and code

## 5. Deployment Pipeline

| Stage | Environment | Purpose |
|-------|------------|---------|
| Dev | Developer Sandbox | Build & unit test |
| QA | Dev/Partial Sandbox | Functional testing |
| UAT | Full Copy Sandbox | Business user acceptance |
| Prod | Production | Go live |

Deploy to each stage sequentially:

```bash
sf deploy metadata -x manifest/package.xml --target-org <sandbox-alias>
```

CI/CD is configured in `.github/workflows/`:

- **On PR to `main`** → `validate-pr.yml` runs a dry-run deploy against sandbox
- **Manual trigger** → `deploy-production.yml` deploys to production (requires GitHub environment approval)

## 6. Key Gotchas

### FLS & Permissions
- Always deploy `permissionsets/` or `profiles/` alongside new fields
- Without this, fields are invisible on layouts, missing from reports, and SOQL returns "No such column"

### Page Layouts
- When adding a field, decide which layouts need it — don't blanket-add to all

### Roll-Up Summary Fields
- Account has a limit of 25 roll-up summary fields
- Consider Declarative Lookup Rollup Summaries (DLRS) as an alternative when approaching the limit

### Validation Rules & Flows
- Test in sandbox first — a bad validation rule can block entire teams
- Document flow logic in the description field

## 7. Testing Checklist

Before deploying to Production:

- [ ] All Apex tests pass (`sf apex run test`)
- [ ] Code coverage >= 75% (per class, not just org-wide)
- [ ] Manual testing in UAT sandbox by a business user
- [ ] Field-level security verified (fields visible where expected)
- [ ] Page layouts updated and verified
- [ ] No hardcoded IDs (record types, profiles differ between environments)
- [ ] Rollback plan documented (what to undo if something breaks)

## 8. Post-Deployment

- **Smoke test** in Production — verify the change works
- **Monitor** for errors (Setup > Apex Exception Email, debug logs)
- **Communicate** the change to affected users
- **Update documentation** in Confluence

## Quick Reference: "I need to add a new field"

```
1. Create field in Dev Sandbox (Setup UI)
2. Add to page layout(s) in Dev Sandbox
3. Set FLS in Dev Sandbox (or create Permission Set)
4. sf retrieve metadata  →  pull to local project
5. Verify retrieved files: objects/, layouts/, permissionsets/
6. git checkout -b feature/RO-XXXX-my-field
7. git commit + push + open PR
8. CI validates → team reviews → merge
9. Deploy to QA → UAT → Production
10. Assign permission set if needed: sf assign permset
```
