# Repository settings (set by hand)

The CI gate only decides; GitHub enforces. Set these once the repo exists.

## General

- **Allow auto-merge**: on. Squash merging only; delete branches on merge.
- **Actions → General → Workflow permissions**: read-only by default. The
  workflow raises its own permissions per job.
- **Actions → Fork pull request workflows**: leave "Require approval for
  first-time contributors" on. The gate runs on `pull_request_target` and
  never executes PR content, but there's no reason to run it for drive-by
  forks without a look.

## Ruleset for `main`

- Restrict deletions; block force pushes.
- **Require a pull request before merging**:
  - required approvals: **0**
  - **require review from Code Owners**: on. `.github/CODEOWNERS` owns
    everything except `peers/`, so a PR touching anything else (workflow,
    README, CODEOWNERS itself) needs a review from `@oscrx`, while a
    peers-only PR doesn't.
  - dismiss stale approvals on new commits: on
- **Require status checks to pass**: the `check` job of the `check`
  workflow, and require branches to be up to date.
- Bypass list: only the repository admin (Oscar), for emergencies.

> **Verify after setup.** Checks from a `pull_request_target` run must count
> as the PR's required status check. Open a test PR and confirm that the
> `check` job appears on it and blocks merging while it fails. If it
> doesn't, switch the trigger to `pull_request`. The gate is then defined by
> the PR's own copy of the workflow, so this is only safe together with
> Code Owners review on `.github/`, which a workflow change needs anyway,
> and the App lacking the `workflows` permission.

## Registry access

`git.dn42.dev` doesn't allow anonymous clones. Either:

- create a read-only access token for your registry account and store it
  as the Actions secret **`DN42_REGISTRY_TOKEN`** (the gate then checks
  against the live registry), or
- keep `registry/asns.txt` in `main` current. It is one ASN per line, made
  from an authenticated clone with `ls data/aut-num > registry/asns.txt`.
  It is the fallback when the secret is missing.

The list is read from `main`, never from the PR, so a PR can't add its own
ASN to it.

## The autopeer GitHub App

- Installed on this repository only.
- Permissions: **Contents: read & write**, **Pull requests: read & write**,
  **Metadata: read**. **Not** Workflows, so GitHub itself refuses any push by
  the App that changes `.github/workflows/`. Not Administration.
- Its bot login (`<app-slug>[bot]`) goes in `APP_LOGIN` in
  `.github/workflows/check.yml`. The gate only offers auto-merge to PRs from
  exactly that login.

## ArgoCD

The Application syncing this repo gets its own AppProject that allows only
the `DN42Peer` kind and only the `dn42` namespace. A merged file that
somehow passed the gate can then still never create anything else.

## Still to do when going public

- Tag a dn42-operator release and set `PEERCHECK_VERSION` to it. Until then,
  `go install ...@v0.1.0` in the workflow fails; use `hack/check.sh` locally.
- Actions are pinned to commit SHAs (checkout v7.0.1, setup-go v7.0.0);
  let Renovate bump them.
- Fill `registry/asns.txt` (or set the token secret). Today it holds only
  the nine seed ASNs and is unverified against the real registry.
