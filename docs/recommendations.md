# Neovim recommendations and migration plan

Status: **recommendations only**. The audit changed documentation, not Neovim behavior. Each item
below names the configuration files that would change in a later implementation phase.

Priorities:

- **P0**: compatibility or confirmed broken behavior.
- **P1**: high-value correctness or maintainability work.
- **P2**: useful cleanup or measured optimization.
- **P3**: optional preference.

## 1. Necessary fixes

### N1. Migrate nvim-treesitter to the Neovim 0.12 branch

- **Priority:** P0.
- **Problem:** The config runs Neovim 0.12.5 but pins the frozen `nvim-treesitter` `master` branch,
  whose own documentation excludes Neovim 0.12. The current `main` branch is a full incompatible
  rewrite for 0.12.
- **Solution:** Change the pack spec to `main` (or stop pinning after confirming the default),
  replace `require("nvim-treesitter.configs").setup()` with the new setup/install API, enable
  highlighting/folds/indent through Neovim/ftplugin APIs, and redesign or remove old incremental
  selection mappings. Update every configured parser in the same controlled change.
- **Expected benefit:** Supported Tree-sitter behavior on the installed editor and a maintained
  update path.
- **Risks:** Parser installation and configuration APIs changed; indentation and incremental
  selection behavior can differ. The new branch also says it does not support lazy loading.
- **Files:** `lua/plugins/nvim-treesitter-config.lua`, `nvim-pack-lock.json`, possibly
  `after/ftplugin/*` or new ftplugin files, plus this documentation.
- **Verify:** Start cleanly; run `:checkhealth nvim-treesitter`; update/install the eight configured
  parsers; open Bash, Fish, C, C++, Python, Lua, JavaScript, and diff buffers; check highlight,
  folds, indentation, injections, and the final selection mappings.

### N2. Remove broken LSP and diagnostic self mappings

- **Priority:** P0.
- **Problem:** Buffer-local nonrecursive mappings from `K`, the native `gr...` family, `gO`, `gra`,
  and insert `<C-s>` to themselves shadow Neovim's global LSP callbacks. The same pattern shadows
  native `<C-w>d` diagnostics.
- **Solution:** Remove the self mappings. Prefer Neovim 0.12 defaults. If custom buffer mappings are
  required, map directly to `vim.lsp.buf.*` functions. Remove exact `gr` and move declaration away
  from `gc` so the native `gr...` and comment families remain usable.
- **Expected benefit:** Restores built-in hover, rename, references, implementation, code actions,
  document symbols, signature help, diagnostic float, and comments.
- **Risks:** Existing muscle memory for `gc` declaration and `gr` references changes. Goto Preview
  and `<C-s>` mappings can remain as secondary paths.
- **Files:** `lua/lsp/lsp-base-config.lua`, `lua/lsp/diagnostic-default-config.lua`,
  `docs/keymaps.md`, README essentials.
- **Verify:** Attach clangd to a small C/C++ project and inspect `:verbose nmap K`, `gra`, `grr`,
  `grn`, `gri`, `gO`, `gc`, `gcc`, and `<C-w>d`; exercise each action. Check Insert `<C-s>` and
  Visual `gra` as well.

### N3. Make configured external tools available or disable their features

- **Priority:** P0 for tools that are expected to work; P1 for unused languages.
- **Problem:** This machine lacks `ty`, `ruff`, `neocmakelsp`, `basedpyright-langserver`,
  `codelldb`, `gersemi`, `stylua`, `ctags-universal`, and `diff-so-fancy`. Mappings remain visible
  even when their tools cannot run.
- **Solution:** Add required tools to platform bootstrap scripts, correct command names where the
  installed executable differs, or conditionally enable servers/formatters/actions with
  `vim.fn.executable()`. Use available Delta for action previews or fall back to built-in diff.
- **Expected benefit:** Documented features either work or clearly report that they are unavailable.
- **Risks:** Installation differs across Linux, macOS, and Windows; conditional enablement can hide
  a missing dependency unless it emits one concise notification/health item.
- **Files:** `core/paths.lua`, relevant LSP files, `conform-nvim-config.lua`,
  `actions-preview-nvim-config.lua`, core `CTags` command, and platform scripts under `setup/` if
  installation is authorized later.
- **Verify:** `:checkhealth conform`, `:checkhealth vim.lsp`, `:checkhealth dap`; `:ConformInfo`;
  `vim.fn.executable()` for each selected tool; format one file per language; attach each enabled
  server; run `:CTags` in a disposable project.

