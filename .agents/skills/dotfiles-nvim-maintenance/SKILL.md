---
name: dotfiles-nvim-maintenance
description: >-
  Audit, maintain, or upgrade this repository's Neovim configuration for explicit
  maintenance, audit, or upgrade requests. Use for upkeep of packages, loading behavior,
  dependencies, workflows, and health reports. Routine configuration edits use existing
  repository guidance; do not apply this skill to unrelated repositories.
---

# Dotfiles Neovim maintenance

Keep the requested scope explicit. Audits produce findings and recommendations; do not update or
remove plugins as an audit side effect. Update requests include implementing and verifying the
authorized changes. Creating or using this skill does not authorize unrelated upgrades, removals, or
automatic update jobs.

For removal-only requests, use **Remove installed plugins with the native API** below instead of the
audit discovery, upstream research, and before/after health requirements. Reuse facts already
verified in this session; recheck the mutable package spec, lockfile, and target directories.

## Establish the current state

- Read [the Neovim README](../../../nvim/README.md), startup imports in
  `nvim/.config/nvim/init.lua`, package registrations and lazy groups in `lua/plugins/spec.lua`, and
  the tracked `nvim-pack-lock.json` under that config directory. Follow imports through affected
  core, plugin, LSP, DAP, and filetype modules.
- Inspect `lua/plugins/config.lua` and `lua/plugins/lazy.lua` for startup hooks, mapping
  registration, and deferred setup. Read affected executable checks in `lua/core/tools.lua`,
  defaults and overrides in `lua/core/paths.lua`, and the relevant documentation under `nvim/docs/`.
- Identify the Neovim version and actual config, data, state, and cache paths, including deployment
  symlinks and the installation's lockfile. Compare installed package names and revisions with the
  repository specification and lockfile. Treat installation drift separately from configuration
  defects; startup can repair a lockfile from installed package metadata.
- Read current audit status and dated reviews, but verify their findings against the present
  configuration. Historical package counts, revisions, and recommendations are not current facts.
  Preserve unrelated working-tree changes.

## Assess changes and preserve architecture

- Verify authoritative upstream documentation, release notes, commit history, and relevant
  unresolved bugs for the locked or proposed revision and its intended branch. Link evidence and
  record revision, version, and date limits; do not treat an inaccessible source or a default-branch
  snapshot as verification of another branch.
- Evaluate compatibility with the configured Neovim version, dependencies, APIs, and documented
  workflows. Commit age alone does not establish abandonment or justify replacement.
- Retain native `vim.pack`, startup ordering, configured lazy groups, executable overrides, and
  documented workflows unless the requested maintenance calls for changing them. Prefer native APIs
  and existing plugin capabilities over substantial custom implementations.
- Keep package registrations, shared dependencies, lazy-group entries, imports, configuration,
  mappings, executable checks, and documentation aligned. Before removing a shared dependency, check
  every remaining consumer.
- For scoped updates, update only the requested packages and necessary dependencies. Preserve
  unrelated locked revisions and intentional branch constraints. Inspect the resulting lockfile diff
  rather than accepting incidental churn.

## Validate in isolation

Use disposable XDG config, data, state, and cache directories and fixture projects for startup and
plugin execution. Copy configuration and package data rather than linking writable paths back to the
live installation or repository; isolate any additional write paths used by affected features. Keep
a before/after copy of the tracked lockfile to detect unexpected changes. Stage packages at the
revisions being evaluated and identify whether a check covers locked, installed, or proposed
revisions. Do not let an audit bootstrap newer packages silently.

Exercise affected loading paths: empty startup, first existing or new file, relevant filetypes, and
first-use mappings as applicable. Load optional plugins through the configured groups and setup
paths. Verify mapping registration and behavior, dependencies, executable overrides, and
missing-tool behavior for the changed features. Use fixtures for edits, search, formatting, and
other writes. Report interactive UI or platform behavior that cannot be verified in this
environment.

### Required health checks

