# ~/.config/bash/wsl.bash
# WSL-only drive and Windows integration helpers.

# Check whether we're running under WSL.
wsl-is-wsl() {
  grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease 2>/dev/null
}

# Normalize a Windows drive name to a lowercase letter.
_wsl-windows-drive-letter() {
  local drive=${1%:}
  local letter

  letter=$(printf '%s' "$drive" | tr '[:upper:]' '[:lower:]') || return

  case "$letter" in
  [a-z]) printf '%s\n' "$letter" ;;
  *) return 2 ;;
  esac
}

# Check whether a Windows drive is mounted.
wsl-windows-drive-is-mounted() {
  local letter
  local mount_path

  (($# == 1)) || {
    printf 'Usage: %s DRIVE\n' "${FUNCNAME[0]}" >&2
    return 2
  }

  if ! letter=$(_wsl-windows-drive-letter "$1"); then
    printf 'WARNING, %s: invalid Windows drive: %s\n' "${FUNCNAME[0]}" "$1" >&2
    return 2
  fi

  mount_path="/mnt/$letter"
  mountpoint -q "$mount_path"
}

# Check whether a Windows drive is unmounted.
wsl-windows-drive-is-unmounted() {
  local letter
  local mount_path

  (($# == 1)) || {
    printf 'Usage: %s DRIVE\n' "${FUNCNAME[0]}" >&2
    return 2
  }

  if ! letter=$(_wsl-windows-drive-letter "$1"); then
    printf 'WARNING, %s: invalid Windows drive: %s\n' "${FUNCNAME[0]}" "$1" >&2
    return 2
  fi

  mount_path="/mnt/$letter"
  if mountpoint -q "$mount_path"; then
    return 1
  fi

  return 0
}

# Mount one or more Windows drives.
wsl-windows-drive-mount() {
  local drive
  local letter
  local mount_path
  local drive_name
  local result=0

  if ! wsl-is-wsl; then
    printf 'WARNING, %s unavailable: not running under WSL.\n' "${FUNCNAME[0]}" >&2
    return 1
  fi

  (($# > 0)) || {
    printf 'Usage: %s DRIVE [DRIVE ...]\n' "${FUNCNAME[0]}" >&2
    return 2
  }

  for drive in "$@"; do
    if ! letter=$(_wsl-windows-drive-letter "$drive"); then
      printf 'WARNING, %s: invalid Windows drive: %s\n' \
        "${FUNCNAME[0]}" "$drive" >&2
      result=2
      continue
    fi

    mount_path="/mnt/$letter"
    drive_name=$(printf '%s' "$letter" | tr '[:lower:]' '[:upper:]') || return

    if wsl-windows-drive-is-mounted "$drive_name"; then
      printf "Windows '%s:' is already mounted at '%s'.\n" "$drive_name" "$mount_path"
      continue
    fi

    if ! sudo mkdir -p "$mount_path"; then
      printf "WARNING, %s: could not create '%s'.\n" \
        "${FUNCNAME[0]}" "$mount_path" >&2
      ((result == 2)) || result=1
      continue
    fi

    if ! sudo mount -t drvfs "${drive_name}:" "$mount_path"; then
      printf "WARNING, %s: could not mount Windows '%s:'.\n" \
        "${FUNCNAME[0]}" "$drive_name" >&2
      ((result == 2)) || result=1
      continue
    fi

    printf "Mounted Windows '%s:' at '%s'.\n" "$drive_name" "$mount_path"
  done

  return "$result"
}

# Unmount one or more Windows drives.
wsl-windows-drive-unmount() {
  local drive
  local letter
  local mount_path
  local drive_name
  local result=0

  if ! wsl-is-wsl; then
    printf 'WARNING, %s unavailable: not running under WSL.\n' "${FUNCNAME[0]}" >&2
    return 1
  fi

  (($# > 0)) || {
    printf 'Usage: %s DRIVE [DRIVE ...]\n' "${FUNCNAME[0]}" >&2
    return 2
  }

  for drive in "$@"; do
    if ! letter=$(_wsl-windows-drive-letter "$drive"); then
      printf 'WARNING, %s: invalid Windows drive: %s\n' \
        "${FUNCNAME[0]}" "$drive" >&2
      result=2
      continue
    fi

    mount_path="/mnt/$letter"
    drive_name=$(printf '%s' "$letter" | tr '[:lower:]' '[:upper:]') || return

    if wsl-windows-drive-is-unmounted "$drive_name"; then
      printf "Windows '%s:' is not mounted at '%s'.\n" "$drive_name" "$mount_path"
      continue
    fi

    if ! sudo umount "$mount_path"; then
      printf "WARNING, %s: could not unmount Windows '%s:'.\n" \
        "${FUNCNAME[0]}" "$drive_name" >&2
      ((result == 2)) || result=1
      continue
    fi

    printf "Unmounted Windows '%s:' from '%s'.\n" "$drive_name" "$mount_path"
  done

  return "$result"
}

# Enable the Karing proxy exposed by the Windows host.
wsl-karing-proxy-enable() {
  local mount_path=/mnt/c
  local powershell="$mount_path/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
  local mounted_by_us=0
  local host_ip=''
  local karing_running=''
  local previous
  local result=0

  if ! wsl-is-wsl; then
    printf 'WARNING, %s unavailable: not running under WSL.\n' "${FUNCNAME[0]}" >&2
    return 1
  fi

  printf '%s%s\n' \
    "WARNING, ${FUNCNAME[0]}: this function may require sudo to mount " \
    "'C:' to run PowerShell." >&2

  if wsl-windows-drive-is-unmounted C; then
    if ! wsl-windows-drive-mount C; then
      printf "WARNING, %s unavailable: could not temporarily mount Windows 'C:'.\n" \
        "${FUNCNAME[0]}" >&2
      return 1
    fi

    mounted_by_us=1
  fi

  if [[ ! -x "$powershell" ]]; then
    printf 'WARNING, %s unavailable: powershell.exe not found.\n' \
      "${FUNCNAME[0]}" >&2
    result=1
  elif ! karing_running=$(
    "$powershell" -NoProfile -Command '
      if (Get-Process -Name "karing" -ErrorAction SilentlyContinue) {
        "yes"
      } else {
        "no"
      }
    '
  ); then
    printf 'WARNING, %s unavailable: could not query Karing.\n' \
      "${FUNCNAME[0]}" >&2
    result=1
  else
    karing_running=${karing_running//$'\r'/}

    if [[ "$karing_running" != yes ]]; then
      printf 'WARNING, %s unavailable: Karing is not running on Windows.\n' \
        "${FUNCNAME[0]}" >&2
      result=1
    elif ! host_ip=$(
      "$powershell" -NoProfile -Command '
        Get-NetIPConfiguration |
        Where-Object {
          $_.IPv4DefaultGateway -ne $null -and
          $_.NetAdapter.Status -eq "Up" -and
          $_.InterfaceAlias -notmatch "vEthernet|WSL|TUN|TAP"
        } |
        Select-Object -First 1 |
        ForEach-Object { $_.IPv4Address.IPAddress }
      '
    ); then
      printf 'WARNING, %s unavailable: could not query the Windows host IP.\n' \
        "${FUNCNAME[0]}" >&2
      result=1
    else
      host_ip=${host_ip//$'\r'/}

      if [[ -z "$host_ip" ]]; then
        printf 'WARNING, %s unavailable: could not detect the Windows host IP.\n' \
          "${FUNCNAME[0]}" >&2
        result=1
      fi
    fi
  fi

  if ((mounted_by_us)) && ! wsl-windows-drive-unmount C; then
    result=1
  fi

  ((result == 0)) || return "$result"

  previous=$(proxy-status) || return

  export http_proxy="http://${host_ip}:4067"
  export https_proxy="$http_proxy"
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$http_proxy"

  printf 'Proxy enabled from Karing.\n'
  printf 'Previous proxy settings:\n%s\n' "$previous"
  printf 'Current proxy settings:\n'
  proxy-status
}