### N4. Choose or merge the C/C++ debug adapters

- **Priority:** P1.
- **Problem:** CodeLLDB and `lldb-dap` both replace `dap.configurations.c/cpp`; the later file wins.
  CodeLLDB remains registered and fails health checks because its executable is absent.
- **Solution:** Prefer the available `lldb-dap` and stop loading CodeLLDB, or install CodeLLDB and
  concatenate both adapters' launch/attach configurations with distinct names.
- **Expected benefit:** Predictable adapter selection and a clean DAP health report.
- **Risks:** `lldb-dap` and CodeLLDB differ in terminal, console, and attach behavior across
  platforms.
- **Files:** `lua/dap/config.lua`, `nvim-dap-codelldb-config.lua`, `nvim-dap-lldb-config.lua`,
  `core/paths.lua`.
- **Verify:** Inspect `require("dap").configurations.c`, launch and attach a small C and C++
  program, exercise breakpoints/REPL/UI, and run `:checkhealth dap`.

### N5. Correct confirmed mapping metadata and the cwd error path

- **Priority:** P1.
- **Problem:** Harpoon next/previous actions and descriptions are reversed; Oil's local-cwd and
  preview scroll descriptions are wrong; Conform's mapping description is nil; the invalid cwd
  warning tries to call a string.
- **Solution:** Align Harpoon `prev/next` with `hp/hn` names, fix Oil descriptions, define Conform's
  description literal, and replace `path("'")` with string concatenation.
- **Expected benefit:** Picker/keymap help becomes trustworthy and a latent runtime error is
  removed.
- **Risks:** Swapping Harpoon actions changes behavior for anyone who learned the current accidental
  layout. Decide whether the keys or descriptions are authoritative before editing.
- **Files:** `plugins/harpoon-config.lua`, `plugins/oil-nvim-config.lua`,
  `plugins/conform-nvim-config.lua`, `core/keymaps.lua`.
- **Verify:** Use `<leader>pk`; open Harpoon and Oil; invoke both directions/scroll actions; inspect
  `:verbose map <leader>cf`; exercise `<leader>cd` in a non-file buffer with an invalid path.

### N6. Replace deprecated local Neovim API usage

- **Priority:** P1.
- **Problem:** Local config uses `vim.loop` and the renamed keymap `buffer` option. Visimatch uses a
  deprecated API upstream.
- **Solution:** Use `vim.uv`, replace `buffer = bufnr` with `buf = bufnr`, and update or patch
  Visimatch when an upstream compatible revision exists.
- **Expected benefit:** Clean Neovim 0.12 API usage and a smaller Neovim 1.0 migration surface.
- **Risks:** Very low for local renames. An upstream Visimatch change requires normal behavior
  testing.
- **Files:** `plugins/indent-blankline-nvim-config.lua`, `plugins/gitsigns-nvim-config.lua`,
  `plugins/floaterm-config.lua`, `plugins/harpoon-config.lua`, `lsp/lsp-base-config.lua`, lockfile
  if Visimatch is updated.
- **Verify:** `:checkhealth vim.deprecated`, full headless startup, and buffer-local map dumps for
  Gitsigns, Floaterm, Harpoon, and LSP.

## 2. Maintainability improvements

### M1. Centralize native pack specifications

- **Priority:** P1.
- **Problem:** 39 `vim.pack.add()` call sites repeat dependencies and make the installed inventory
  depend on setup order.
- **Solution:** Create one `lua/plugins/specs.lua` containing source, version, and optional metadata
  for all repositories. Add eager groups once during startup. Setup files should only configure
  plugins. Keep the native lockfile as the exact revision source of truth.
- **Expected benefit:** One reviewable inventory, no duplicate specs, clearer dependencies, simpler
  update/removal work.
- **Risks:** `vim.pack` reconciles the entire lockfile on its first call; preserve that behavior and
  dependency order while moving specs. Centralizing specs alone does not add lazy loading.
- **Files:** New `lua/plugins/specs.lua`; all plugin, LSP, DAP, and theme config modules;
  `plugins/config.lua`.
- **Verify:** Compare `vim.pack.get()` names/active flags and lockfile before/after; headless
  startup; `:checkhealth vim.pack`; confirm no repository is added from two places.

### M2. Use namespaced Lua modules and explicit group entry points

- **Priority:** P1.
- **Problem:** `init.lua` mutates `package.path` four times to load flat names such as `config`,
  `paths`, and `filetypes`. Ownership is unclear and names can collide.
