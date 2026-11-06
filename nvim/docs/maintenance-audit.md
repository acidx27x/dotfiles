# Neovim maintenance and custom-code audit

## Implementation status — 2026-11-06

The requested migration is implemented. The current spec contains **46 repositories: 28 eager and 18
optional**, including 15 Mini modules. Plenary, Harpoon, Snipe, and Navic remain. The tracked
lockfile and actual installed package store now match all 46 configured names after the unused
package cleanup below. All remaining locked revisions and branch constraints were preserved.

- Spectre is replaced by grug-far with the ripgrep engine, case-insensitive searching, executable
  overrides, cwd capture, Normal toggle, and Visual search prefilling. The `sd` check is removed.
- Actions Preview and its lazy group are removed. `<C-s>ca` uses fzf-lua's built-in code-action diff
  previewer; native `gra` is preserved. The unused diff-so-fancy override is removed.
- MiniNotify initializes before feature modules. It retains native formatting and durations, wraps
  within 80 columns, and **enables built-in LSP-progress notifications with upstream defaults**.
  `<Space>nd` clears active messages; `MiniNotify.show_history()` and `get_all()` expose history.
- Native parent/child selection replaces the custom node stack. The aliases explicitly mirror native
  `an`/`in`'s parser check for LSP fallback; mappings no longer depend on highlighting.
- Save cleanup uses `MiniTrailspace.trim_last_lines()` in the target buffer. BTab opens exact buffer
  IDs with `:tab sbuffer`; CTags uses asynchronous `vim.system` with captured cwd and output.
- Navic keeps attachment, clicks, depth limits, and global-scope text. Its renderer uses aggregate
  `getwininfo().textoff`; Oil keeps its own winbar.
- `<Space>pp` uses fzf-lua's built-in grep picker for a fixed set of project TODO markers. The
  Hipatterns project scanner and its dedicated tests were removed in the follow-up simplification.
  MiniHipatterns retains in-buffer marker and hex-color highlighting; it no longer drives search.

### Validation of the implementation

All plugin sources were staged at locked revisions in disposable XDG config/data/state/cache paths.
Available local Git objects were exported; missing sources were downloaded as archives. The live
installation was not updated. The tracked lockfile was checked independently for inventory and
unchanged unrelated revisions.

- Lua syntax checks passed. The follow-up project-search fixture checks the actual fzf-lua grep
  provider with ripgrep for standalone markers, hidden and ignored files, `.git` exclusion, saved
  disk contents, executable overrides, missing-ripgrep handling, and standard result positions.
- Headless workflow fixtures cover BTab identity for named/unnamed/modified/terminal buffers,
  completion and invalid input; final-blank cleanup for ordinary/empty/whitespace-only/binary/
  special/non-current buffers; manual/autosave formatting coordination and Navic gutter alignment;
  and CTags success/failure, a spaced override path, cwd, and output.
- MiniNotify fixtures cover wrapping, capped width, dismissal/history, simultaneous progress tasks,
  begin/report/end updates, native completion expiry, and ordinary messages during progress.
- Selection fixtures cover parent growth, child shrinkage, counts, UTF-8 text, rename coexistence,
  and dispatch to LSP fallback without a parser.
- Real grug-far fixtures exercise case-insensitive replacement, file filters, toggle, selected-text
  prefilling, and missing-ripgrep handling.
- A live clangd fixture exercises fzf-lua's real code-action provider, diff generation and applying
  actions for both cursor and Visual ranges. Progress events were also checked with that client.
- The original Hipatterns scanner/picker checks are superseded by the simpler native grep-provider
  fixture. The custom scanner, previewer, streaming callbacks, cancellation hooks, and tests are
  gone.

Scoped dprint checks and `git diff --check` passed. The lockfile is excluded by dprint configuration
and was validated as JSON and compared entry by entry instead.

The environment denies fzf-lua's local RPC socket, including an escalated attempt. Headless tests
preseeded its server variable and intercepted the terminal UI, while using real provider/preview/
action code. Full interactive fzf rendering and terminal key navigation remain unverified. BTab
fixtures also encountered an existing `BufWinLeave`/`mkview` error when closing a tab over an
unnamed buffer; fixture teardown bypassed that hook. The unrelated view-restoration code is
unchanged.

