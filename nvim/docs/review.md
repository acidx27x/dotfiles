# Neovim review (2026-10-28)

The configuration starts on Neovim 0.12.6 with its committed `vim.pack` lockfile. The refactor's
central package list and explicit optional groups are coherent. The first file opened in a session
now loads the buffer UI group whether it already exists (`BufReadPre`) or is new (`BufNewFile`).
Feature files with global mappings register those keys at startup and run plugin setup on first use.
Other buffer UI modules load on the first file event; Gitsigns creates its buffer mappings on
attach.

The new core mappings are listed in [keymaps.md](keymaps.md). `<Space>st` moves a split to a tab and
opens a float's buffer in a tab while closing that float. `<Space>sf` turns a split into a float or
docks a float as a right split. Neovim cannot turn the tab's last normal window into a float, so in
that case the mapping opens a float for the same buffer and keeps the base window. The existing
`<Space>sh` and `<Space>sv` mappings split the current split further.

## Locked plugin revisions

Before the Blink migration, I compared each of the 47 lockfile revisions with its upstream Git
branch head. This historical snapshot checks revision freshness, not compatibility or release
quality. Blink followed `v1` and Harpoon followed `harpoon2`; the others followed their repository
default branch. Twenty-six heads differed from that lockfile:

| Plugin                | Locked       | Upstream head |
| --------------------- | ------------ | ------------- |
| auto-save.nvim        | `9aabcb8396` | `5961d5e041`  |
| blink.cmp (`v1`)      | `78336bc89e` | `5d77bcf210`  |
| floaterm              | `fc2efaf25e` | `4f24e90f12`  |
| gitsigns.nvim         | `5be654f223` | `d4854fa9a9`  |
| indent-blankline.nvim | `d28a3f7072` | `f1e186e44d`  |
| matchparen.nvim       | `75398158ea` | `87df7d1459`  |
| mini.bufremove        | `281bb1a2c6` | `6e9c563cb7`  |
| mini.comment          | `27a29d6b94` | `7b6e37ad79`  |
| mini.extra            | `9c6affac2b` | `6cbc59d875`  |
| mini.hipatterns       | `7c840c71d6` | `247c017357`  |
| mini.icons            | `98faae31e9` | `eab3e692d7`  |
| mini.move             | `48fcaac289` | `57435a0f66`  |
| mini.pairs            | `b1c5a72692` | `03eb1f0062`  |
| mini.splitjoin        | `9301717c76` | `be4536a1b8`  |
| mini.statusline       | `127997ebef` | `d7133a9a24`  |
| mini.surround         | `8d5d0c5aa9` | `59ce0acf79`  |
| mini.tabline          | `525b27e98d` | `3dd8686c15`  |
| mini.trailspace       | `82c4fb7d43` | `8bcd13b6d5`  |
| no-neck-pain.nvim     | `0df6659e25` | `ed63925a06`  |
| nvim-dap              | `9e848e09a6` | `cfa2d58f45`  |
| nvim-lspconfig        | `af9adce488` | `77b7432d47`  |
| nvim-navic            | `f5eba192f3` | `455808fd0f`  |
| oil.nvim              | `b73018b75a` | `d3733d9338`  |
| smartcolumn.nvim      | `5351ae24e9` | `3a760dc239`  |
| visimatch.nvim        | `4334be61a9` | `c4bbb79612`  |
| volt                  | `620de1321f` | `4351c5cd79`  |

The other 21 matched their tracked heads: actions-preview.nvim, conform.nvim, goto-preview, harpoon,
indent-rainbowline.nvim, kanagawa.nvim, logger.nvim, lspkind.nvim, mini.clue, mini.pick,
multinput.nvim, nvim-dap-ui, nvim-dap-virtual-text, nvim-nio, nvim-notify, nvim-spectre,
nvim-treesitter, plenary.nvim, snipe.nvim, symbol-usage.nvim, and visual-whitespace.nvim.

Use `:lua vim.pack.update()` to review other plugin updates and accept them in Neovim, then restart
before checking plugin behavior.
[Neovim's vim.pack documentation](https://neovim.io/doc/user/pack.html) describes this workflow. The
migration updated Blink and added blink.lib and friendly-snippets to the lockfile.

## Design and migration notes

- `blink.cmp` now tracks `main` (v2) and loads `blink.lib` first. The config uses the native matcher
  when available, builds it when Cargo is installed, and falls back to Lua otherwise.
  `friendly-snippets` supplies ready-made snippets for the built-in snippet source. The private
  signature-trigger override was removed; manual signature help remains on `<C-s>`. See the
  [v2 migration guide](https://github.com/saghen/blink.cmp/blob/main/UPGRADE.md). Existing Neovim
  installations retain their old Blink checkout until they run
  `:lua vim.pack.update({"blink.cmp"}, {target="lockfile"})` and restart. Startup shows a reminder
  while v1 is installed.
- The LSP setup already uses `vim.lsp.config` and `vim.lsp.enable`, the API recommended by
  [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig). No framework migration is needed.
- The Tree-sitter setup uses the newer `main` branch API. Its current revision matches upstream;
  watch
  [upstream migration notes](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md)
  when updating parsers and queries. Install `tree-sitter-cli` 0.26.1 or newer before updating
  parsers.
- Snipe and MiniPick both provide a buffer picker (`<Space>sn` and `<Space>pb`). If the Snipe hint
  UI is not useful, removing it would simplify this setup. Likewise, `smartcolumn.nvim` and the
  fixed `colorcolumn=120` both mark a width; choose the behavior you prefer before removing one.
- `FloatermClose` reaches into `volt.utils` and Floaterm state, which are plugin internals. It is
  the most fragile plugin integration here; check it after updating Floaterm and Volt.
- The shared LSP `on_attach` stops Tree-sitter whenever a server offers semantic tokens. This is a
  deliberate visual tradeoff; if Tree-sitter selections or highlighting appear to vanish after LSP
  attach, review that condition before changing parser setup.
