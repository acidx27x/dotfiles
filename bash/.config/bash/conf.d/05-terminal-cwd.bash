# ~/.config/bash/conf.d/05-terminal-cwd.bash
# Report the directory for terminals without native shell integration.

if [[ ${TERM_PROGRAM:-} == WezTerm || ${TERM:-} == foot || ${TERM:-} == foot-direct ]]; then
  __terminal_report_cwd() {
    local status=$?
    local LC_ALL=C
    local directory=$PWD encoded='' character hex index

    # Encode URI delimiters, whitespace, and non-ASCII bytes in the path.
    for ((index = 0; index < ${#directory}; index++)); do
      character=${directory:index:1}
      case $character in
        [a-zA-Z0-9/._~-]) encoded+=$character ;;
        *)
          printf -v hex '%%%02X' "'$character"
          encoded+=$hex
          ;;
      esac
    done

    printf '\e]7;file://%s%s\a' "$HOSTNAME" "$encoded"
    return "$status"
  }

elif [[ (-z ${TERM_PROGRAM:-} || ${TERM_PROGRAM:-} == Windows_Terminal) &&
  ${TERM:-} != xterm-kitty && -n ${WT_SESSION:-} && -n ${WSL_DISTRO_NAME:-} &&
  -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]] && has-cmd wslpath; then
  __terminal_report_cwd() {
    local status=$?
    local windows_path

    # Windows Terminal needs a Windows/UNC path, even for a Linux directory.
    windows_path=$(wslpath -w "$PWD") || return "$status"
    # OSC 9;9 has no URI encoding; do not emit terminal controls from filenames.
    [[ $windows_path != *[$'\001'-$'\037'$'\177']* ]] || return "$status"
    printf '\e]9;9;"%s"\a' "$windows_path"
    return "$status"
  }
else
  # Ghostty and kitty provide their own directory-reporting integration.
  return 0
fi

add-prompt-command __terminal_report_cwd