- For whole-config maintenance and audits, run full `:checkhealth`. For changes, capture a baseline
  before implementation and repeat after implementation; audit-only requests need the baseline. Load
  relevant optional plugins through configured lazy groups before running checks so their
  healthchecks are included.
- For scoped maintenance, run relevant providers, such as `:checkhealth vim.lsp vim.treesitter`,
  plus affected plugin healthchecks. Capture a baseline and repeat after changes.
- Run these checks in the disposable configuration. Allow the health run to finish, capture the
  completed report, and inspect its contents; process exit status alone does not establish health.
  Record which providers and plugin checks actually ran, including failures to load or finish.
- Separate new regressions, existing issues, missing optional tools, and environment restrictions.
  Fix failures introduced by the change. Report unrelated findings without expanding scope or
  installing every optional provider. State any checks or behavior that remain unverified.

## Remove installed plugins with the native API

Removal is part of an authorized removal or replacement request, never audit-only work.

1. Compare the spec, lockfile, and installed directory names in one batch. Confirm the exact
   selected managed names, Neovim version, config/data paths, and lockfile. Search configuration for
   remaining consumers, including shared dependencies. Read only affected modules and current
   inventory/status; skip unrelated modules, historical audits, and removed plugins' upstream
   histories. The installed version's local `:help vim.pack.del()` is sufficient removal guidance.
2. Save the current lockfile for comparison. Remove any remaining specifications, lazy-group
   entries, imports, mappings, and obsolete configuration for the selected packages. If these are
   already absent, proceed directly to cleanup.
3. In a fresh session where the selected packages are inactive, run `vim.pack.del({ ... })` once
   with all selected names. A headless `-u NONE -i NONE` session avoids full-config startup and
   unrelated bootstrap or UI failures. Set config/data paths explicitly to target the actual package
   store and intended lockfile; if no deployed config exists, the repository's `nvim/.config` can be
   used as `XDG_CONFIG_HOME`. Never force-delete active plugins or delete every inactive package.
4. Verify the selected directories and lock entries are absent and every remaining lock entry is
   unchanged, including revisions and branch constraints. Let `vim.pack.del()` perform both
   removals; manual directory deletion or JSON-only edits can cause packages to reappear. Do not
   synchronize or inspect every remaining installed revision unless drift affects this removal.
5. Scale validation to what changed:
   - **Stale-package cleanup:** when registrations, imports, and consumers were already absent and
     no executable configuration changed, inventory checks and the exact lockfile comparison are
     sufficient. Skip disposable removal rehearsals, full package copies, startup fixtures, health
     baselines, and replacement-feature UI tests.
   - **Configuration removal:** run one disposable startup and `:checkhealth vim.pack`, plus one
     focused smoke check if a retained feature's dependency or loading path changed. Use the
     isolation rules above, but do not repeat the full before/after audit or test unrelated
     replacements.

   Expand checks only for new failures attributable to the removal. Reuse established environment
   limitations; do not repeatedly retry known socket restrictions or build custom health reporters.
6. Update only affected inventory/counts and current status with a short cleanup note; leave dated
   reports historical. Format touched files, inspect the diff, and report exact removals and any
   incomplete installed cleanup. A disposable test or repository edit alone does not uninstall the
   actual packages.

## Documentation and reporting

Update affected README guidance, plugin inventory, keymaps, workflows, and current audit status as
part of maintenance changes. Derive package and group counts from the configuration instead of
copying historical totals. Keep dated reports clearly historical; record resolutions in current
status without presenting old findings as present defects.

Use [dotfiles-formatting](../dotfiles-formatting/SKILL.md) for formatter selection, scoped checks,
and repository formatting conventions.

Report changes or audit findings, linked upstream evidence, checks performed and their findings, and
verification limits. Distinguish repository changes, installed-package cleanup, and disposable test
results. Identify incomplete cleanup and unavailable health or behavioral checks without claiming
success from an exit code or an untested recommendation.
