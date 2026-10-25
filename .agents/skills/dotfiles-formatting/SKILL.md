---
name: dotfiles-formatting
description: >-
  Apply this repository's editor and formatter configuration when checking or formatting files
  in the dotfiles repository. Use for formatter selection, scoped formatting, and diagnosing
  formatting-check failures; do not use for unrelated repositories.
---

# Dotfiles formatting

Use the repository configuration as the source of truth; do not duplicate all formatter settings
in this skill. Before changing formatting configuration, inspect the relevant rules in
`.editorconfig`, `.dprint.jsonc`, `.PSScriptAnalyzerSettings.psd1`, `.dprint-powershell.ps1`, and
any language-specific config such as `llvm/.clang-format`.

## Configured conventions

- `.editorconfig` supplies editor defaults: UTF-8, LF, final newline, trimmed trailing whitespace,
  and a 100-column soft limit. Most files use two-space indentation; Python uses four spaces and an
  88-column limit; Makefiles use tabs; `.bat` and `.cmd` use CRLF. Markdown preserves trailing
  whitespace for Markdown syntax.
- `.dprint.jsonc` runs the configured dprint plugins for JSON/JSONC, Markdown, TOML, YAML, KDL,
  shell, and Lua. It also routes PowerShell through `.dprint-powershell.ps1`.
- Shell style is configured for shfmt in both `.editorconfig` and `.dprint.jsonc`: two spaces,
  no simplification, no forced next-line binary operators/functions, no spaces after redirects, and
  indented `case` clauses. `.brushrc` is an extra shfmt association. shfmt already recognizes
  `.zsh` and conventional Zsh startup filenames; add associations only for additional file names.
  The pinned dprint shfmt plugin is independent of the Homebrew shfmt binary and currently bundles
  shfmt 3.14.1, including Zsh support.
- PowerShell formatting uses `pwsh` (PowerShell 7 or newer) and PSScriptAnalyzer 1.25.0 or newer.
  If either dependency is unavailable, report the formatter failure; do not treat skipped files as
  successfully checked or remove them from formatting without authorization.
- Respect dprint's configured exclusions, including lock files, `zed/**`, and `ssh/**`. Do not
  change exclusions or formatter coverage unless requested.

## Scoped formatting workflow

When asked to format the repository or a set of folders:

1. Determine the requested scope and check its current status before writing. Preserve unrelated
   working-tree changes.
2. Use `dprint check <folder>` to check a folder and `dprint fmt <folder>` to format it. Never run
   an unscoped `dprint fmt` for a folder-by-folder request.
3. Format one top-level package/folder per batch. After each batch, report the exact scope and
   validation results, then wait for the user's commit/continue instruction before formatting the
   next batch.
4. If dprint delegates a language to another tool, verify that tool is available and honor its
   configuration. For shell files, use `shfmt -d` to check formatting and `bash -n` or `zsh -n` for
   syntax validation when the relevant shell is installed. For PowerShell, use the configured
   dprint exec formatter when `pwsh` and PSScriptAnalyzer are available.
5. Run `git diff --check` on the changed scope and review the diff. Report limitations such as a
   missing formatter, failed plugin download, or files excluded by configuration instead of
   claiming the whole scope passed.

Formatting is mechanical only: do not mix behavior changes into a formatting batch. When a
formatter's version changes output, format and validate only the current authorized scope, then stop
for review/commit before proceeding.
