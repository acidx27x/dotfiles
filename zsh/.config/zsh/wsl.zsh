# ~/.config/zsh/wsl.zsh
# WSL-only drive and Windows integration helpers.

# Check whether we're running under WSL.
wsl-is-wsl() {
  emulate -L zsh

  grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease 2>/dev/null
}

# Normalize a Windows drive name to a lowercase letter.
_wsl-windows-drive-letter() {
  emulate -L zsh

  local drive=${1%:}

  drive=${(L)drive}
  [[ $drive == [a-z] ]] || return 2
  print -r -- "$drive"
}

# Check whether a Windows drive is mounted.
wsl-windows-drive-is-mounted() {
  emulate -L zsh

  local letter
  local mount_path

  (( $# == 1 )) || {
    print -u2 -- "Usage: $funcstack[1] DRIVE"
    return 2
  }

  if ! letter=$(_wsl-windows-drive-letter "$1"); then
    print -u2 -- "WARNING, $funcstack[1]: invalid Windows drive: $1"
    return 2
  fi

  mount_path="/mnt/$letter"
  mountpoint -q "$mount_path"
}

# Check whether a Windows drive is unmounted.
wsl-windows-drive-is-unmounted() {
  emulate -L zsh

  local letter
  local mount_path

  (( $# == 1 )) || {
    print -u2 -- "Usage: $funcstack[1] DRIVE"
    return 2
  }

  if ! letter=$(_wsl-windows-drive-letter "$1"); then
    print -u2 -- "WARNING, $funcstack[1]: invalid Windows drive: $1"
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
  emulate -L zsh

  local drive letter mount_path drive_name
  local result=0

  if ! wsl-is-wsl; then
    print -u2 -- "WARNING, $funcstack[1] unavailable: not running under WSL."
    return 1
  fi

  (( $# > 0 )) || {
    print -u2 -- "Usage: $funcstack[1] DRIVE [DRIVE ...]"
    return 2
  }

  for drive in "$@"; do
    if ! letter=$(_wsl-windows-drive-letter "$drive"); then
      print -u2 -- "WARNING, $funcstack[1]: invalid Windows drive: $drive"
      result=2
      continue
    fi

    mount_path="/mnt/$letter"
    drive_name=${(U)letter}

    if wsl-windows-drive-is-mounted "$drive_name"; then
      print -r -- "Windows '$drive_name:' is already mounted at '$mount_path'."
      continue
    fi

    if ! sudo mkdir -p "$mount_path"; then
      print -u2 -- "WARNING, $funcstack[1]: could not create '$mount_path'."
      (( result == 2 )) || result=1
      continue
    fi

    if ! sudo mount -t drvfs "${drive_name}:" "$mount_path"; then
      print -u2 -- \
        "WARNING, $funcstack[1]: could not mount Windows '$drive_name:'."
      (( result == 2 )) || result=1
      continue
    fi

    print -r -- "Mounted Windows '$drive_name:' at '$mount_path'."
  done

  return $result
}

# Unmount one or more Windows drives.
wsl-windows-drive-unmount() {
  emulate -L zsh

  local drive letter mount_path drive_name
  local result=0

  if ! wsl-is-wsl; then
    print -u2 -- "WARNING, $funcstack[1] unavailable: not running under WSL."
    return 1
  fi

  (( $# > 0 )) || {
    print -u2 -- "Usage: $funcstack[1] DRIVE [DRIVE ...]"
    return 2
  }

  for drive in "$@"; do
    if ! letter=$(_wsl-windows-drive-letter "$drive"); then
      print -u2 -- "WARNING, $funcstack[1]: invalid Windows drive: $drive"
      result=2
      continue
    fi

    mount_path="/mnt/$letter"
    drive_name=${(U)letter}

    if wsl-windows-drive-is-unmounted "$drive_name"; then
      print -r -- "Windows '$drive_name:' is not mounted at '$mount_path'."
      continue
    fi

    if ! sudo umount "$mount_path"; then
      print -u2 -- \
        "WARNING, $funcstack[1]: could not unmount Windows '$drive_name:'."
      (( result == 2 )) || result=1
      continue
    fi

    print -r -- "Unmounted Windows '$drive_name:' from '$mount_path'."
  done

  return $result
}

# Enable the Karing proxy exposed by the Windows host.
wsl-karing-proxy-enable() {
  emulate -L zsh

  local mount_path=/mnt/c
  local powershell="$mount_path/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
  local mounted_by_us=0
  local host_ip=''
  local karing_running=''
  local previous
  local result=0

  if ! wsl-is-wsl; then
    print -u2 -- "WARNING, $funcstack[1] unavailable: not running under WSL."
    return 1
  fi

  print -u2 -- \
    "WARNING, $funcstack[1]: this function may require sudo to mount" \
    "'C:' to run PowerShell."

  if wsl-windows-drive-is-unmounted C; then
    if ! wsl-windows-drive-mount C; then
      print -u2 -- \
        "WARNING, $funcstack[1] unavailable: could not temporarily mount Windows 'C:'."
      return 1
    fi

    mounted_by_us=1
  fi

  if [[ ! -x $powershell ]]; then
    print -u2 -- "WARNING, $funcstack[1] unavailable: powershell.exe not found."
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
    print -u2 -- "WARNING, $funcstack[1] unavailable: could not query Karing."
    result=1
  else
    karing_running=${karing_running//$'\r'/}

    if [[ $karing_running != yes ]]; then
      print -u2 -- \
        "WARNING, $funcstack[1] unavailable: Karing is not running on Windows."
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
      print -u2 -- \
        "WARNING, $funcstack[1] unavailable: could not query the Windows host IP."
      result=1
    else
      host_ip=${host_ip//$'\r'/}

      if [[ -z $host_ip ]]; then
        print -u2 -- \
          "WARNING, $funcstack[1] unavailable: could not detect the Windows host IP."
        result=1
      fi
    fi
  fi

  if (( mounted_by_us )) && ! wsl-windows-drive-unmount C; then
    result=1
  fi

  (( result == 0 )) || return $result

  previous=$(proxy-status) || return

  export http_proxy="http://${host_ip}:4067"
  export https_proxy="$http_proxy"
  export HTTP_PROXY="$http_proxy"
  export HTTPS_PROXY="$http_proxy"

  print -r -- 'Proxy enabled from Karing.'
  print -r -- 'Previous proxy settings:'
  print -r -- "$previous"
  print -r -- 'Current proxy settings:'
  proxy-status
}
