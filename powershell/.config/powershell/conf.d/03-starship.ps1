# ~/.config/powershell/conf.d/03-starship.ps1
# Starship prompt.

if (Test-Command starship) {
  if ($env:TERM_PROGRAM -eq 'WezTerm' -or $env:WT_SESSION) {
    # Report the directory so new terminal tabs and panes can inherit it.
    function Invoke-Starship-PreCommand {
      $location = $executionContext.SessionState.Path.CurrentLocation
      if ($location.Provider.Name -eq 'FileSystem') {
        if ($env:TERM_PROGRAM -eq 'WezTerm') {
          $directoryUri = [System.UriBuilder]::new([uri]$location.ProviderPath)
          if (-not $directoryUri.Host) {
            $directoryUri.Host = [System.Environment]::MachineName
          }
          $host.UI.Write("$([char]27)]7;$($directoryUri.Uri.AbsoluteUri)$([char]27)\")
        } else {
          $host.UI.Write("$([char]27)]9;9;`"$($location.ProviderPath)`"$([char]27)\")
        }
      }
    }
  }

  Invoke-Expression (&starship init powershell)
}
