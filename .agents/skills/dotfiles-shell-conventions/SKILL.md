---
name: dotfiles-shell-conventions
description: >-
  Apply this repository's conventions when adding, editing, reviewing, or refactoring Bash
  or Zsh startup files, helpers, functions, and conf.d modules. Use for Bash/Zsh parity,
  shell-native idioms, fzf integration, line wrapping, diagnostics, optional commands, and
  validation. Do not use for unrelated languages or one-off shell commands outside this
  repository.
---

# Dotfiles Bash and Zsh conventions

Keep changes small, behavior-driven, and native to the target shell. Do not copy an
implementation verbatim between Bash and Zsh when either shell has a clearer native form.

## Workflow

1. Read the target file and the corresponding file for the other shell, when one exists.
2. Identify shared behavior, shell-specific behavior, compatibility limits, and local style.
3. Make the minimum change needed and preserve unrelated working-tree modifications.
4. Validate syntax, diagnostics, generated command strings, and Bash/Zsh behavioral parity.

## Shared conventions

- Keep paired Bash and Zsh features behaviorally aligned, including arguments, output,
  return codes, optional dependencies, key bindings, and failure behavior.
- Implement each side using its own shell conventions. Share behavior, not syntax.
- Preserve lexical loading through `conf.d` and machine-local overrides through
  `conf.local.d`.
- Start configuration modules with their installed path and a concise purpose comment.
- Reuse project helpers such as `has-cmd`, `shell-init`, `source-if-exists`, `source-first`,
  `source-conf-dirs`, and `path-prepend` after the file that defines them has been loaded.
- Guard optional programs. Use return status 127 for a missing required command, 2 for
  invalid usage, and 1 for other failures when the surrounding code follows that scheme.
- Propagate selection cancellation and command failures with `|| return` where appropriate.
- Quote command arguments and add `--` before user-controlled paths when the command
  supports it.
- Require explicit confirmation before destructive operations.
- Update `functions-help` or `utils-help` when adding or removing user-facing helpers.
- Preserve XDG paths and existing local environment-loading behavior.

## Bash conventions

- Preserve compatibility with Bash 3.2 on macOS and with Brush where existing code supports
  it. Guard or avoid features introduced in later Bash releases.
- Prefer `[[ ... ]]` for tests. Quote parameter expansions used as command arguments.
- Declare function variables with `local`; use `local -a` and `"${array[@]}"` for arrays.
- Use `printf` for output. Send diagnostics to stderr with `printf '...' >&2`.
- Use `builtin` or `command` only when intentionally bypassing an alias, function, or
  wrapper.
- Preserve intentional dynamic `source` and `export` patterns. Do not rewrite them solely
  to silence ShellCheck warnings.

## Zsh conventions

- Begin every non-trivial function with `emulate -L zsh` to isolate option changes.
- Prefer `[[ ... ]]` and `(( ... ))`. Simple parameters inside `[[ ... ]]` need not be
  quoted, but command arguments still must be quoted.
- Use native forms such as `<->` for integers, `${path:h}` and `${file:t}` for path parts,
  glob qualifiers such as `(N)`, `autoload -Uz`, and `unfunction`.
- Use `typeset -g`, `typeset -gx`, and `typeset -gU` for global, exported, and unique global
  values. Use the tied `path` array when changing `PATH`.
- Use `print -r --` for plain output, `print -u2 --` for diagnostics, and `print -n --` for
  prompts. Use `print -f` or `printf` only when formatting or byte-level behavior requires
  it.
- Respect `NO_CLOBBER`. Use `>|` only when an overwrite is intentional.
- Prefix a command with `command` when intentionally bypassing an alias or wrapper, such as
  `command rm`, `command mv`, or `command cat`.
- Prefer native command, function, alias, and builtin maps over emulating Bash discovery
  mechanisms.

## Formatting

- Treat 100 columns as a soft limit. Split commands one option or argument per line when it
  improves readability and preserves behavior.
- Wrap Bash diagnostics by combining explicit `printf` format arguments when necessary.
- Wrap Zsh plain messages using `print` arguments or safe continuations rather than copying
  Bash formatting code.
- Do not insert whitespace or newlines into fzf actions, reload expressions, environment
  variables, or other protocol-like strings unless the consumer expects them.
- Test the exact rendered value whenever wrapping a generated command or exported option
  string.

## Validation

- Run `bash -n` on every modified Bash file.
- Run targeted ShellCheck checks on modified Bash files when ShellCheck is available.
  Distinguish intentional existing warnings about dynamic sources and exports from new
  warnings.
- Run `zsh -n` on every modified Zsh file when Zsh is available; report when it is skipped.
- Run `git diff --check` and scan modified text for lines longer than 100 columns.
- Exercise optional-command branches and compare generated strings when changing shell
  initialization, fzf previews, bindings, or reload actions.
- Review the final diff and confirm every changed line belongs to the requested task.
