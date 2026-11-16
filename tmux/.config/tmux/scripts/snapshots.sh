#!/usr/bin/env bash
# ~/.config/tmux/scripts/snapshots.sh — browse tmux-resurrect snapshots.

preview() {
  awk -F '\t' '
    $1 == "window" { printf "\n%s / window %s: %s\n", $2, $3, substr($4, 2) }
    $1 == "pane" { printf "  %s / window %s / pane %s: %s\n", $2, $3, $6, substr($8, 2) }
  ' "$1"
}

snapshot_files() {
  local file
  for file in "$snapshot_dir"/tmux_resurrect_*.txt; do
    [[ -f "$file" ]] && printf '%s\n' "${file##*/}"
  done | LC_ALL=C sort -r
}

snapshot_rows() {
  local file timestamp marker
  while IFS= read -r file; do
    timestamp=${file#tmux_resurrect_}
    timestamp=${timestamp%.txt}
    marker=' '
    [[ "$snapshot_dir/$file" -ef "$snapshot_dir/last" ]] && marker='●'
    printf '%s\t%s %s-%s-%s %s:%s:%s\t' "$file" "$marker" \
      "${timestamp:0:4}" "${timestamp:4:2}" "${timestamp:6:2}" \
      "${timestamp:9:2}" "${timestamp:11:2}" "${timestamp:13:2}"
    awk -F '\t' '
      $1 == "window" { windows++ }
      ($1 == "window" || $1 == "pane") && !seen[$2]++ {
        sessions = sessions (sessions ? ", " : "") $2
      }
      END { printf "%s / %d windows\n", sessions, windows }
    ' "$snapshot_dir/$file"
  done < <(snapshot_files)
}

confirm() {
  local answer
  printf '\n%s [y/N] ' "$1"
  IFS= read -r answer || return 1
  [[ "$answer" == y || "$answer" == Y ]]
}

main() {
  local save_script restore_script snapshot_dir selection action file newest
  local self preview_command header row notice=''
  local -a files
  if ! command -v fzf >/dev/null 2>&1; then
    printf '%s: fzf is required.\n' "${BASH_SOURCE[0]}" >&2
    return 127
  fi
  save_script=$(tmux show-option -gqv @resurrect-save-script-path)
  restore_script=$(tmux show-option -gqv @resurrect-restore-script-path)
  save_script=${save_script:-$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh}
  restore_script=${restore_script:-$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh}
  if [[ ! -x "$save_script" || ! -x "$restore_script" ]]; then
    printf '%s: install tmux-resurrect with prefix + Shift+i first.\n' "${BASH_SOURCE[0]}" >&2
    return 1
  fi
  # Use the plugin's directory resolution, including XDG and @resurrect-dir expansion.
  # shellcheck disable=SC1091
  source "${save_script%/*}/helpers.sh"
  snapshot_dir=$(resurrect_dir)
  mkdir -p -- "$snapshot_dir" || return
  self=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/${BASH_SOURCE[0]##*/}
  printf -v preview_command 'bash %q preview %q/{1}' "$self" "$snapshot_dir"
  # Ignore a stale inherited options-file path, while retaining valid fzf preferences.
  if [[ -n "${FZF_DEFAULT_OPTS_FILE:-}" && ! -r "$FZF_DEFAULT_OPTS_FILE" ]]; then
    unset FZF_DEFAULT_OPTS_FILE
  fi
  header=$'Enter: restore   Ctrl+s: save now   Alt+Backspace: delete   Esc: close\n'
  header+=$'Tab / Shift+Tab: mark snapshots   ● latest auto-restore snapshot\n'
  header+='Restore one snapshot at a time; empty list: Ctrl+s to save'
  while true; do
    selection=$(snapshot_rows | fzf --no-tmux --height=100% --multi \
      --layout=reverse --delimiter=$'\t' --with-nth=2.. \
      --prompt='Snapshots ∼ ' \
      --header="$notice$header" \
      --bind='enter:print(enter)+accept,ctrl-s:print(ctrl-s)+accept' \
      --bind='alt-backspace:print(delete)+accept' \
      --bind='tab:toggle+down,btab:toggle+up' \
      --preview="$preview_command" --preview-window=up,60% \
      --with-shell='bash -c') || {
      # fzf returns 1 when accepting an empty list, even after print(ctrl-s).
      [[ "$selection" == ctrl-s ]] || return 0
    }
    notice=''
    action=${selection%%$'\n'*}
    if [[ "$action" == ctrl-s ]]; then
      bash "$save_script" || return
      continue
    fi
    files=()
    while IFS= read -r row; do
      file=${row%%$'\t'*}
      [[ -n "$file" && -f "$snapshot_dir/$file" ]] && files+=("$snapshot_dir/$file")
    done <<<"${selection#*$'\n'}"
    [[ ${#files[@]} -gt 0 ]] || continue
    case "$action" in
      enter)
        if [[ ${#files[@]} -gt 1 ]]; then
          notice=$'Select only one snapshot to restore.\n'
          continue
        fi
        confirm 'Restore? Existing panes stay in place. Use fresh tmux for full recovery.' ||
          continue
        file=${files[0]##*/}
        ln -sfn -- "$file" "$snapshot_dir/last" || return
        bash "$restore_script"
        return
        ;;
      delete)
        printf '\nSelected snapshots:\n'
        printf '  %s\n' "${files[@]##*/}"
        confirm "Delete ${#files[@]} snapshot(s)? Running sessions will stay open." || continue
        rm -- "${files[@]}" || return
        if [[ -L "$snapshot_dir/last" && ! -e "$snapshot_dir/last" ]]; then
          newest=$(snapshot_files | head -n 1)
          if [[ -n "$newest" ]]; then
            ln -sfn -- "$newest" "$snapshot_dir/last" || return
          else
            rm -- "$snapshot_dir/last" || return
          fi
        fi
        ;;
    esac
  done
}

case "${1:-}" in
  preview) preview "$2" ;;
  *) main ;;
esac
