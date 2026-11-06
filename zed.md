# Shared Zed settings

Keep SSH and WSL connections, `proxy`, and ACP `agent_servers` in `settings.json`'s LOCAL section.
That file is local to each repository checkout and ignored by Git.
`zed/.config/zed/settings.shared.json` contains the settings to commit. The active file has marked
**LOCAL** and **SHARED** sections so changes made in Zed are easy to review.

## Set up or refresh

On Linux or macOS, sync before deploying the Zed package with Stow:

```bash
python3 setup/zed-settings.py sync
./setup/stow.sh deploy --package zed
```

On Windows, Python is in `windows/scoop/Scoopfile.json`. Sync before deploying Zed with Dotter:

```powershell
python .\setup\zed-settings.py sync
pwsh -NoProfile -File .\setup\dotter.ps1 -Package zed
```

Run `sync` again after pulling changes to `settings.shared.json`. It replaces only the SHARED
section and keeps the LOCAL section, including connections, proxy, and ACP settings saved by Zed.
Each machine needs its own checkout for its local file to stay separate.

`sync` seeds an empty `agent_servers` object in LOCAL if it is missing, so Zed can save ACP model,
reasoning, mode, and other per-agent choices there. Keep the entire object local. The separate
`agent` UI and tool preferences remain shared. If `agent_servers` already appears in SHARED, move
it to LOCAL before syncing.

## Project overrides

Put project-specific settings in that project's `.zed/settings.json`. Global search excludes
Git-ignored files by default; add only the ignored paths needed in a project:

```jsonc
{
  "file_scan_inclusions": ["generated/schemas/**", "..."]
}
```

`"..."` appends to the inherited list instead of replacing it. The same applies to
`file_scan_exclusions`, which takes precedence over inclusions. To include all ignored files for one
project, set `search.include_ignored` to `true` and `file_finder.include_ignored` to `"all"` there;
these values override the shared defaults for that project.

## Promote a setting changed in Zed

Zed edits the active `settings.json`. If it changes a setting in the SHARED section, promote that
section into the tracked file, review the diff, and commit it:

```bash
python3 setup/zed-settings.py promote
git diff -- zed/.config/zed/settings.shared.json
git add zed/.config/zed/settings.shared.json
```

On Windows, use `python` instead of `python3`. If a new preference lands in the LOCAL section, move
its JSON entry to the SHARED section before promoting. Keep `ssh_connections`, `wsl_connections`,
`proxy`, and `agent_servers` in LOCAL. Zed can read SSH hosts from the machine's SSH config because
`read_ssh_config` is enabled in the shared settings.

The commands refuse to overwrite a changed SHARED section or a file without the section markers.
When moving from the old tracked `settings.json`, save it outside the checkout. If an unmarked
active file remains after pulling, move it outside the checkout too. Then run `sync` and paste
connection entries from the backup into the LOCAL arrays. If Git merges old connection arrays into
`settings.shared.json`, remove those arrays from the shared file before syncing.
