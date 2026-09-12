# ~/.config/bash/functions.bash
# User-facing interactive Bash functions.

# Print the currently running interactive shell.
current-shell() {
  if is-brush; then
    printf 'brush %s\n' "$BRUSH_VERSION"
  else
    printf 'bash %s\n' "${BASH_VERSION:-unknown}"
  fi
}

# Print the resolved XDG paths.
print-xdg-paths() {
  printf '%-24s %s\n' \
    "XDG_DATA_HOME"        "$XDG_DATA_HOME" \
    "XDG_CONFIG_HOME"      "$XDG_CONFIG_HOME" \
    "XDG_STATE_HOME"       "$XDG_STATE_HOME" \
    "XDG_CACHE_HOME"       "$XDG_CACHE_HOME" \
    "XDG_RUNTIME_DIR"      "${XDG_RUNTIME_DIR:-<not set>}" \
    "XDG_DATA_DIRS"        "$XDG_DATA_DIRS" \
    "XDG_CONFIG_DIRS"      "$XDG_CONFIG_DIRS" \
    "XDG_USER_BIN_HOME"    "$XDG_USER_BIN_HOME" \
    "XDG_DESKTOP_DIR"      "$XDG_DESKTOP_DIR" \
    "XDG_DOWNLOAD_DIR"     "$XDG_DOWNLOAD_DIR" \
    "XDG_TEMPLATES_DIR"    "$XDG_TEMPLATES_DIR" \
    "XDG_PUBLICSHARE_DIR"  "$XDG_PUBLICSHARE_DIR" \
    "XDG_DOCUMENTS_DIR"    "$XDG_DOCUMENTS_DIR" \
    "XDG_MUSIC_DIR"        "$XDG_MUSIC_DIR" \
    "XDG_PICTURES_DIR"     "$XDG_PICTURES_DIR" \
    "XDG_VIDEOS_DIR"       "$XDG_VIDEOS_DIR"
}

# List user-facing functions available in the current shell.
functions-help() {
  _print-function-catalog 'Bash user functions:' \
    color-status 'Show the active terminal color configuration.' \
    current-shell 'Print the current interactive shell and version.' \
    detect-encoding 'Detect the likely encoding of a text file.' \
    ffd 'Select a file or directory with fzf, then choose an action.' \
    fgb 'Select Git branches with fzf.' \
    fgf 'Select Git files with fzf.' \
    fgh 'Select Git commit hashes with fzf.' \
    fghelp 'List the short fzf-git functions.' \
    fgs 'Select Git stashes with fzf.' \
    fgt 'Select Git tags with fzf.' \
    fgw 'Select Git worktrees with fzf.' \
    fman 'Find and open a man page with fzf.' \
    frg 'Search file contents with ripgrep, then choose an action.' \
    functions-help 'List available user-facing Bash functions.' \
    homebrew-path-prepend 'Prepend Homebrew bin directories to PATH.' \
    homebrew-path-remove 'Remove Homebrew directories from PATH.' \
    homebrew-tool-path-prepend 'Prepend Homebrew formula bin directories to PATH.' \
    l 'List entries with eza in long form.' \
    ldr 'List directories with eza in long form.' \
    ll 'List all entries with eza in long form.' \
    llt 'Show all entries as a detailed eza tree.' \
    ls 'List one entry per line with eza.' \
    lt 'Show entries as an eza tree.' \
    print-xdg-paths 'Print the resolved XDG paths.' \
    rm-zone-id 'Delete Windows Zone.Identifier metadata files.' \
    stellar-help 'Show Stellar installation and theme instructions.' \
    to-us-ascii 'Transliterate text files to US-ASCII.' \
    to-utf8 'Convert text files to UTF-8 without a BOM.' \
    to-utf8-bom 'Convert text files to UTF-8 with one BOM.' \
    NO, NE, NA 'Redirect command output to /dev/null.' \
    karing-proxy-enable 'Overwrite HTTP variables for karing network.' \
    utils-help 'List available Bash configuration utilities.'
}

# Remove Windows download-zone metadata files recursively.
#
# Usage:
#   rm-zone-id
#   rm-zone-id ~/Downloads
rm-zone-id() {
  local root="${1:-.}"

  [[ -d "$root" ]] || {
    printf 'Not a directory: %s\n' "$root" >&2
    return 1
  }

  find "$root" \
    -type f \
    -name '*:Zone.Identifier' \
    -print \
    -delete
}