- **Solution:** Require `core.config`, `plugins.config`, `lsp.config`, `dap.config`, and
  `colorscheme.config` through the standard config Lua path; update internal requires to namespaced
  paths such as `core.paths` and `lsp.base`.
- **Expected benefit:** Clear stack traces, normal Lua module resolution, easier editor navigation,
  and fewer hidden globals.
- **Risks:** Mechanical but broad; one missed require prevents startup. Do it separately from
  behavior changes.
- **Files:** `init.lua` and every local `require()` referring to a flat module.
- **Verify:** Compile all Lua files, run headless startup, inspect `package.path`, and search for
  old flat require names.

### M3. Separate active, optional, and dormant modules

- **Priority:** P2.
- **Problem:** Hardtime, a local trailing-whitespace implementation, and cppdbg look active by file
  name but are not initialized. Vague and mini.bufremove are active without current use.
- **Solution:** Add a clear `disabled/` or `optional/` convention, or delete modules after a review.
  Remove Vague and mini.bufremove if a short interactive trial confirms they are unused. Keep
  reasons in documentation instead of commented require lines.
- **Expected benefit:** The tree reflects actual behavior and future audits do not confuse dead code
  with active functionality.
- **Risks:** Deletion loses convenient experiments; preserve history in Git and avoid removing a
  plugin used manually through commands.
- **Files:** `plugins/config.lua`, dormant module files, colorscheme config, lockfile, plugin docs.
- **Verify:** Search all requires/commands/mappings; compare `vim.pack.get()`; exercise normal
  editing for a week before final removal.

### M4. Replace repeated option defaults with intentional policy

- **Priority:** P2.
- **Problem:** Many assignments repeat Neovim defaults, while `colorcolumn=120` is immediately
  managed by Smartcolumn and `vim.loader.enable()` is already enabled in the tested 0.12 build.
- **Solution:** Keep settings that express a deliberate policy; remove defaults that add no
  explanation or behavior. Add short comments only where the explicit default is meaningful for
  portability.
- **Expected benefit:** Smaller option surface and easier upgrades.
- **Risks:** Defaults can change between Neovim versions. The config already targets 0.12 because of
  `vim.pack`, `winborder`, and current LSP APIs, so that portability benefit is limited.
- **Files:** `init.lua`, `core/options.lua`, `plugins/smartcolumn-nvim-config.lua`.
- **Verify:** Dump selected option values before/after under Neovim 0.12.5 and compare interactive
  behavior.

### M5. Restrict view persistence to real file buffers

- **Priority:** P2.
- **Problem:** `mkview`/`loadview` runs for every buffer/window with errors hidden.
- **Solution:** In callbacks, require an empty `buftype`, a real file name, and a readable/writable
  view location. Keep the current `viewoptions=folds,cursor` policy.
- **Expected benefit:** Less hidden work and fewer surprising interactions with plugin buffers.
- **Risks:** Some unusual file-backed buffers may stop restoring views.
- **Files:** `core/autocmds.lua`, possibly `core/options.lua`.
- **Verify:** Restore cursor/folds in normal files; open terminals, Oil, Neo-tree, help, quickfix,
  DAP UI, and picker buffers; check `:messages` for errors.

### M6. Document and maintain the mini.pick fork delta

- **Priority:** P1.
- **Problem:** The config uses `acidx27x/mini.pick`, whose lock revision is older than current
  upstream mini modules. The only source comment says it changes glob patterns.
- **Solution:** Record the exact patch/commits against `nvim-mini/mini.pick`, add an upstream remote
  maintenance procedure, and periodically rebase or upstream the behavior.
- **Expected benefit:** Updates become deliberate rather than silently freezing a core picker.
- **Risks:** Rebases can change picker semantics and conflict with registry wrappers.
- **Files:** `plugins/mini-pick-config.lua`, contributor documentation, lockfile when rebased.
- **Verify:** File, grep, live grep with glob patterns and custom cwd; all extra and LSP pickers;
  `vim.ui.select` consumers.

## 3. Optional ergonomic improvements

### E1. Reduce mapping timeout and simplify prefix families

- **Priority:** P2.
- **Problem:** `timeoutlen=5000` makes incomplete leader, `s`, `gr`, `<C-w>d`, and `<C-s>` sequences
  feel stalled. Several groups use native command prefixes.
- **Solution:** After removing exact `gr` and deciding on surround keys, try 500-1000 ms. Keep
  terminal `ttimeoutlen` separate and test Alt/arrow transport.
