#!/usr/bin/env bash
# ~/.config/tmux/scripts/snapshots.sh — browse and manage tmux-persist snapshots.

snapshot_layout() {
  case "$1" in
    *.tgz) tar xzOf "$1" ./layout ;;
    *.txt) cat -- "$1" ;;
  esac
}

preview() {
  snapshot_layout "$1" | awk -F '\t' '
    $1 == "window" { printf "\n%s / window %s: %s\n", $2, $3, substr($4, 2) }
    $1 == "pane" { printf "  %s / window %s / pane %s: %s\n", $2, $3, $6, substr($8, 2) }
    $1 == "grouped_session" { printf "%s shares windows with %s\n", $2, $3 }
  '
}

snapshot_session() {
  local stem=${1%.*}
  _unsanitize_session_from_path "${stem%_*}"
}

snapshot_files() {
  local file name stem session
  for file in "$snapshot_dir"/*_????????T??????.{tgz,txt}; do
    [[ -f "$file" ]] || continue
    name=${file##*/}
    stem=${name%.*}
    [[ "${stem##*_}" =~ ^[0-9]{8}T[0-9]{6}$ ]] || continue
    session=$(snapshot_session "$name")
    [[ -z "${1:-}" || "$session" == "$1" ]] || continue
    if [[ "$name" == tmux_resurrect_*.txt ]]; then
      # Legacy files can share this pattern with a session named tmux_resurrect.
      [[ ! "$file" -ef "$snapshot_dir/last" ]] || continue
      awk -F '\t' '
        $1 == "state" || ($1 ~ /^(window|pane|grouped_session)$/ && $2 != "tmux_resurrect") {
          exit 1
        }
      ' "$file" || continue
    fi
    printf '%s\t%s\t%s\n' "$session" "${stem##*_}" "$name"
  done | LC_ALL=C sort -t $'\t' -k1,1 -k2,2r
}

snapshot_rows() {
  local file session timestamp marker windows
  while IFS=$'\t' read -r session timestamp file; do
    marker=' '
    [[ "$snapshot_dir/$file" -ef "$(last_session_file "$session")" ]] && marker='●'
    windows=$(snapshot_layout "$snapshot_dir/$file" |
      awk -F '\t' '$1 == "window" { n++ } END { print n+0 }')
    printf '%s\t%s %s-%s-%s %s:%s:%s\t%s / %d windows\n' "$file" "$marker" \
      "${timestamp:0:4}" "${timestamp:4:2}" "${timestamp:6:2}" \
      "${timestamp:9:2}" "${timestamp:11:2}" "${timestamp:13:2}" "$session" "$windows"
  done < <(snapshot_files)
}

set_latest() {
  local last=$1 target=$2
  [[ -n "$target" && "$(readlink "$last")" == "$target" ]] && return 0
  rm -f -- "$last.hash" || return
  if [[ -n "$target" ]]; then
    ln -sfn -- "$target" "$last"
  else
    rm -f -- "$last"
  fi
}

delete_snapshot() {
  local file=$1 session last newest was_latest=false
  session=$(snapshot_session "${file##*/}")
  last=$(last_session_file "$session")
  [[ "$file" -ef "$last" ]] && was_latest=true
  if [[ "$file" == *.txt ]]; then
    rm -f -- "$(snapshot_companion_file "$file")" || return
  fi
  rm -f -- "$file" || return
  if [[ "$was_latest" == true && -L "$last" && ! -e "$last" ]]; then
    newest=$(snapshot_files "$session" | head -n 1)
    set_latest "$last" "${newest##*$'\t'}"
  fi
}

confirm() {
  local answer
  printf '\n%s [y/N] ' "$1"
  IFS= read -r answer || return 1
  [[ "$answer" == y || "$answer" == Y ]]
}

persist_script() {
  local script
  script=$(tmux show-option -gqv "@persist-$1-script-path")
  if [[ ! -x "$script" ]]; then
    printf '%s: install tmux-persist with prefix + Shift+i, then reload.\n' "${BASH_SOURCE[0]}" >&2
    return 1
  fi
  printf '%s\n' "$script"
}

can_restore() {
  [[ -n "$1" && "$1" != all && "$1" != quiet && "$1" != _deferred_focus_restore ]]
}

save_session_snapshot() {
  local script=$1 session=$2
  if [[ -z "$session" || "$session" == all || "$session" == quiet ]]; then
    tmux display-message 'Cannot save this session by name with tmux-persist.'
    return 1
  fi
  tmux has-session -t "=$session" || return
  bash "$script" "$session"
}

