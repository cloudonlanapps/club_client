# Contributing to club_core

This project is **stable**. To keep it that way, all changes must be tracked through GitHub Issues. There are no exceptions — even small fixes get an issue.

## The golden rule

> **No code change without an issue. No merge without a PR linked to that issue.**

This applies to bugs, features, refactors, docs, dependency bumps, CI tweaks — everything.

**Exception:** Edits to any `CLAUDE.md` file (the root one or any module-scoped `<module>/CLAUDE.md`), to `CONTRIBUTING.md`, or to files in `docs/` do not require an issue. These are process / config / documentation files, not product code — commit directly to `main`.

---

## Workflow

```
1. Open issue (bug / feature / task template)
   ↓
2. Triage: scope it, and give it a priority
   ↓
3. Create branch from main
   ↓
4. Implement + test locally
   ↓
5. Open PR linked to the issue ("Fixes #N")
   ↓
6. Review → merge to main
   ↓
7. Promote main → release on schedule (manual)
```

**Testing locally (step 4):** the `justfile` is the task runner (requires just ≥ 1.27; `just --list` for the grouped menu). Use `just unit-test-all` for package unit/widget tests and `just app-test-<target>` (`linux` / `macos` / `web` / `android`) for app integration. Every server-backed recipe spins up its own isolated test stack, so runs never collide. Full setup in [`app/docs/QUICK_START_TEST.md`](app/docs/QUICK_START_TEST.md). The SDK (`club_sdk_2`) is developed and tested in its own repo, `cloudonlanapps/club_sdk`.

## 1. Open an issue

Use one of the templates at <https://github.com/cloudonlanapps/club_client/issues/new/choose>:

| Template | When to use |
|---|---|
| **Bug report** | Something is broken or behaving incorrectly |
| **Feature request** | New capability or enhancement |
| **Task / chore** | Refactor, docs, tooling, dependency bump, CI |

Blank issues are disabled. If your work doesn't fit any template, the closest match is **Task**.

## 2. Triage

Triage means:

1. Verify it is reproducible / well-scoped
2. Decide its priority. **Priority and order of work are not GitHub labels**:
   they are tracked outside GitHub. SDK work is high, app UI work is low, and a
   task that must wait for another names it.
3. Move its status label to `status:ready` once the scope is agreed (see
   [Labels](#labels))
4. Optionally assign to a person

### Labels

This section is the single source for labels on this repo; `CLAUDE.md` points
here.

**Status — required.** Every open issue carries exactly one `status:*` label.
Closed issues carry **none**: closing is the terminal state, so the label is
removed at close, not replaced (there is no `status:done`).

| From | To | When |
|---|---|---|
| (none) | `status:triage` | Automatically, when the issue is filed from a template |
| `status:triage` | `status:ready` | Triage done; scope agreed |
| `status:ready` | `status:in-progress` | The feature branch is created and work starts |
| `status:in-progress` | `status:blocked` | Waiting on an external dependency or decision |
| `status:in-progress` | `status:needs-info` | Waiting on the reporter or user for an answer |
| `status:blocked` / `status:needs-info` | `status:in-progress` | Unblocked; work resumed |
| any `status:*` | (removed) | The PR merges and closes the issue, or the issue is closed by hand |

Change a status by removing the old label and adding the new one in one call:

```bash
gh issue edit N --remove-label "status:ready" --add-label "status:in-progress"
gh issue edit N --remove-label "status:in-progress"   # after the merge closes N
```

**Kind — optional.** `bug`, `enhancement`, `documentation` and the other
GitHub defaults say what kind of change an issue is. Use them when they help;
nothing depends on them.

**Priority — not a label.** Priority and order of work are tracked outside
GitHub (step 2 above).

## 3. Branch naming

Branches must include the issue number:

```
<type>/<issue-number>-<short-slug>
```

Examples:

```
bug/42-login-redirect-loop
feature/57-enrollment-flow
task/61-bump-flutter
```

Always branch **from `main`**, never from `release`.

## 4. Commits

- Write commits in the imperative mood: *"fix login redirect"*, not *"fixed login"*
- Reference the issue in the body when context helps: `Refs #42`
- Keep commits focused; squash trivial fixups before opening the PR

## 5. Pull requests

- **Title:** clear, < 70 characters
- **Body:** must include `Fixes #N` (or `Closes #N` / `Refs #N`) so GitHub auto-links and auto-closes
- **Target branch:** `main` (never `release` directly)
- **One issue per PR** when possible. Bundling is OK only if issues are tightly related.
- All CI checks must pass before merge
- At least one human review for non-trivial changes

## 6. Merging

- Merge to `main` is human-gated — no auto-merge
- **Default: squash merge.** `gh pr merge <num> --squash`. The repo no longer allows `--merge` (the option is disabled in repo settings). A merge-commit on a PR branched off `dev` and targeted at `release` once silently dragged 40 ancestry commits from `dev` into `release` — squash filters that second-parent ancestry so only the PR's own diff lands.
- **Use `--rebase` only for an intentional, individually-meaningful commit series.** Default to squash unless you specifically curated the commits and want each preserved on the target branch.
- **Never `--merge`.** Repo setting now blocks it; the dropdown won't even show the option.
- **Do not delete the feature branch on merge.** Branches stay on the remote so the PR's commits remain reachable for archaeology (`gh pr view <num>` still works, but local checkouts of the branch ref need it to exist).
- `release` is updated by promoting `main` → `release` on a separate cadence (manual). The same squash-default applies — and matters most here, since this is the path where ancestry-leaks bite hardest.
- Never push directly to `main` or `release`

## 7. Closing issues

- An issue is closed automatically when a PR with `Fixes #N` is merged; then remove its `status:*` label (see [Labels](#labels))
- If an issue is invalid or won't be done, close it with a comment explaining why, remove its `status:*` label, and apply `wontfix` if appropriate

---

## Working with Claude Code

This repo uses [Claude Code](https://claude.com/claude-code) locally as part of the development workflow. Claude is invoked from a developer's terminal and uses the `gh` CLI to interact with issues and pull requests.

A typical Claude-assisted session looks like:

```
You: "implement issue #42"
Claude:
  → gh issue view 42
  → creates branch bug/42-...
  → reads relevant code, edits, runs tests
  → commits
  → confirms with you
  → pushes branch
  → gh pr create --title ... --body "Fixes #42"
```

Conventions Claude must follow on this repo:

1. **Always work from an issue.** If asked to make a change without an issue, Claude should propose creating one first.
2. **Always branch from `main`.** Never `release`.
3. **Never push, open PRs, or merge without explicit user confirmation.**
4. **Always link PRs to their issue** with `Fixes #N` in the PR body.
5. **Never merge to `release`.** That's a human-only operation.

These conventions are also documented in `CLAUDE.md` so Claude picks them up automatically in every session on this repo.
