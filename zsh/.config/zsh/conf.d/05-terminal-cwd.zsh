# ~/.config/zsh/conf.d/05-terminal-cwd.zsh
# Report the directory for terminals without native shell integration.

if [[ ${TERM_PROGRAM:-} == WezTerm || ${TERM:-} == foot || ${TERM:-} == foot-direct ]]; then
  __terminal_report_cwd() {
    emulate -L zsh
    local LC_ALL=C
    local directory=$PWD encoded='' character hex
    local -i index

    # Encode URI delimiters, whitespace, and non-ASCII bytes in the path.
    for ((index = 1; index <= ${#directory}; index++)); do
      character=$directory[index]
      case $character in
        [a-zA-Z0-9/._~-]) encoded+=$character ;;
        *)
          printf -v hex '%%%02X' "'$character"
          encoded+=$hex
          ;;
      esac
    done

    printf '\e]7;file://%s%s\a' "$HOST" "$encoded"
    # A failing precmd hook would prevent subsequent Zsh hooks from running.
    return 0
  }
elif [[ (-z ${TERM_PROGRAM:-} || ${TERM_PROGRAM:-} == Windows_Terminal) &&
  ${TERM:-} != xterm-kitty && -n ${WT_SESSION:-} && -n ${WSL_DISTRO_NAME:-} &&
  -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]] && has-cmd wslpath; then
  __terminal_report_cwd() {
    emulate -L zsh

    local windows_path
    # Windows Terminal needs a Windows/UNC path, even for a Linux directory.
    windows_path=$(wslpath -w "$PWD") || return 0
    # OSC 9;9 has no URI encoding; do not emit terminal controls from filenames.
    [[ $windows_path != *[$'\001'-$'\037'$'\177']* ]] || return 0
    printf '\e]9;9;"%s"\a' "$windows_path"
    return 0
  }
else
  # Ghostty and kitty provide their own directory-reporting integration.
  return 0
fi

autoload -Uz add-zsh-hook
add-zsh-hook precmd __terminal_report_cwd