# Detect the likely encoding of a text file.
detect-encoding() {
  local file="${1:-}"
  local encoding=""

  [[ -n "$file" ]] || {
    printf 'Usage: detect-encoding FILE\n' >&2
    return 2
  }

  [[ -f "$file" && -r "$file" ]] || {
    printf 'Not a readable regular file: %s\n' "$file" >&2
    return 1
  }

  if has-cmd uchardet; then
    encoding=$(uchardet "$file" 2>/dev/null || true)
  fi

  case "$encoding" in
    "" | unknown | UNKNOWN)
      has-cmd file || {
        printf 'Neither uchardet nor file is available.\n' >&2
        return 127
      }

      encoding=$(file -b --mime-encoding -- "$file") || return
      ;;
  esac

  case "$encoding" in
    binary | BINARY)
      printf 'binary\n'
      ;;

    us-ascii | US-ASCII | ascii | ASCII)
      printf 'UTF-8\n'
      ;;

    utf-8 | UTF-8)
      printf 'UTF-8\n'
      ;;

    unknown-8bit | UNKNOWN-8BIT | unknown | UNKNOWN | "")
      printf 'Could not determine encoding: %s\n' "$file" >&2
      return 2
      ;;

    *)
      printf '%s\n' "$encoding"
      ;;
  esac
}

_file_exists_and_rw() {
  local file="$1"

  [[ -f "$file" && -r "$file" && -w "$file" ]] || {
    printf 'Not a readable and writable regular file: %s\n' \
      "$file" >&2
    return 1
  }
}

