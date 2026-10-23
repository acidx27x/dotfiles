# ~/.config/bash/blerc.bash
# Responsive ble.sh defaults for interactive command editing.

# Wait for a brief idle period before generating automatic suggestions.
bleopt complete_auto_delay=300

# Defer expensive filename highlighting instead of blocking keyboard input.
bleopt highlight_timeout_sync=50
bleopt highlight_timeout_async=500

# Match the Iceberg palette used by the rest of the shell configuration.
ble-face -s syntax_default 'fg=#c6c8d1'
ble-face -s syntax_command 'fg=#e2a478'
ble-face -s syntax_quoted 'fg=#b4be82'
ble-face -s syntax_quotation 'fg=#b4be82,bold'
ble-face -s syntax_escape 'fg=#ada0d3'
ble-face -s syntax_expr 'fg=#84a0c6'
ble-face -s syntax_error 'fg=#161821,bg=#e27878'
ble-face -s syntax_varname 'fg=#e2a478'
ble-face -s syntax_delimiter 'fg=#adb1c4,bold'
ble-face -s syntax_param_expansion 'fg=#ada0d3'
ble-face -s syntax_history_expansion 'fg=#161821,bg=#e2a478'
ble-face -s syntax_function_name 'fg=#ada0d3,bold'
ble-face -s syntax_comment 'fg=#6b7089'
ble-face -s syntax_glob 'fg=#89b8c2,bold'
ble-face -s syntax_brace 'fg=#84a0c6,bold'
ble-face -s syntax_tilde 'fg=#a093c7,bold'
ble-face -s syntax_document 'fg=#828597'
ble-face -s syntax_document_begin 'fg=#828597,bold'

# Command classification overrides syntax_command, so configure it separately.
ble-face -s command_builtin_dot 'fg=#e27878,bold'
ble-face -s command_builtin 'fg=#e2a478'
ble-face -s command_alias 'fg=#89b8c2'
ble-face -s command_function 'fg=#ada0d3'
ble-face -s command_file 'fg=#b4be82'
ble-face -s command_keyword 'fg=#84a0c6'
ble-face -s command_jobs 'fg=#e27878,bold'
ble-face -s command_directory 'fg=#84a0c6,underline'

# Starship does not receive Bash's vi mode. Render its character through ble.sh
# so the symbol can update while the current command is being edited.
ble/prompt/backslash:blerc/starship-character() {
  local color='180;190;130'
  local mode
  local symbol='❯'

  if ble/is-function ble/keymap:vi/script/get-mode; then
    ble/keymap:vi/script/get-mode
  fi
  if [[ $mode == *n ]]; then
    color='226;164;120'
    symbol='❮'
  elif [[ ${STARSHIP_CMD_STATUS:-0} != 0 ]]; then
    color='226;120;120'
  fi

  ble/prompt/print $'\e[1;38;2;'"$color"'m'"$symbol"$'\e[0m '
}

# Return externally edited text to the prompt instead of executing it immediately.
ble/widget/blerc/edit-in-external-editor() {
  local edited
  local editor_status
  local ret

  # ble.sh owns the current editor-state variable.
  # shellcheck disable=SC2154
  ble/widget/edit-and-execute-command.edit "$_ble_edit_str" no-newline
  editor_status=$?
  ((editor_status == 0)) || return "$editor_status"
  edited=$ret

  # Editors normally leave a final newline, which is not part of the command.
  if ble/string#match "$edited" $'[\n]+$'; then
    edited=${edited:0:${#edited}-${#BASH_REMATCH}}
  fi

  ble-edit/content/reset "$edited"
  _ble_edit_ind=${#_ble_edit_str}
  _ble_edit_mark=$_ble_edit_ind

  # Normal mode cannot place the cursor on the newline after a non-empty line.
  if ble/keymap:vi/needs-eol-fix "$_ble_edit_ind"; then
    ((_ble_edit_ind--))
  fi
}

# ble.sh 0.4.0-devel3 maps Readline's edit-and-execute-command to this missing
# widget name while importing .inputrc. Define it to keep that import compatible.
ble/widget/vi-command/edit-and-execute-line() {
  ble/widget/blerc/edit-in-external-editor "$@"
}

# Cursor shape already communicates the active vi mode. Apply vi bindings only
# after the keymap is available because ble.sh loads it lazily.
_blerc_vi_load_hook() {
  bleopt keymap_vi_mode_show=
  bleopt keymap_vi_mode_update_prompt=1

  # Ctrl-C should cancel the current input in either vi mode.
  ble-bind -m vi_imap -f C-c discard-line
  ble-bind -m vi_nmap -f C-c discard-line

  # Navigate logical lines first; the native widgets fall back to history at
  # the top and bottom of the current input.
  ble-bind -m vi_nmap -f up vi-command/backward-line
  ble-bind -m vi_nmap -f down vi-command/forward-line

  # Open the external editor with Ctrl-X Ctrl-E and return for review.
  ble-bind -m vi_imap -f 'C-x C-e' blerc/edit-in-external-editor
  ble-bind -m vi_nmap -f 'C-x C-e' \
    'vi_nmap/@edit blerc/edit-in-external-editor'
}

blehook/eval-after-load keymap_vi _blerc_vi_load_hook
