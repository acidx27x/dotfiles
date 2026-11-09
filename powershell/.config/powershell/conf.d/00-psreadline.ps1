# ~/.config/powershell/conf.d/00-psreadline.ps1
# Fish/Emacs editing keys in PSReadLine vi mode.

if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
  return
}

Import-Module PSReadLine
Set-PSReadLineOption -EditMode Vi

Set-PSReadLineKeyHandler -Chord 'Ctrl+a' -Function BeginningOfLine -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+e' -Function EndOfLine -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+b' -Function BackwardChar -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function ForwardChar -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Alt+b' -Function BackwardWord -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Alt+f' -Function ForwardWord -ViMode Insert

Set-PSReadLineKeyHandler -Chord 'Ctrl+u' -Function BackwardKillLine -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+k' -Function KillLine -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardKillWord -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function KillWord -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Alt+Backspace' -Function BackwardKillWord -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Yank -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Alt+y' -Function YankPop -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -Function SwapCharacters -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+_' -Function Undo -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Tab' -Function ViTabCompleteNext -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Shift+Tab' -Function ViTabCompletePrevious -ViMode Insert

# PSReadLine has no transpose-words handler; swap whitespace-delimited words around the cursor.
Set-PSReadLineKeyHandler -Chord 'Alt+t' -ViMode Insert -ScriptBlock {
  $line = ''
  $cursor = 0
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref] $line, [ref] $cursor)
  $words = [regex]::Matches($line, '\S+')
  if ($words.Count -lt 2) { return }

  $right = 0
  while ($right -lt $words.Count -and $words[$right].Index + $words[$right].Length -le $cursor) {
    $right++
  }
  if ($right -eq 0) { $right = 1 }
  if ($right -eq $words.Count) { $right-- }

  $leftWord = $words[$right - 1]
  $rightWord = $words[$right]
  $gap = $line.Substring($leftWord.Index + $leftWord.Length,
    $rightWord.Index - $leftWord.Index - $leftWord.Length)
  $end = $rightWord.Index + $rightWord.Length
  [Microsoft.PowerShell.PSConsoleReadLine]::Replace($leftWord.Index,
    $end - $leftWord.Index, $rightWord.Value + $gap + $leftWord.Value)
  [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end)
}

if ((Get-Module PSReadLine).Version -ge [version] '2.3.0') {
  Set-PSReadLineKeyHandler -Chord 'Alt+u' -Function UpcaseWord -ViMode Insert
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+p' -Function PreviousHistory -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+n' -Function NextHistory -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+p' -Function PreviousHistory -ViMode Command
Set-PSReadLineKeyHandler -Chord 'Ctrl+n' -Function NextHistory -ViMode Command

Set-PSReadLineKeyHandler -Chord 'Ctrl+x,Ctrl+e' -Function ViEditVisually -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Alt+e' -Function ViEditVisually -ViMode Insert
Set-PSReadLineKeyHandler -Chord 'Ctrl+x,Ctrl+e' -Function ViEditVisually -ViMode Command
