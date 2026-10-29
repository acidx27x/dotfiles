# Neovim stability review (2026-10-29)

## Verdict and scope

**Usable on this Linux installation, with a qualified stability verdict.** Neovim 0.12.6 starts,
the 47 configured packages load, and the tested file, picker, formatter, LSP, terminal, and debugger
setup paths work. This is a **local-installation** result: 27 installed repositories differ from the
committed lockfile. A **committed-lockfile runtime** result could not be produced because these Git
checkouts are partial clones and the missing blobs require GitHub access that this workspace blocks.
The committed specification and lockfile agree on all 47 names and sources. This follow-up removes
Lspkind and rainbowline, adds first-use external tool checks, and leaves other revisions unchanged.

The largest risks are version drift, [experimental `vim.pack`](https://neovim.io/doc/user/pack/),
and [Blink v2's breaking-change warning](https://github.com/Saghen/blink.cmp). Keep the lockfile
and installed checkouts synchronized before interpreting a runtime result as a release check.

## Findings

| Severity | Finding and evidence | Action |
| --- | --- | --- |
| High | **27/47 installed revisions differ from the committed lockfile** (table below). `vim.pack.add()` does not synchronize an existing checkout's revision; [upstream documents an explicit update step](https://neovim.io/doc/user/pack/). | Use `:packupdate ++lockfile` or the documented `vim.pack.update(..., {target="lockfile"})`, review the change, restart, then retest. Do not treat the local tests below as pinned tests. |
| Resolved | Four obsolete installed directories (`neo-tree.nvim`, `nui.nvim`, `nvim-web-devicons`, `vague.nvim`) previously caused `vim.pack` to repair a disposable copy's lockfile from 49 to 53 entries at startup. | Removed these and the two dropped plugin checkouts with `vim.pack.del`; startup now retains 47 entries. |
| Medium | `vim.pack` is explicitly experimental, though upstream calls it stable enough for daily use. Native package install/update hooks and lock reconciliation remain a maintenance surface. | Keep the lockfile under version control and review package updates before accepting them. |
| Medium | Blink follows `main` (v2), which upstream says is subject to breaking changes. The config uses `blink.lib`, and falls back from Rust matching to Lua if no library is available. Cargo is absent here. | Keep the committed revision fixed for routine work; test completion, snippets, command line, and terminal modes after any Blink update. A stable v1 migration would require configuration changes, so this audit makes no swap. |
| Medium | Tree-sitter `main` is an incompatible rewrite, requires Neovim 0.12+ and `tree-sitter-cli` 0.26.1+, and [ties parsers to plugin queries](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md). The config correctly loads it eagerly and runs `:TSUpdate` on plugin updates. | Update parsers with the plugin; verify selection and highlighting after updates. The configured CMake parser is included. |
| Medium | `FloatermClose` directly edits `floaterm.state`, calls `volt.utils.close()`, and deletes `FloatermAu`. Those internals can change independently of the documented toggle API. | Retest the close command after Floaterm/Volt updates; consider built-in terminal windows if the floating sidebar is unused. |
| Medium | `actions-preview` uses `diff-so-fancy`, which is absent on this machine. The action mapping now warns once and its plain-diff preview remains available. | Verify an interactive code-action preview when a suitable server offers one. |
| Low | Snipe duplicates MiniPick buffer selection; Smartcolumn overlaps the fixed color column. | See [workflow comparisons](plugins.md#workflow-comparisons-and-decisions). |
| Low | LSP `on_attach` stops Tree-sitter when semantic tokens are offered. `grc` and `grn` both grow to the same parent; the [keymap reference](keymaps.md) already states this. | Retain current behavior in this audit; decide separately whether semantic highlighting or distinct scope growth is wanted. |

## Installed revisions versus committed lockfile

All 47 spec names and GitHub source URLs match lockfile entries. The version constraints are `main`
for Blink and Tree-sitter and `harpoon2` for Harpoon; the remaining specs use repository defaults.
The following are the **27 local-installation differences**, from `git rev-parse HEAD` versus the
committed `nvim-pack-lock.json` on 2026-10-29. The other 20 revisions match. Hashes are abbreviated.

| Plugin | Committed | Installed | Plugin | Committed | Installed |
| --- | --- | --- | --- | --- | --- |
| auto-save.nvim | `9aabcb8396` | `141e5b4cb5` | blink.cmp | `1e4cb39b92` | `74ebcf9a2d` |
| floaterm | `fc2efaf25e` | `4f24e90f12` | friendly-snippets | `b4d01b0fdf` | `b2ea5c41a1` |
| gitsigns.nvim | `5be654f223` | `d4854fa9a9` | indent-blankline.nvim | `d28a3f7072` | `f1e186e44d` |
| matchparen.nvim | `75398158ea` | `87df7d1459` | mini.bufremove | `281bb1a2c6` | `6e9c563cb7` |
| mini.comment | `27a29d6b94` | `3aa39b795c` | mini.extra | `9c6affac2b` | `6cbc59d875` |
| mini.hipatterns | `7c840c71d6` | `247c017357` | mini.icons | `98faae31e9` | `eab3e692d7` |
| mini.move | `48fcaac289` | `5207c4de3d` | mini.pairs | `b1c5a72692` | `03eb1f0062` |
| mini.splitjoin | `9301717c76` | `de43d1ace7` | mini.statusline | `127997ebef` | `d7133a9a24` |
| mini.surround | `8d5d0c5aa9` | `5357f00aca` | mini.tabline | `525b27e98d` | `3dd8686c15` |
| mini.trailspace | `82c4fb7d43` | `8bcd13b6d5` | no-neck-pain.nvim | `0df6659e25` | `ed63925a06` |
| nvim-dap | `9e848e09a6` | `cfa2d58f45` | nvim-lspconfig | `af9adce488` | `4feaba4d39` |
| nvim-navic | `f5eba192f3` | `455808fd0f` | oil.nvim | `b73018b75a` | `d3733d9338` |
| smartcolumn.nvim | `5351ae24e9` | `3a760dc239` | visimatch.nvim | `4334be61a9` | `c4bbb79612` |
| volt | `620de1321f` | `4351c5cd79` | | | |

The prior review's upstream-head comparison was a historical freshness snapshot, not a compatibility
check. This review replaces it with the current committed-versus-installed comparison.

## Verification and limits

- **Local-installation / isolated startup:** the earlier audit copied config and installed packages
  into temporary XDG directories. After cleanup, a disposable config with the live package data
  loaded 47 packages and a representative lazy group without setup errors. The tracked lockfile
  remained stable after `vim.pack.del` removed the six unused checkouts.
- **Local-installation / lazy groups:** loaded `buffer_ui`, Conform, Harpoon, Spectre, DAP,
  Floaterm, Snipe, LSP preview/actions, symbol usage, and No-Neck-Pain without setup errors.
  Opening a Lua file triggered the buffer group; a buffer-local `gd` mapping appeared after the LSP
  keymap setup. This checks registration, not every interactive UI action.
- **Local-installation / representative paths:** a C++ fixture attached `clangd`; Conform used
  `clang-format` to change `int main(){return 0;}` to `int main() { return 0; }`; Oil opened an
  `oil` buffer; a MiniPick file picker opened and closed; `dap.toggle_breakpoint()` did not error;
  and an exiting built-in terminal buffer was removed by `TermClose`.
- **Committed-lockfile runtime:** unavailable. The local Git repositories are blobless partial
  clones. Checking out the pinned Blink revision in a temporary copy attempted to fetch missing
  blobs from GitHub, and the sandbox blocked that domain, including an escalated retry. No pinned
  plugin code was run. This limits compatibility claims for all 27 differing revisions.
- **External tools:** present: Git, `rg`, `sd`, `tree-sitter` 0.27.1, `tar`, `curl`, a C compiler,
  `clangd`, `clang-format`, `gersemi`, and `delta`. Absent from `PATH`: Cargo, `stylua`, `ruff`,
  `ty`, `neocmakelsp`, `basedpyright-langserver`, `codelldb`, `ctags-universal`, and
  `diff-so-fancy`. Python/CMake formatters other than clang-format, real code-action previews,
  CMake/Python LSP attachment, and a CodeLLDB session were not verified.
- **Follow-up checks:** rainbowline's four highlight values matched IBL's new hook before and after
  a Kanagawa reload. Both configurations use the same whitespace cycle, scope settings, and platform
  glyphs; headless Neovim did not expose drawing marks for a visual comparison. MiniIcons returned
  LSP-kind and file icons. Temporary missing paths produced one notification per tool for LSP,
  CodeLLDB, parser commands, Spectre, MiniPick live grep, and CTags. A missing clang-format warned
  once while `<Space>cf` formatted through clangd; Actions Preview warned once and exposed its
  plain-diff fallback. A configured `local_paths` override was honored. Clangd attached to C++.
- **Executable resolution:** `core.tools.ensure_executable` checks `_G.Paths` first, then ordered
  command candidates, and reports a missing tool once at the feature's error or fallback warning
  level. LSP, Conform, CodeLLDB, CTags, Spectre, and Actions Preview pass its selected command to
  their runner. Blink, MiniPick, and Tree-sitter check the literal names their plugins invoke;
  Tree-sitter's installer uses `curl` and has no `wget` fallback. Headless checks covered override
  priority, ordered fallback, both notification levels, runner arguments, missing-tool stops, the
  Conform fallback, isolated startup, and `clangd` attachment to C++.
- **Repository checks:** spec URLs match all 47 lockfile URLs; all 47 inventory rows have a
  recommendation; `git diff --check -- nvim` passed. Scoped
  `dprint check` could not run because its pinned Markdown plugin fetch from `registry.npmjs.org`
  was blocked by this sandbox, including an escalated retry.

## Core, LSP, and keymap assessment

Core options enable persistent undo, backups, swap files, and saved views under the XDG cache.
`BufWritePre` removes final blank lines and ensures a final newline; saving a buffer can therefore
change its content even when Conform's format-on-save remains disabled. `TermClose` deletes a
successful terminal buffer, as exercised above. The global `colorcolumn=120` overlaps
Smartcolumn's contextual marker. Search centering, split/float/tab operations, and Alt/Meta
window maps are documented in [keymaps.md](keymaps.md); no documentation mismatch requiring a
keymap edit was found.

LSP uses Neovim 0.12's `vim.lsp.config`/`enable` API with `clangd`, `neocmake`, `ruff`, and `ty`
enabled; `basedpyright` is configured but disabled. Blink tries LSP completion, then a valid
buffer-local omnifunc, then buffer words. Path and snippet sources run independently.
On attach the config installs buffer-local LSP maps, sets folding when offered, suppresses
Tree-sitter for semantic-token servers, retains Neovim's LSP omnifunc for manual completion, and
attaches Navic for document symbols. Clangd attachment and buffer-local `gd` registration were
observed; the other servers were unavailable. Conform's CMake/Python client filters are supported
filetype options, but those fallback combinations could not be exercised here.

The README's setup and package commands, the workflow guide, and the keymap reference agree with
the audited code for the paths checked. Interactive modifier delivery and all plugin UI mappings
still require terminal-level checks; a clean headless startup alone does not establish them.

## Platform review

Linux was exercised in this workspace. The code selects `<A-...>` window mappings and the `⎜`
indent glyph on Linux; those mappings still depend on the terminal sending the expected keycodes.
On macOS it selects `<M-...>` and `⎸`; clipboard, terminal modifiers, parser compiler, trash,
and external binary paths require a macOS runtime check. On Windows it selects `<A-...>` and `|`,
sets CodeLLDB's `detached=false`, and relies on the same external executables and clipboard/trash
integration. [MiniIcons notes a possible Windows path-length issue](https://github.com/nvim-mini/mini.icons).
Windows runtime was not tested and is lower priority. No platform behavior is certified from source
inspection alone.
