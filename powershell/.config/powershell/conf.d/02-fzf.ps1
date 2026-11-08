# ~/.config/powershell/conf.d/02-fzf.ps1
# fzf defaults and optional PSFzf key bindings.

$env:FZF_DEFAULT_OPTS_FILE = Join-Path $PSScriptRoot '..\fzfrc'

if (-not (Test-Command fzf)) {
  return
}

if (Get-Module -ListAvailable -Name PSFzf) {
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordSetLocation 'Alt+c'
}

function _fzf_open_path {
  param([string] $Path, [string] $Line)

  if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
    return
  }

  $actions = @()
  if (Test-Path -LiteralPath $Path -PathType Leaf) {
    if (Test-Command bat) { $actions += 'bat' }
    $actions += 'cat'
  }
  $actions += 'cd'
  if (Test-Command nvim) { $actions += 'nvim' }
  $actions += 'remove', 'echo'

  $action = $actions | fzf --prompt 'Select command> ' --header-first --header $Path
  if ($LASTEXITCODE -ne 0 -or -not $action) { return }

  switch ($action) {
    'bat' { bat -- $Path }
    'cat' { Get-Content -LiteralPath $Path }
    'cd' {
      if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $fullPath = (Resolve-Path -LiteralPath $Path).Path
        Set-Location -LiteralPath ([System.IO.Path]::GetDirectoryName($fullPath))
      }
      else {
        Set-Location -LiteralPath $Path
      }
    }
    'nvim' {
      if ($Line -match '^\d+$' -and (Test-Path -LiteralPath $Path -PathType Leaf)) {
        nvim "+$Line" -- $Path
      }
      else {
        nvim -- $Path
      }
    }
    'remove' {
      $reply = Read-Host "Remove $Path? [y/N]"
      if ($reply -match '^(?i:y|yes)$') {
        Remove-Item -LiteralPath $Path -Recurse -Force
      }
    }
    'echo' { Write-Output $Path }
  }
}

# fzf uses SHELL for child commands; these pickers use Windows cmd syntax.
function ffd {
  if (-not (Test-Command fd)) {
    Write-Warning 'ffd: fd is required'
    return
  }

  $fdOptions = '--follow --hidden --exclude .git --exclude node_modules'
  # Reload from fzf so cancelling a large fd listing cannot break a PowerShell pipe.
  $initial = 'start:reload:fd --type file ' + $fdOptions
  $toggle = 'ctrl-s:transform:if "%FZF_PROMPT%"=="Files> " ' +
  '(echo ^change-prompt^(Directories^> ^)^+^reload^(fd --type directory ' + $fdOptions + '^)) ' +
  'else (echo ^change-prompt^(Files^> ^)^+^reload^(fd --type file ' + $fdOptions + '^))'

  if ((Test-Command bat) -and (Test-Command eza)) {
    $preview = 'if "%FZF_PROMPT%"=="Files> " (bat --color=always --style=plain -- {}) ' +
    'else (eza --tree --color=always --icons=always -- {})'
  }
  elseif (Test-Command bat) {
    $preview = 'if "%FZF_PROMPT%"=="Files> " (bat --color=always --style=plain -- {}) ' +
    'else (dir {})'
  }
  elseif (Test-Command eza) {
    $preview = 'if "%FZF_PROMPT%"=="Files> " (type {}) ' +
    'else (eza --tree --color=always --icons=always -- {})'
  }
  else {
    $preview = 'if "%FZF_PROMPT%"=="Files> " (type {}) else (dir {})'
  }

  $fzfOptions = @()
  # The initial reload starts empty, so adaptive height would stay too short.
  if (-not $env:TMUX -and -not $env:ZELLIJ) { $fzfOptions += '--height=60%' }

  $previousShell = $env:SHELL
  # Unset SHELL so fzf uses cmd.exe for the reload and preview commands above.
  $env:SHELL = $null
  try {
    $path = fzf @fzfOptions --prompt 'Files> ' --header-first `
      --header 'CTRL-S: Switch between Files/Directories' `
      --bind $initial --bind $toggle --preview $preview
  }
  finally {
    $env:SHELL = $previousShell
  }
  if ($LASTEXITCODE -eq 0 -and $path) { _fzf_open_path $path }
}

function frg {
  if (-not (Test-Command rg)) {
    Write-Warning 'frg: rg is required'
    return
  }

  $query = $args -join ' '
  $rg = 'rg --column --line-number --no-heading --with-filename --color=always ' +
  "--colors path:none --smart-case --hidden --no-messages " +
  '--glob "!**/.git/**" --glob "!**/node_modules/**" ' +
  '--field-match-separator=\t --'
  $options = @(
    '--ansi', '--disabled', '--delimiter=\t', '--with-nth=1,2,4..',
    '--query', $query, '--prompt', 'rg> ', '--header-first',
    '--header', 'Type a ripgrep regex; Enter: select match',
    '--bind', "change:reload:if defined FZF_QUERY ($rg {q} || cd .) else (cd .)",
    '--bind', "start:reload:if defined FZF_QUERY ($rg {q} || cd .) else (cd .)"
  )
  # Ripgrep reload also starts empty, so use a fixed height without a popup.
  if (-not $env:TMUX -and -not $env:ZELLIJ) { $options += '--height=60%' }
  if (Test-Command bat) {
    $options += @(
      '--preview-label', 'Preview',
      '--preview', 'bat --color=always --style=plain --highlight-line {2} -- {1}',
      '--preview-window', 'up,60%,border-bottom,+{2}+3/3'
    )
  }

  $previousShell = $env:SHELL
  $env:SHELL = $null
  try {
    $match = fzf @options
  }
  finally {
    $env:SHELL = $previousShell
  }
  if ($LASTEXITCODE -ne 0 -or -not $match) { return }
  $fields = $match -split "`t", 3
  if ($fields.Count -lt 3 -or $fields[1] -notmatch '^\d+$') {
    Write-Warning 'frg: invalid ripgrep selection'
    return
  }
  _fzf_open_path $fields[0] $fields[1]
}

function _fzf_run_keybinding {
  param([string] $Command)

  $line = ''
  $cursor = 0
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref] $line, [ref] $cursor)

  # Preserve typed input; fzf remains full screen in this PSReadLine branch.
  if ($line) {
    & $Command
    return
  }

  # fzf ignores --height inside a PSReadLine handler; run from the accepted prompt.
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert($Command)
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

if (Get-Module -ListAvailable -Name PSReadLine) {
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  Set-PSReadLineKeyHandler -Chord 'Ctrl+x,Ctrl+f' -ScriptBlock {
    _fzf_run_keybinding 'ffd'
  }
  Set-PSReadLineKeyHandler -Chord 'Ctrl+x,Ctrl+g' -ScriptBlock {
    _fzf_run_keybinding 'frg'
  }
}
