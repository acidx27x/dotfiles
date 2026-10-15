# ~/.config/bash/blerc.bash
# Responsive ble.sh defaults for interactive command editing.

# Wait for a brief idle period before generating automatic suggestions.
bleopt complete_auto_delay=300

# Defer expensive filename highlighting instead of blocking keyboard input.
bleopt highlight_timeout_sync=50
bleopt highlight_timeout_async=500

# Cursor shape already communicates the active vi mode.
_blerc_vi_load_hook() {
  bleopt keymap_vi_mode_show=
}

blehook/eval-after-load keymap_vi _blerc_vi_load_hook