### Floaterm cleanup — 2026-11-05

Floaterm's registration, lazy group, setup module, and mappings were already absent. Removed the
remaining `floaterm` and `volt` packages with `vim.pack.del({ "floaterm", "volt" })` in a fresh
session where both were inactive, following the installed Neovim 0.12.6 removal instructions. Volt
is declared by
[Floaterm's locked README](https://github.com/nvzone/floaterm/blob/4f24e90f1281d6a848c96adb6501573c8e0e406b/README.md)
and has no remaining configured consumers. The removed revisions were `4f24e90f12` (Floaterm) and
`4351c5cd79` (Volt).

The actual target was `/home/acidx27x/.local/share/nvim/site/pack/core/opt`; both directories are
confirmed absent. No deployed `/home/acidx27x/.config/nvim` exists in this environment, so the
cleanup used this repository's `nvim/.config` as `XDG_CONFIG_HOME` to update its tracked lockfile
through the native API. Exactly those two lock entries were removed; all other 53 entries, including
revisions and branch constraints, were preserved. Seven other stale entries were left outside this
request.

Before/after checks used copied configuration and installed package data in disposable XDG paths;
they cover installed revisions, not synchronization to every locked revision. Completed
`:checkhealth vim.pack vim.treesitter` reports contained no warnings or errors. Package health
reported the unrelated inactive stale packages. Neither removed plugin supplies a healthcheck. Empty
startup, existing/new text files, buffer-UI lazy loading, and the native `<Space>tt/tv/th` terminal
tab/split mappings passed, including terminal options and successful-exit buffer cleanup. Terminal
exit also exposed an `Invalid buffer id` error in the unchanged `TermClose` callback
(`core/autocmds.lua`); the buffers were deleted, but this callback issue remains outside the
removal. The fzf-lua RPC socket was denied even with elevated execution; these checks preseeded its
server variable only in the test process. Interactive picker rendering and terminal key delivery
remain unverified.

### Unused-package cleanup — 2026-11-06

On the macOS installation, removed 15 stale packages with `vim.pack.del()`: `actions-preview.nvim`,
`floaterm`, `hardtime.nvim`, `indent-rainbowline.nvim`, `lspkind.nvim`, `mini.extra`,
`mini.indentscope`, `mini.pick`, `neo-tree.nvim`, `nui.nvim`, `nvim-notify`, `nvim-spectre`,
`nvim-web-devicons`, `vague.nvim`, and `volt`. All were already absent from the configuration and
had no remaining configured consumers. Neovim 0.12.6 ran the removal in a fresh session with the
repository config path and `/Users/acidx27x/.local/share/nvim` as the data path; the deployed
lockfile links to the repository lockfile. The spec, lockfile, and installed directories now agree
on 46 names. An exact before/after comparison confirmed every retained lock entry was unchanged,
including pre-existing revision changes and branch constraints. No executable configuration changed;
validation used inventory and lockfile comparisons without startup or health checks.

The earlier Linux cleanup and validation are recorded below.

Removed `actions-preview.nvim`, `indent-rainbowline.nvim`, `lspkind.nvim`, `mini.extra`,
`mini.pick`, `nvim-notify`, and `nvim-spectre` with the native `vim.pack.del()` API, following
[Neovim's removal sequence](https://neovim.io/doc/user/pack/#vim.pack-examples). Their
registrations, imports, mappings, and remaining consumers were already absent. fzf-lua, IBL,
MiniIcons, MiniNotify, and grug-far retain the replacement workflows.

The actual target remained `/home/acidx27x/.local/share/nvim/site/pack/core/opt`, with this
repository's `nvim/.config` as `XDG_CONFIG_HOME` because no deployed config directory exists here.
Removal ran in a fresh session with all seven packages inactive. The installed directories are
confirmed absent, and the specification, tracked lockfile, and package store match all 46 names.
Exactly seven lock entries were removed; every remaining entry is unchanged. The 46 installed
revisions also match their tracked lockfile revisions.

Before/after checks used copied configuration and installed package data in disposable XDG paths on
Neovim 0.12.6. They exercise installed revisions without updating packages. Completed
`:checkhealth vim.pack grug-far` reports show package health passing; the seven inactive leftovers
reported before removal are gone afterward. Grug-far reports the same missing optional `ast-grep`
tool, while required ripgrep is present. fzf-lua has no discoverable `:checkhealth fzf-lua` provider
at this installed revision; its bundled `_health.check()` was invoked directly instead. Its report
confirms required tools and MiniIcons are present, reports the known denied RPC socket, and lists
missing optional media preview tools `viu`, `chafa`, and `ueberzugpp`.

Empty startup and first existing/new text files passed. Checks exercised the real grug-far toggle,
MiniNotify add/history/clear, MiniIcons LSP-kind lookup, IBL lazy setup, replacement mapping
registration, and fzf-lua code-action provider availability. The known RPC-socket restriction still
requires a preseeded fzf-lua server variable in the disposable test process; interactive picker
rendering and code-action selection are not covered by these checks.

The original findings below are retained as historical context. Their package counts and replacement
recommendations describe the configuration before this implementation.

## Original audit

Audited on 2026-11-05. Scope: every Lua configuration file, the package spec, the lockfile, and the
existing Neovim documentation. No plugin, lockfile, or configuration changes were made.

The current spec and lockfile agree on **47 repositories: 28 eager and 19 optional**, including 14
Mini modules. The older plugin inventory says 46 and the older review contains references to
MiniPick that no longer describe the current package spec.

## Recommended order

1. Replace the broken Actions Preview integration with fzf-lua's code-action previewer.
2. Replace the custom Tree-sitter selection implementation with Neovim 0.12's native API.
3. Replace Spectre with grug-far; then assess Harpoon's Plenary dependency separately.
4. Consider replacing Notify with Snacks notifier or MiniNotify.
5. Consider Dropbar if reducing breadcrumb integration code matters more than retaining the current
   exact appearance.

The clearest upstream maintenance problem is **Plenary's explicit end-of-maintenance notice**.
Spectre, Notify, and Snipe have long gaps in their visible default-branch histories. That is a
reason to evaluate alternatives, but it does not establish that every quiet plugin is broken or
abandoned.

## Evidence and limits

Public upstream READMEs and commit histories were checked through the browser. Dates below mean the
newest commit visible in the retrieved history, not a guarantee that the browser cache is current.
The GitHub API was blocked even after an escalated retry. Some history URLs also failed; local
commit metadata was used where indicated, with Git lazy fetching disabled. Local dates are committer
dates, which can differ from the browser's displayed author dates by a day.

`L` means the date of the exact locked revision inspected locally. It does **not** establish the
current upstream tip. `H` means a date observed in the upstream default-branch history. Mini's split
repositories were assessed together with the actively updated parent project; the table also records
each available locked revision individually.

The live package directory differs from this checkout: fzf-lua and mini.files are absent there, old
mini.pick remains, and some locked objects are unavailable. A full startup of the live config would
therefore conflate installation drift with config quality. It was not run, nor were packages
updated. The analysis concerns reproducibility from this repository's spec and lockfile.

## All 47 plugins

Each plugin name links to its upstream. For `H` dates, the repository's `/commits` page is the
source. The two highest-priority maintenance signals are linked again in the detailed findings
below.

| Plugin                                                                             | Evidence date       | Assessment and recommendation                                                                                                     |
| ---------------------------------------------------------------------------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [actions-preview.nvim](https://github.com/aznhe21/actions-preview.nvim)            | H 2026-04-22        | Compatibility work exists. Replace this integration because its only configured backend is missing; reuse fzf-lua.                |
| [auto-save.nvim](https://github.com/okuuva/auto-save.nvim)                         | H 2026-10-27        | Keep. Recent save-condition fixes; already uses the maintained fork.                                                              |
| [blink.cmp](https://github.com/saghen/blink.cmp)                                   | H 2026-10-30        | Keep, but explicitly choose whether to accept v2 development-branch churn.                                                        |
| [blink.lib](https://github.com/saghen/blink.lib)                                   | H 2026-09-07        | Keep with Blink v2. Dependency, not duplicate completion functionality.                                                           |
| [conform.nvim](https://github.com/stevearc/conform.nvim)                           | H 2026-08-11        | Keep. Formatter dispatch and LSP fallback already match this configuration's needs.                                               |
| [friendly-snippets](https://github.com/rafamadriz/friendly-snippets)               | H 2026-10-27        | Keep if its snippets are used. No need to add another snippet engine for this setup.                                              |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua)                                     | H 2026-10-21        | Keep. Existing picker can absorb code-action previews and optional buffer/TODO searches.                                          |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)                        | H 2026-11-05        | Keep. No maintenance reason to replace its extensive configured Git actions.                                                      |
| [goto-preview](https://github.com/rmagatti/goto-preview)                           | H 2025-12-26        | Watch; keep if editable floating previews are useful. A picker preview is a different interaction.                                |
| [harpoon](https://github.com/ThePrimeagen/harpoon)                                 | L 2025-10-31        | Consider mini.visits to move away from Plenary. Exact current harpoon2 tip could not be verified.                                 |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim)    | L 2026-09-04        | Keep for its current scope and tinted-whitespace behavior. Retrieved history was older than the lock.                             |
| [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim)                          | H 2026-05-10        | Keep. A mature theme does not need frequent feature commits.                                                                      |
| [leap.nvim](https://codeberg.org/andyg/leap.nvim)                                  | L 2026-09-27        | Keep. Spec already follows its move to Codeberg. Current Codeberg history was inaccessible.                                       |
| [logger.nvim](https://github.com/rmagatti/logger.nvim)                             | H 2025-03-09        | Keep only while needed by goto-preview. Small dependency; age alone is insufficient evidence of a problem.                        |
| [matchparen.nvim](https://github.com/monkoose/matchparen.nvim)                     | H 2026-10-13        | Keep. Recently maintained. Built-in matchparen is an optional simplification with different behavior.                             |
| [mini.bufremove](https://github.com/nvim-mini/mini.bufremove)                      | L 2026-10-13        | Keep. Preserves window layout when deleting buffers.                                                                              |
| [mini.clue](https://github.com/nvim-mini/mini.clue)                                | L 2026-10-22        | Keep. Current configuration deliberately refreshes late buffer mappings.                                                          |
| [mini.comment](https://github.com/nvim-mini/mini.comment)                          | L 2026-10-27        | Healthy; optional removal in favor of native commenting, subject to textobject and spacing differences.                           |
| [mini.files](https://github.com/nvim-mini/mini.files)                              | Parent H 2026-10-22 | Healthy; choose based on whether its column navigation adds value beside Oil. Locked object unavailable locally.                  |
| [mini.hipatterns](https://github.com/nvim-mini/mini.hipatterns)                    | L 2026-10-20        | Keep. Used for markers, hex colors, and the custom buffer picker.                                                                 |
| [mini.icons](https://github.com/nvim-mini/mini.icons)                              | L 2026-10-23        | Keep. Shared icon provider.                                                                                                       |
| [mini.move](https://github.com/nvim-mini/mini.move)                                | L 2026-10-27        | Keep. No reason to trade a small maintained module for custom movement code.                                                      |
| [mini.operators](https://github.com/nvim-mini/mini.operators)                      | L 2026-10-27        | Keep. Current evaluate/exchange/multiply/replace/sort configuration is focused.                                                   |
| [mini.pairs](https://github.com/nvim-mini/mini.pairs)                              | L 2026-10-13        | Keep unless syntax-aware pairing is a concrete requirement.                                                                       |
| [mini.splitjoin](https://github.com/nvim-mini/mini.splitjoin)                      | L 2026-10-27        | Keep. No maintenance issue established.                                                                                           |
| [mini.statusline](https://github.com/nvim-mini/mini.statusline)                    | L 2026-10-13        | Keep, including the small diagnostic/encoding presentation callbacks.                                                             |
| [mini.surround](https://github.com/nvim-mini/mini.surround)                        | L 2026-10-27        | Keep. Existing custom mappings do not justify a migration.                                                                        |
| [mini.tabline](https://github.com/nvim-mini/mini.tabline)                          | L 2026-10-13        | Keep. The custom label is a preference, not a missing framework.                                                                  |
| [mini.trailspace](https://github.com/nvim-mini/mini.trailspace)                    | L 2026-10-13        | Keep; can also replace the custom end-of-file blank-line removal loop.                                                            |
| [multinput.nvim](https://github.com/r0nsha/multinput.nvim)                         | H 2026-04-15        | No confirmed abandonment. GitHub identifies itself as a Tangled mirror; consider Snacks input only if its behavior is sufficient. |
| [no-neck-pain.nvim](https://github.com/shortcuts/no-neck-pain.nvim)                | H 2026-09-26        | Keep. Current scratch-pad side buffers make a simple zen-mode swap behaviorally different.                                        |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap)                               | H 2026-09-11        | Keep. Active debugger client.                                                                                                     |
| [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)                             | H 2026-07-14        | Keep. Current DAP integration is short and conventional.                                                                          |
| [nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text)        | H 2025-05-25        | Watch; keep if useful. No verified better maintained equivalent was established in this audit.                                    |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)                         | H 2026-11-02        | Keep. Modern vim.lsp.config usage still benefits from its server defaults.                                                        |
| [nvim-navic](https://github.com/SmiteshP/nvim-navic)                               | H 2026-09-02        | Maintained. Dropbar is an optional integration improvement, not an abandonment fix.                                               |
| [nvim-nio](https://github.com/nvim-neotest/nvim-nio)                               | H 2026-07-15        | Keep while required by DAP UI. Recent compatibility fix.                                                                          |
| [nvim-notify](https://github.com/rcarriga/nvim-notify)                             | H 2025-09-06        | Replacement candidate: Snacks notifier or mini.notify. Preserve dismiss/history behavior deliberately.                            |
| [nvim-spectre](https://github.com/nvim-pack/nvim-spectre)                          | H 2025-05-13        | Strong replacement candidate: grug-far, due to the long activity gap plus Plenary dependency.                                     |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)              | H 2026-10-31        | Keep main. Current upstream is active; older archival reports are no longer sufficient grounds to replace it.                     |
| [oil.nvim](https://github.com/stevearc/oil.nvim)                                   | H 2026-10-12        | Keep as configured default explorer. Consolidating explorers is a workflow choice.                                                |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)                           | L 2026-04-10        | Explicitly no longer actively maintained; plan to remove by migrating consumers first.                                            |
| [smartcolumn.nvim](https://github.com/m4xshen/smartcolumn.nvim)                    | H 2026-09-13        | Keep for dynamic column visibility and EditorConfig behavior. Recent commits include documentation changes.                       |
| [snipe.nvim](https://github.com/leath-dub/snipe.nvim)                              | H 2025-09-18        | Optional consolidation into existing fzf.buffers; loses persistent one-key buffer tags.                                           |
| [symbol-usage.nvim](https://github.com/Wansmer/symbol-usage.nvim)                  | H 2026-04-06        | Keep if its reference counts are used. It received a compatibility fix; built-in CodeLens is server-dependent.                    |
| [visimatch.nvim](https://github.com/wurli/visimatch.nvim)                          | H 2026-10-05        | Keep. Selection matching differs from LSP document-symbol highlighting.                                                           |
| [visual-whitespace.nvim](https://github.com/mcauley-penney/visual-whitespace.nvim) | H 2026-06-05        | Keep for selection-specific whitespace. Native listchars is simpler but does not preserve that behavior.                          |

## Replacements worth making or evaluating

### Actions Preview: reuse fzf-lua

[`actions-preview-nvim-config.lua`](../.config/nvim/lua/lsp/actions-preview-nvim-config.lua), line
14, sets `backend = { "minipick" }`. Neither the spec nor the lockfile includes mini.pick. The
installed backend explicitly checks for it and otherwise raises
`actions-preview: No backend available`. A clean headless invocation of the backend selector
reproduced that failure.

This is a configuration defect, not proof that Actions Preview is unmaintained: its
[history includes Neovim compatibility work in April 2026](https://github.com/aznhe21/actions-preview.nvim/commits).
The preferred replacement is `require("fzf-lua").lsp_code_actions`, using the existing picker and
its [code-action previewer](https://github.com/ibhagwan/fzf-lua#customization). This can remove
Actions Preview's spec/group, config module, and the diff-so-fancy check on that mapping. The
alternative is to restore mini.pick and keep the existing preview workflow.

Validate normal and visual-range actions, unresolved actions, and preview diffs with the configured
servers. Native `gra` currently uses vim.lsp.buf.code_action, so it should be considered alongside
the custom mapping when deciding how consistent the UI should be.

### Spectre: grug-far

[Spectre's retrieved history ends in May 2025](https://github.com/nvim-pack/nvim-spectre/commits?per_page=1).
It also relies on Plenary. [grug-far](https://github.com/MagicDuck/grug-far.nvim) has
[October 2026 fixes](https://github.com/MagicDuck/grug-far.nvim/commits), including replacement and
line-ending handling. It is the strongest feature-plugin migration here.

Port `<leader>S` in both Normal and Visual mode, selected-text prefilling, case settings, and path
filters. Test replacements on disposable files. The existing Spectre module checks both rg and sd;
the new engine choice should determine its actual tool requirements rather than carrying those
checks over automatically. This migration alone does not make Plenary removable, because the Harpoon
group still loads it.

### Plenary and Harpoon: migrate consumers, then remove the library

[Plenary's own notice](https://github.com/nvim-lua/plenary.nvim#important-notice) explicitly ends
active maintenance and gives 2026-06-30 as the cutoff for possible critical fixes. This is stronger
evidence than a low commit count.

The spec loads it for both Harpoon and Spectre. Harpoon's locked harpoon2 revision is from
2025-10-31; the current branch tip could not be verified. A retrieved default-branch history showed
older commits and must not be mistaken for harpoon2's history.

For a replacement within the Mini ecosystem, [mini.visits](https://github.com/nvim-mini/mini.visits)
provides persistent project visits and labels, with
[October 2026 updates](https://github.com/nvim-mini/mini.visits/commits?per_page=1). It can
represent a set of favorite files, but Harpoon's ordered list and split/tab menu actions would need
deliberate adaptation. Keep Harpoon until that tradeoff is acceptable. Grapple is a plausible
functional alternative, but its retrieved history was also old; this audit does not endorse it as a
verified maintenance upgrade.

Notify's Plenary-based async API is another possible consumer. This config only calls regular
notifications, setup, and dismiss, so that optional API is not an established blocker here.

### Notifications and input: optional consolidation

[Notify's retrieved history ends in September 2025](https://github.com/rcarriga/nvim-notify/commits).
[Snacks notifier](https://github.com/folke/snacks.nvim/blob/main/docs/notifier.md) is a current
alternative; [mini.notify](https://github.com/nvim-mini/mini.notify) would fit the existing module
ecosystem. This config only customizes width, fade animation, wrapping, and dismissal, making the
migration relatively small. Check message history, wrapping, timeout, and dismiss-all behavior.

[Snacks input](https://github.com/folke/snacks.nvim/blob/main/docs/input.md) could also replace
Multinput if a shared UI package is desirable. Multinput provides a buffer that expands with its
contents; verify that interaction before switching. Its GitHub repository is explicitly a mirror of
Tangled, so GitHub activity alone cannot establish its canonical maintenance status.

Adding all of Snacks just to replace a tiny working helper is not automatically a simplification. If
chosen, enable only the modules whose behavior is wanted.

### Breadcrumbs: Dropbar is an integration choice

Navic has
[September 2026 compatibility fixes](https://github.com/SmiteshP/nvim-navic/commits?per_page=1). It
should not be labelled abandoned. Nevertheless, [Dropbar](https://github.com/Bekaboo/dropbar.nvim)
owns its breadcrumb UI and supports multiple symbol sources, so it could replace Navic, the manual
LSP attachment block, and much of the custom winbar renderer. Its
[history includes a September 2026 fix](https://github.com/Bekaboo/dropbar.nvim/commits?per_page=1).

Preserve or intentionally change the current six-level limit, clickable symbols, global-scope text,
and alignment. Oil's separate buffer-local winbar would still need attention. Retaining Navic and
simplifying its renderer is the smaller alternative.

### Keep the current Tree-sitter upstream

The current [nvim-treesitter history](https://github.com/nvim-treesitter/nvim-treesitter/commits)
contains October 2026 parser and query work. Its README documents the rewritten main branch that
this config already uses. Historic reports of archival do not describe the current status
accurately. Replacing it with a parser manager alone could also lose query and indentation behavior.

## Custom functions and integration code

| Location / behavior                                                                         | Recommendation                                                                                                             | Tradeoff or verification                                                                                                                                         |
| ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `plugins/nvim-treesitter-config.lua:79`: selection stack, start/grow/shrink callbacks       | Replace with native vim.treesitter.select or native Visual-mode an/in.                                                     | About 50 lines plus mapping callbacks can go. Native child selection is not identical to the stored ancestry stack.                                              |
| `core/autocmds.lua:4`: trim final blank lines before save                                   | Reuse installed MiniTrailspace.trim_last_lines inside the target buffer context.                                           | Retain buftype/binary guards and final-newline policy. Decide explicitly whether autosaves should also trim.                                                     |
| `lsp/nvim-navic-config.lua:15`: winbar padding and rendering                                | Simplify around Navic, or evaluate Dropbar as above.                                                                       | Exact gutter alignment and global-scope presentation remain customization.                                                                                       |
| `plugins/oil-nvim-config.lua:7`: custom cwd winbar                                          | Keep a small renderer or move directory text into Oil's title callback.                                                    | A title is not the same location as a gutter-aligned winbar. A second explorer plugin will not remove this preference.                                           |
| `core/keymaps.lua:49`: float/split/tab conversion and float movement                        | Keep for current behavior.                                                                                                 | These use direct native window APIs. Snacks win/terminal only makes sense if reusable terminal state or richer window management is wanted.                      |
| `core/keymaps.lua:193`: encoding picker; line-ending picker                                 | Keep.                                                                                                                      | Native encodings, BOM flags, and reload commands are already used. A UI plugin would style the prompt, not replace the save/discard/reopen policy.               |
| `core/keymaps.lua:297`: BTab                                                                | Replace with a small native :tab sbuffer wrapper, or use the command directly.                                             | Current tabedit reopens by filename and excludes unnamed buffers. No plugin is needed.                                                                           |
| `core/keymaps.lua:361`: manual CTags job                                                    | Keep for manual generation; simplify with vim.system if editing it later.                                                  | A tags-management plugin only pays off if automatic incremental updates and root detection are desired. LSP navigation already covers many configured languages. |
| `plugins/fzf-lua-config.lua:41`: Hipatterns picker                                          | Keep for exact matches in loaded buffers.                                                                                  | A project rg picker is smaller if disk-based TODO search is sufficient, but misses unsaved text and changes scope.                                               |
| `plugins/conform-nvim-config.lua:53`: .nvim.json reader and formatting policy               | Keep if declarative per-project policy is wanted.                                                                          | Conform already handles formatting. EditorConfig can cover basic whitespace, but not all this formatter/client-selection policy.                                 |
| `plugins/spec.lua` and `plugins/lazy.lua`: package groups and deferred setup                | Keep.                                                                                                                      | Small adaptation of vim.pack; introducing another package manager would require a separate loading/features justification.                                       |
| `lsp/lsp-base-config.lua`: executable checks, callbacks, attach behavior                    | Keep common behavior; simplify merging with native vim.lsp.config when revisiting it.                                      | Preserve server defaults, roots, capabilities, and attach callbacks. No additional LSP wrapper is needed.                                                        |
| `core/tools.lua` and `core/paths.lua`: executable resolution and overrides                  | Keep.                                                                                                                      | Small shared helper for explicitly chosen system tools. Mason would change installation ownership rather than replace just this function.                        |
| `lsp/blink-cmp-config.lua`: build fallback, omnifunc check, ghost-text state                | Keep completion preferences; move builds to install/update workflow if startup blocking is unwanted.                       | Synchronous build().pwait() can delay startup. Another completion plugin would not preserve these preferences automatically.                                     |
| `plugins/leap-config.lua`: f/t and repeat-state handling                                    | Keep while its behavior is useful; prefer a documented upstream recipe over touching internal repeat state when available. | A switch to another motion plugin changes motion/repeat semantics and needs operator-pending tests.                                                              |
| `plugins/mini-files-config.lua`: hidden/preview toggles, yank path                          | Keep.                                                                                                                      | Short callbacks around existing plugin APIs; changing explorer would replace the workflow too.                                                                   |
| `plugins/indent-blankline-nvim-config.lua`: derived rainbow colors                          | Keep if the tint is intentional.                                                                                           | Another indent plugin will not preserve the exact palette/background blending without configuration.                                                             |
| `plugins/mini-statusline-config.lua` and `mini-tabline-config.lua`: display callbacks       | Keep.                                                                                                                      | These express your chosen information and labels. A larger statusline/tabline framework offers little clear benefit.                                             |
| `plugins/auto-save-nvim-config.lua`: exclusions and Conform coordination                    | Keep.                                                                                                                      | Already delegates debounce/saving to a maintained plugin; callbacks distinguish automatic writes from manual saves.                                              |
| `dap/`: CodeLLDB adapter, launch/attach, UI listeners                                       | Keep.                                                                                                                      | Already delegates debugging and UI to plugins. Machine paths and launch choices remain project configuration.                                                    |
| Remaining autocmds: yank, resize, terminal cleanup, view/cursor restore, cwd notifications  | Keep.                                                                                                                      | Most are direct native calls. A session plugin is only justified if restoring full workspaces becomes a requirement.                                             |
| Keymap helper, diagnostic toggles, server settings, color overrides, filetype pairing rules | Keep.                                                                                                                      | These are configuration and presentation choices, not substantial missing plugin functionality.                                                                  |

### Native selection is the clearest custom-code removal

Installed Neovim 0.12.6 documents and exposes
[`vim.treesitter.select`](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/treesitter.txt),
with parent/child selection and native Visual-mode `an`/`in` mappings. Its native mappings can fall
back to LSP selection ranges when a parser is unavailable. The current custom implementation does
not provide that fallback, and `grc` currently invokes the same parent-growth function as `grn`
rather than implementing a separate scope selection.

Port the existing keys if their muscle memory matters. Validate nested nodes, multiline selections,
UTF-8 boundaries, count handling, and buffers without a parser. No extra selection plugin is needed
for these basic operations on the declared Neovim version.

### Additional observations relevant to replacement decisions

- Blink's [upstream README](https://github.com/saghen/blink.cmp) explicitly warns that v2 on main
  has breaking changes. This config intentionally uses v2 APIs and blink.lib. A stable-v1 move would
  be a configuration migration, not just a version-field change.
- The LSP attach callback stops Tree-sitter highlighting whenever semantic tokens are supported.
  This is your policy; neither a new parser manager nor a new completion plugin would change it.
  Consider whether combined semantic and syntax highlighting is desired before attributing gaps to
  plugin maintenance.
- Both Oil and MiniFiles are maintained. Keeping two explorers is reasonable if buffer-style editing
  and column browsing serve different tasks; otherwise remove whichever is not used.
- Snipe overlaps fzf.buffers, but its persistent single-key hints are a real difference. Native
  listchars likewise does not reproduce selection-only whitespace, and CodeLens does not universally
  reproduce symbol-usage's locally requested reference counts.

## Verification performed

- All 47 spec URLs exactly match all 47 lockfile URLs.
- Read all configuration Lua, including DAP, language servers, colorscheme, and C++ ftplugin.
- Inspected public upstream documentation and histories, with explicit date/source limits above.
- Confirmed installed Neovim is 0.12.6; a clean process exposes vim.treesitter.select.
- Reproduced the missing MiniPick backend using only Actions Preview on a clean runtime path.
- Inspected the existing native retab, buffer-split, selection, and view APIs in installed help.
- Checked that the report covers each of the 47 plugins exactly once with its configured upstream
  URL.
- The repository's dprint check could not run: fetching the pinned formatter plugins from
  registry.npmjs.org was blocked, including after an escalated retry. Formatting is not certified.
- No interactive migration or end-to-end debugger/server session was tested. Recommendations still
  require the feature-specific acceptance checks described above when implemented.