- **Expected benefit:** Faster feedback and fewer apparent freezes.
- **Risks:** Slow deliberate key sequences may time out, especially over remote sessions.
- **Files:** `core/options.lua`, surround and LSP mapping files if prefixes change.
- **Verify:** Use every multi-key group locally and over SSH/tmux; test Escape, arrows, function
  keys, Alt navigation, and plugin menus.

### E2. Make buffer deletion use mini.bufremove or remove the plugin

- **Priority:** P2.
- **Problem:** mini.bufremove is installed but `<leader>bd` uses `:bdelete`.
- **Solution:** Map `<leader>bd` to `MiniBufremove.delete()` if preserving the window layout is
  desired, or remove the plugin.
- **Expected benefit:** Either useful behavior or one less plugin.
- **Risks:** Force/modified-buffer behavior differs from `:bdelete`.
- **Files:** `core/keymaps.lua`, `plugins/mini-bufremove-config.lua`, lockfile if removed.
- **Verify:** Delete modified/unmodified buffers in single and split windows; check alternate buffer
  and tabline state.

### E3. Reconsider plugins now covered by Neovim

- **Priority:** P3.
- **Problem:** mini.comment and matchparen overlap built-in Neovim behavior; nvim-notify replaces a
  usable built-in notification path.
- **Solution:** Compare behavior one plugin at a time. Prefer built-ins only where the user-visible
  result and needed configuration remain acceptable.
- **Expected benefit:** Fewer dependencies and mappings.
- **Risks:** Built-ins can lack preferred padding, motions, animation, history, or highlight logic.
- **Files:** Corresponding plugin configs, core mappings/highlights, lockfile.
- **Verify:** Comment motions/text objects, nested pair matching on large files, notification
  levels, dismissal, and plugin-originated notifications.

### E4. Keep both file explorers only if their roles remain distinct

- **Priority:** P3.
- **Problem:** Oil and Neo-tree overlap, though the current takeover settings do not conflict.
- **Solution:** Use Oil for directory editing and Neo-tree for project overview, and say so in the
  README. If one workflow goes unused, remove it after a trial.
- **Expected benefit:** Clear mental model or a smaller plugin set.
- **Risks:** Removing either loses a genuinely different workflow.
- **Files:** Explorer configs, mappings, plugin specs/lockfile, README.
- **Verify:** Directory startup, file create/rename/delete/trash, reveal-current-file, cwd behavior,
  split/tab opens, and external open.

### E5. Use one spelling for Alt/Meta mappings

- **Priority:** P3.
- **Problem:** Every `<A-...>` mapping is immediately replaced by the identical `<M-...>` alias.
- **Solution:** Keep `<M-...>` or `<A-...>` consistently and document terminal support.
- **Expected benefit:** Half as many definitions with the same effective behavior.
- **Risks:** None inside Neovim; terminal emulators still determine whether the key arrives.
- **Files:** `core/keymaps.lua`.
- **Verify:** `:verbose nmap` for all navigation, resize, and floating-window keys in each supported
  terminal.

## 4. Plugin-loading and performance optimizations

### P1. Preserve the measured baseline while fixing correctness

- **Priority:** P1.
- **Problem:** Performance work without a stable comparison can trade predictable behavior for
  unmeasured complexity.
- **Solution:** Re-run the five-run startup harness after necessary fixes before introducing lazy
  loading. Save representative interactive `--startuptime` results with a real file as well.
- **Expected benefit:** Optimizations have measurable targets and regressions are visible.
- **Risks:** Headless warm-cache timing is noisy and does not predict all interactive latency.
- **Files:** Documentation or an optional audit script; no runtime config required.
- **Verify:** Same Neovim binary, plugin revisions, environment, run count, and cache conditions.

### P2. Lazy-load the complete DAP group

- **Priority:** P1.
- **Problem:** DAP costs about 7.5 ms in the representative startup and is unnecessary in sessions
  without debugging.
- **Solution:** Register lightweight DAP key stubs. On first invocation, add/load nvim-dap,
  nvim-nio, virtual text, and DAP UI; configure the selected adapter; replace or directly execute
  the requested action. Keep the group atomic.
- **Expected benefit:** Largest low-risk startup saving for an occasional feature.
- **Risks:** First debug action becomes slower; recursive stubs and dependency order must be handled
  carefully; missing packages should be installed during normal bootstrap rather than surprising the
  user at first breakpoint.