browse() {
  local caller=$1 save_script restore_script snapshot_dir selection action file session last
  local self preview_command preview_label_command header row notice=''
  local -a files rows picker_options
  if ! command -v fzf >/dev/null 2>&1; then
    printf '%s: fzf is required.\n' "${BASH_SOURCE[0]}" >&2
    return 127
  fi
  save_script=$(persist_script save) || return
  restore_script=$(persist_script restore) || return
  # Use Persist's configured directory, including its legacy directory fallback.
  # shellcheck disable=SC1091
  source "${save_script%/*}/helpers.sh"
  snapshot_dir=$(persist_dir)
  self=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/${BASH_SOURCE[0]##*/}
  printf -v preview_command 'bash %q preview %q/{1}' "$self" "$snapshot_dir"
  # The second field ends with the 19-character timestamp, after the auto-restore marker.
  preview_label_command="timestamp={2}; printf '%s' \"\${timestamp:+ [ \${timestamp: -19} ] }\""
  # Ignore a stale inherited options-file path, while retaining valid fzf preferences.
  if [[ -n "${FZF_DEFAULT_OPTS_FILE:-}" && ! -r "$FZF_DEFAULT_OPTS_FILE" ]]; then
    unset FZF_DEFAULT_OPTS_FILE
  fi
  picker_options=(
    --no-tmux --height=100% --layout=reverse --border=rounded --highlight-line
    --no-sort --delimiter=$'\t' --with-nth=2.. --pointer='▶'
  )
  header='enter=󰿄  ctrl+s=󰆓  alt+bspace=󱂧  tab=✓  esc=󰌍  ● auto-restore'
  while true; do
    selection=$(snapshot_rows | fzf "${picker_options[@]}" --multi \
      --border-label=' Persist snapshots ' --prompt='∼ ' --marker='✓' --info=inline \
      --header="$notice$header" \
      --bind='enter:print(enter)+accept,ctrl-s:print(ctrl-s)+accept' \
      --bind='alt-backspace:print(delete)+accept' \
      --bind='tab:toggle+down,btab:toggle+up' \
      --bind="focus:transform-preview-label($preview_label_command)" \
      --preview="$preview_command" --preview-window=up,60%,border-bottom \
      --with-shell='bash -c') || {
      # fzf returns 1 when accepting an empty list, even after print(ctrl-s).
      [[ "$selection" == ctrl-s ]] || return 0
    }
    notice=''
    action=${selection%%$'\n'*}
    if [[ "$action" == ctrl-s ]]; then
      save_session_snapshot "$save_script" "$caller" || return
      continue
    fi
    files=()
    rows=()
    while IFS= read -r row; do
      file=${row%%$'\t'*}
      if [[ -n "$file" && -f "$snapshot_dir/$file" ]]; then
        files+=("$snapshot_dir/$file")
        rows+=("$row")
      fi
    done <<<"${selection#*$'\n'}"
    [[ ${#files[@]} -gt 0 ]] || continue
    case "$action" in
      enter)
        if [[ ${#files[@]} -gt 1 ]]; then
          notice=$'Select only one snapshot to restore.\n'
          continue
        fi
        file=${files[0]##*/}
        session=$(snapshot_session "$file")
        if ! can_restore "$session"; then
          notice=$'tmux-persist reserves this session name.\n'
          continue
        fi
        confirm 'Restore this session? A session with one pane may have that pane replaced.' ||
          continue
        [[ -f "${files[0]}" ]] || continue
        last=$(last_session_file "$session")
        set_latest "$last" "$file" || return
        bash "$restore_script" "$session"
        return
        ;;
      delete)
        selection=$(printf '%s\n' "${rows[@]}" | fzf "${picker_options[@]}" \
          --no-input --no-preview --no-multi --info=hidden \
          --border-label=' Delete snapshots ' --header='y=󰿄 delete  esc=󰌍 cancel' \
          --bind='enter:ignore,double-click:ignore' \
          --bind='y:print(delete)+accept,Y:print(delete)+accept,n:abort,N:abort') || continue
        [[ ${selection%%$'\n'*} == delete ]] || continue
        for file in "${files[@]}"; do
          delete_snapshot "$file" || return
        done
        ;;
    esac
  done
}

case "${1:-}" in
  preview) preview "$2" ;;
  save)
    script=$(persist_script save) || exit
    save_session_snapshot "$script" "${2:-}"
    ;;
  restore)
    if ! can_restore "${2:-}"; then
      tmux display-message 'Cannot restore this session by name with tmux-persist.'
      exit 1
    fi
    script=$(persist_script restore) || exit
    bash "$script" "$2"
    ;;
  *) browse "${2:-}" ;;
esac
