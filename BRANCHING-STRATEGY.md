# Branching Strategy: dev/main workflow

## Goal

Separate development work from production content so PRs can be tested before going live to students.

## Current state

All three repos use `main` as both the development and production branch:

| Repo | Default branch | How AgnosticV references it |
|------|---------------|---------------------------|
| **openshift-days-ops-showroom** | `main` | `ocp4_workload_showroom_content_git_repo_ref: main` |
| **openshift-days-roadshow-automation** | `main` | `version: "{{ tag }}"` where `tag: main` |
| **agnosticv** (openshift-days-ops-track-cnv) | `master` | `common.yaml` + `dev.yaml` |

AgnosticV already has the control points: `common.yaml` sets production values, `dev.yaml` overrides for testing. The `tag` variable controls the automation collection branch. The `ocp4_workload_showroom_content_git_repo_ref` variable controls the showroom branch.

## Proposed workflow

### Branches

- **`main`** — production. What students see. Protected: require PR, no direct pushes.
- **`dev`** — default branch on GitHub. All PRs target `dev`. Testing happens here.

This applies to **openshift-days-ops-showroom** first. The automation repo can follow later if needed.

### AgnosticV changes

```yaml
# common.yaml (production)
ocp4_workload_showroom_content_git_repo_ref: main

# dev.yaml (testing)
ocp4_workload_showroom_content_git_repo_ref: dev
```

No changes needed — this is already how it works. `common.yaml` already points to `main` and `dev.yaml` already overrides it.

### Day-to-day workflow

1. Create feature branch from `dev`
2. Open PR targeting `dev`
3. Merge to `dev` — test on a dev-provisioned cluster
4. When ready for production: PR from `dev` to `main`, review, merge

### Releasing to production

Open a PR from `dev` to `main`. The PR diff shows everything changed since the last release. One review, one merge, production is updated.

## Hardcoded `main` references

There are **25 `raw.githubusercontent.com` URLs** in the showroom content that hardcode `main`:

```
bash <(curl -sL https://raw.githubusercontent.com/rhpds/openshift-days-ops-showroom/main/support/...)
```

These appear in modules: 04-network-security, 05-debugging, 07-ldap, 08-oidc, 09-observability, 10-performance-tuning, 11-virtualization.

Plus 1 in `support/05-debugging/deploy-broken-apps.sh`.

### Options for handling these

**Option A — Leave them pointing at `main` (recommended to start)**
Support scripts are stable. Content changes rarely require matching script changes. Students always get the production version of scripts. If a dev-branch content change needs a matching script change, merge the script to `main` first.

**Option B — Parameterize with an Antora attribute**
Replace `main` in URLs with `{showroom_git_ref}`, injected by `inject-env-vars.sh` from the AgnosticV ref. Ensures dev deployments pull dev scripts. More correct but touches 25+ lines across 7 files.

**Option C — Move scripts into automation repo**
Deploy support scripts to the cluster via Ansible at provision time instead of curling them at runtime. Eliminates the problem entirely but is a larger refactor.

Start with Option A. Move to B if script/content mismatches become a problem.

## GitHub Actions

The `gh-pages.yml` workflow triggers on push to `main` and builds the GitHub Pages preview site. This is correct — the preview site should reflect production.

If a dev preview is wanted later, add a second workflow that builds from `dev` and deploys to a different GitHub Pages path or environment.

## Steps to implement

1. Create `dev` branch from `main` in the showroom repo
2. Set `dev` as the default branch on GitHub (so PRs target `dev` by default)
3. Update `dev.yaml` in AgnosticV to point showroom ref at `dev`
4. Let Michael and Jimmy know — PRs now go to `dev`, production releases go `dev` → `main`
5. Optionally: repeat for the automation repo