- **Files:** `dap/config.lua`, all DAP modules, centralized specs/loader, keymap documentation.
- **Verify:** Cold and warm first invocation for every DAP mapping, adapter launch/attach, UI
  lifecycle, virtual text, REPL, restart, and startup comparison.

### P3. Lazy-load command-driven feature groups

- **Priority:** P2.
- **Problem:** Harpoon, Spectre, Floaterm, Neo-tree, Snipe, No Neck Pain, and manual-only Conform do
  setup work in every session.
- **Solution:** Add one small loader helper around native `vim.pack.add()` and setup modules. Use
  key or command stubs for each feature. Treat dependencies as part of the feature group. Preserve
  Oil's eager directory handling unless directory startup is separately solved.
- **Expected benefit:** Removes several milliseconds while keeping native package management.
- **Risks:** Native `vim.pack` does not supply declarative triggers, dependency resolution, or stub
  cleanup. Too many one-off loaders become a homemade plugin manager.
- **Files:** New loader module, affected plugin configs/specs, keymaps.
- **Verify:** Start without touching each feature and inspect loaded Lua modules/runtime paths; then
  invoke every entry key/command twice, including first invocation with missing optional tools.

### P4. Delay optional LSP UI features

- **Priority:** P2.
- **Problem:** Goto Preview, Actions Preview, and Symbol Usage are configured before any LSP
  attaches; Symbol Usage is then disabled.
- **Solution:** Configure them on the first LSP attach that needs them or in direct mapping
  callbacks. Keep core LSP configs and completion registration early enough for the first file.
- **Expected benefit:** Smaller general startup and no work for non-code sessions.
- **Risks:** Multiple clients can trigger setup more than once; attach callbacks need an idempotent
  guard; mappings must behave clearly if no server supports the action.
- **Files:** `lsp/config.lua`, the three add-on configs, `lsp-base-config.lua`, loader/spec module.
- **Verify:** First and second LSP attachments, multiple clients in one buffer, all preview/action/
  usage mappings, detach/reattach, and startup comparison.

### P5. Keep always-on editing/UI plugins eager

- **Priority:** P1 policy decision.
- **Problem:** “Lazy-load everything” can miss the first buffer/event and creates visible first-use
  latency for fundamental editing behavior.
- **Solution:** Keep the selected theme, Tree-sitter, desired `vim.ui`/`vim.notify` overrides,
  statusline/tabline, pairs, comment, move, surround, split/join, and other expected always-on
  behavior eager. Reconsider each only with a concrete measurement.
- **Expected benefit:** Predictable first-buffer behavior and simpler configuration.
- **Risks:** These plugins continue to account for part of the roughly 82 ms config overhead.
- **Files:** Central specs and loading policy documentation.
- **Verify:** Open a file directly on the command line and immediately use every editing primitive;
  compare startup and first-action latency.

### P6. Keep `vim.pack`; do not migrate solely for lazy-loading syntax

- **Priority:** P1 recommendation.
- **Problem:** A third-party manager would offer declarative triggers but creates a large migration
  and another abstraction. The current manager already provides locking and reproducible installs.
- **Solution:** Retain `vim.pack`, centralize specs, and implement only a few high-value lazy
  groups. Revisit a manager migration only if custom trigger code becomes substantial or
  requirements grow.
- **Expected benefit:** Incremental change, preserved lockfile/update workflow, and less churn.
- **Risks:** Native `vim.pack` is still marked experimental and lacks dependency/trigger metadata.
- **Files:** No immediate behavior change; future specs/loader modules.
- **Verify:** `:packupdate`, initial bootstrap on a clean data directory, offline lockfile restore,
  removal workflow, and `:checkhealth vim.pack`.

## Suggested implementation order

1. Create a small branch or commit boundary for documentation (this audit).
2. Fix LSP/diagnostic mappings and mapping metadata; validate with a real clangd project.
3. Resolve missing tools and the DAP adapter choice.
4. Migrate nvim-treesitter and parsers as its own change.
5. Replace deprecated APIs.
6. Centralize plugin specs without changing loading behavior.
7. Namespace local modules as a mechanical follow-up.
8. Re-measure startup.
9. Lazy-load DAP first, then only the command-driven groups whose measured savings justify the
   loader code.
10. Remove confirmed-unused plugins and dormant modules one at a time.

Each step should leave Neovim starting cleanly, preserve a reviewable diff, and update
[plugins.md](plugins.md), [keymaps.md](keymaps.md), and the README whenever behavior changes.