_to_utf8_impl() {
  local add_bom="$1"
  local command_name="$2"
  shift 2

  local file
  local encoding
  local temp
  local body
  local signature

  (( $# > 0 )) || {
    printf 'Usage: %s FILE...\n' "$command_name" >&2
    return 2
  }

  has-cmd iconv || {
    printf 'iconv is required.\n' >&2
    return 127
  }

  for file in "$@"; do
    _file_exists_and_rw "$file" || continue

    if ! encoding=$(detect-encoding "$file"); then
      printf 'Skipping file with unknown encoding: %s\n' \
        "$file" >&2
      continue
    fi

    if [[ "$encoding" == binary ]]; then
      printf 'Skipping binary file: %s\n' "$file" >&2
      continue
    fi

    temp=$(mktemp) || return 1
    body=""

    if ! iconv \
      -f "$encoding" \
      -t UTF-8 \
      "$file" > "$temp"
    then
      printf 'iconv failed for %s using encoding %s\n' \
        "$file" "$encoding" >&2

      rm -f -- "$temp"
      continue
    fi

    signature=$(
      LC_ALL=C od -An -tx1 -N3 "$temp" |
        tr -d ' \n'
    )

    if [[ "$signature" == efbbbf ]]; then
      body=$(mktemp) || {
        rm -f -- "$temp"
        return 1
      }

      if ! tail -c +4 -- "$temp" > "$body"; then
        rm -f -- "$temp" "$body"
        continue
      fi

      mv -f -- "$body" "$temp"
      body=""
    fi

    if (( add_bom )); then
      body=$(mktemp) || {
        rm -f -- "$temp"
        return 1
      }

      if ! {
        printf '\xEF\xBB\xBF'
        cat -- "$temp"
      } > "$body"
      then
        rm -f -- "$temp" "$body"
        continue
      fi

      mv -f -- "$body" "$temp"
      body=""
    fi

    if ! cat -- "$temp" > "$file"; then
      printf 'Failed to overwrite: %s\n' "$file" >&2
      rm -f -- "$temp"
      continue
    fi

    rm -f -- "$temp"

    if (( add_bom )); then
      printf 'Converted to UTF-8 with BOM from %s: %s\n' \
        "$encoding" "$file"
    else
      printf 'Converted to UTF-8 from %s: %s\n' \
        "$encoding" "$file"
    fi
  done
}

# Convert files to plain UTF-8, removing an existing BOM.
to-utf8() {
  _to_utf8_impl 0 to-utf8 "$@"
}

# Convert files to UTF-8 and ensure exactly one BOM is present.
to-utf8-bom() {
  _to_utf8_impl 1 to-utf8-bom "$@"
}

# Transliterate text files to US-ASCII.
to-us-ascii() {
  local file
  local encoding
  local temp
  local uconv_command=""
  local brew_command=""
  local brew_candidate
  local icu_prefix=""

  (( $# > 0 )) || {
    printf 'Usage: to-us-ascii FILE...\n' >&2
    return 2
  }

  if has-cmd uconv; then
    uconv_command=$(command -v uconv)
  else
    if [[ -n ${HOMEBREW_BREW_FILE:-} && -x $HOMEBREW_BREW_FILE ]]; then
      brew_command=$HOMEBREW_BREW_FILE
    elif has-cmd brew; then
      brew_command=$(command -v brew)
    else
      for brew_candidate in \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew \
        /home/linuxbrew/.linuxbrew/bin/brew \
        "$HOME/.linuxbrew/bin/brew"
      do
        if [[ -x "$brew_candidate" ]]; then
          brew_command=$brew_candidate
          break
        fi
      done
    fi

    if [[ -n "$brew_command" ]]; then
      icu_prefix=$("$brew_command" --prefix icu4c 2>/dev/null) || icu_prefix=""

      if [[ -n "$icu_prefix" && -x "$icu_prefix/bin/uconv" ]]; then
        uconv_command="$icu_prefix/bin/uconv"
      fi
    fi
  fi

  [[ -n "$uconv_command" ]] || {
    printf 'uconv is required (Homebrew: icu4c; Debian/Ubuntu: icu-devtools).\n' >&2
    return 127
  }

  for file in "$@"; do
    _file_exists_and_rw "$file" || continue

    if ! encoding=$(detect-encoding "$file"); then
      printf 'Skipping file with unknown encoding: %s\n' \
        "$file" >&2
      continue
    fi

    if [[ "$encoding" == binary ]]; then
      printf 'Skipping binary file: %s\n' "$file" >&2
      continue
    fi

    temp=$(mktemp) || return 1

    if ! "$uconv_command" \
      -f "$encoding" \
      -t US-ASCII \
      -x 'Any-Latin; Latin-ASCII' \
      --to-callback stop \
      "$file" > "$temp"
    then
      printf 'uconv failed for %s using encoding %s\n' \
        "$file" "$encoding" >&2

      rm -f -- "$temp"
      continue
    fi

    if ! cat -- "$temp" > "$file"; then
      printf 'Failed to overwrite: %s\n' "$file" >&2
      rm -f -- "$temp"
      continue
    fi

    rm -f -- "$temp"

    printf 'Converted to US-ASCII from %s: %s\n' \
      "$encoding" "$file"
  done
}

# Redirect wrappers
NO() {
  "$@" >/dev/null
}

NE() {
  "$@" 2>/dev/null
}

NA() {
  "$@" >/dev/null 2>&1
}

# karing windows share network to wsl
karing-proxy-enable() {
  local mountpoint="/mnt/c"
  local powershell="${mountpoint}/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
  local mounted_by_us=0
  local host_ip
  local karing_running

  # 1. Make sure we're actually running under WSL.
  if ! grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease 2>/dev/null; then
    printf 'WARNING, karing-proxy-enable unavailable: not running under WSL.\n' >&2
    return 1
  fi

  printf '%s%s\n' \
    'WARNING, karing-proxy-enable: this function may require sudo to ' \
    "mount 'C:' to run powershell." >&2

  # 2. Temporarily mount Windows C: if it isn't already mounted.
  if ! mountpoint -q "$mountpoint"; then
    if ! sudo mkdir -p "$mountpoint"; then
      printf 'WARNING, karing-proxy-enable unavailable: could not create %s.\n' "$mountpoint" >&2
      return 1
    fi

    if ! sudo mount -t drvfs C: "$mountpoint"; then
      printf '%s\n' \
        "WARNING, karing-proxy-enable unavailable: could not temporarily mount Windows 'C:'." >&2
      return 1
    fi

    mounted_by_us=1
  fi

  # Helper: only unmount if this function mounted it.
  _karing_cleanup_mount() {
    if [ "$mounted_by_us" -eq 1 ]; then
      sudo umount "$mountpoint"
    fi
  }

  # 3. Check that PowerShell is accessible.
  if [ ! -x "$powershell" ]; then
    printf 'WARNING, karing-proxy-enable unavailable: powershell.exe not found.\n' >&2
    _karing_cleanup_mount
    unset -f _karing_cleanup_mount
    return 1
  fi

  # 4. Check whether Karing is running on Windows.
  karing_running=$(
    "$powershell" -NoProfile -Command '
      if (Get-Process -Name "karing" -ErrorAction SilentlyContinue) {
        "yes"
      } else {
        "no"
      }
    ' | tr -d '\r'
  )

  if [ "$karing_running" != "yes" ]; then
    printf 'WARNING, karing-proxy-enable unavailable: Karing is not running on Windows.\n' >&2
    _karing_cleanup_mount
    unset -f _karing_cleanup_mount
    return 1
  fi

  # 5. Detect the Windows host IP.
  host_ip=$(
    "$powershell" -NoProfile -Command '
      Get-NetIPConfiguration |
      Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -eq "Up" -and
        $_.InterfaceAlias -notmatch "vEthernet|WSL|TUN|TAP"
      } |
      Select-Object -First 1 |
      ForEach-Object { $_.IPv4Address.IPAddress }
    ' | tr -d '\r'
  )

  # We no longer need access to C:.
  _karing_cleanup_mount
  unset -f _karing_cleanup_mount

  if [ -z "$host_ip" ]; then
    printf 'WARNING, karing-proxy-enable unavailable: could not detect Windows host IP.\n' >&2
    return 1
  fi

  # 6. Enable proxy in the current shell.
  export http_proxy="http://${host_ip}:4067"
  export https_proxy="$http_proxy"
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$http_proxy"

  printf 'Proxy enabled from karing: %s\n' "$http_proxy"
}

proxy-disable() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  printf 'Proxy disabled\n'
}
