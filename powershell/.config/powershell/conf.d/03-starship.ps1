# ~/.config/powershell/conf.d/03-starship.ps1
# Starship prompt.

if (Test-Command starship) {
  if ($env:WT_SESSION) {
    # Report the directory so Terminal's duplicate tabs and panes inherit it.
    # https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
    function Invoke-Starship-PreCommand {
      $location = $executionContext.SessionState.Path.CurrentLocation
      if ($location.Provider.Name -eq 'FileSystem') {
        $host.UI.Write("$([char]27)]9;9;`"$($location.ProviderPath)`"$([char]27)\")
      }
    }
  }

  Invoke-Expression (&starship init powershell)
}
