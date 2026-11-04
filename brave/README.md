# Brave preferences

[`brave.toml`](brave.toml) contains the local Brave preferences you chose to carry across Windows,
Linux, and macOS. Keep Brave Sync enabled for the data it already syncs. Apply this file with
[`dotbrave`](https://github.com/xom11/dotbrave); Brave does not read the TOML directly.

## First use on each machine

1. Install [uv](https://docs.astral.sh/uv/getting-started/installation/) if `uvx` is unavailable.
2. Install the **Fira Code** font family using its
   [official installation instructions](https://github.com/tonsky/FiraCode/wiki/Installing). The
   TOML names that family for standard and fixed-width text. Other font families keep their current
   Brave settings on each machine.
3. From the repository root, preview and apply:

   ```sh
   uvx dotbrave apply --dry-run brave/brave.toml
   uvx dotbrave apply brave/brave.toml
   ```

Review the preview before applying it, especially on a new machine. `dotbrave` may restart a running
Brave window to apply changes. To roll back the most recent apply, run:

```sh
uvx dotbrave apply --undo
```

## Keep a setting changed in Brave

When you already have `brave.toml` and want to keep a change made in Brave's settings UI:

1. **Before changing the setting**, run `uvx dotbrave export --snapshot` to record the current
   profile state.
2. Change one setting in Brave and wait a few seconds for it to save.
3. Run `uvx dotbrave export`. Find the changed key under `[settings]`. The export can also show
   other known or previously managed keys, so identify the specific change before copying it.
4. Add or update that key in `brave/brave.toml`. Keep the rest of the file; do not replace it with
   the whole export.
5. Run `uvx dotbrave apply --dry-run brave/brave.toml` to check the result. On the machine where you
   made the UI change, the value may already match and produce no value diff.
6. Run `uvx dotbrave export --snapshot --clear` when finished.

If you **already changed** a setting without a snapshot, try `uvx dotbrave export` and compare its
value with `brave.toml`. Export includes known and managed keys, but may omit other changes made
before a snapshot. For an omitted key, set the UI option back to its old value, take a snapshot,
then change it again and export. Do this only if you know the old value.

## Fira Code in webpages

The HTML `<link>` and CSS `@import` in Fira Code's
[browser example](https://github.com/tonsky/FiraCode#browser-support) are for website authors to
load and style a web font. They are not Brave preferences and do not go in `brave.toml`. This config
selects your locally installed `Fira Code` as Brave's standard and fixed-width font. A After
applying it, check `brave://settings/fonts`: **Standard font** and **Fixed-width font** should both
show Fira Code. Serif and Sans-serif keep their current values. A website's own CSS may select a
different font; whether its code ligatures appear depends on the site's styles and browser
rendering. The `Fira Code VF` name in that example is for its web font CSS, so it does not require
another entry in this config.

## Useful commands

Run these from the repository root.

- `uvx dotbrave export`: show the current profile's customizations as TOML.
- `uvx dotbrave export -a`: include all shortcut bindings when looking up command names.
- `uvx dotbrave -p "Profile 1" apply --dry-run brave/brave.toml`: preview another profile. The
  default profile is `Default`.
- `uvx dotbrave --channel beta apply --dry-run brave/brave.toml`: preview Brave Beta. `nightly` is
  also supported.
- `-r <profile-root>`: use a custom Brave profile root when auto-detection does not find it.

To save an export, use `uvx dotbrave export -o <path>`. Review it before copying keys into
`brave.toml`: exports can contain machine-specific or private values. `uvx dotbrave export --help`
and `uvx dotbrave apply --help` show the complete options.

The file currently has no active `[shortcuts]` table because you have no custom key bindings. It
includes a commented cross-platform example. Leave the table absent until you want to manage
shortcuts; an empty table clears previously managed shortcuts in `dotbrave`.

## Stow and Dotter

Run `dotbrave` directly after installing Brave and Fira Code on a machine. Do not add this TOML to
the global Stow or Dotter profiles: those tools create file links and do not apply Brave
preferences. The `brave/` directory is excluded from the Stow package list for that reason.

## Everyday tips

### Search bangs and operators

With Brave Search as the default search engine, type a **bang** in the address bar to search another
site directly. Bangs also work on [Brave Search](https://search.brave.com/help/bangs) itself.

| Example               | Searches       |
| --------------------- | -------------- |
| `!gh dotbrave`        | GitHub         |
| `!so bash arrays`     | Stack Overflow |
| `!w Fira Code`        | Wikipedia      |
| `!yt zellij tutorial` | YouTube        |
| `!g brave shortcuts`  | Google         |

Browse the [bang directory](https://search.brave.com/bangs) for more. For a focused Brave Search
query, try `site:brave.com vertical tabs`, `filetype:pdf keyboard shortcuts`, or quotes around an
exact phrase; see the [search operator reference](https://search.brave.com/help/operators).

For a site you search often, add a **site-search shortcut** under **Settings → Search engine →
Manage search engines**. Give it a keyword such as `:docs` and a search URL with `%s` where the
query goes; then type the keyword, press Space or Tab, and enter your query. See
[Brave's site-search guide](https://support.brave.app/hc/en-us/articles/360017479752-How-do-I-set-my-default-search-engine).

For research, use [Brave Search Goggles](https://search.brave.com/help/goggles) to apply a community
ranking filter or write your own rules for which sources appear higher in results. Open **Goggles**
from a Brave Search results page to explore available filters.

### Handy keyboard shortcuts

| Action                        | Windows / Linux  | macOS                  |
| ----------------------------- | ---------------- | ---------------------- |
| Focus the address bar         | `Ctrl+L`         | `⌘+L`                  |
| Reopen the last closed tab    | `Ctrl+Shift+T`   | `⌘+Shift+T`            |
| Move to the next tab          | `Ctrl+Tab`       | `⌘+Option+Right Arrow` |
| Move to the previous tab      | `Ctrl+Shift+Tab` | `⌘+Option+Left Arrow`  |
| Find text on the current page | `Ctrl+F`         | `⌘+F`                  |
| Bookmark the current page     | `Ctrl+D`         | `⌘+D`                  |
| Bookmark all open tabs        | `Ctrl+Shift+D`   | `⌘+Shift+D`            |

See
[Brave's full shortcut list](https://support.brave.app/hc/en-us/articles/360032272171-What-keyboard-shortcuts-can-I-use-in-Brave).
Customize bindings at `brave://settings/system/shortcuts` if one conflicts with another app.

### Tab and session tools

- **Vertical tabs:** This config enables them and starts with the tab panel collapsed. Hover over
  the panel to see tab titles; use the Minimize Tabs button to collapse it again. See
  [Brave's vertical tabs guide](https://brave.com/whats-new/hide-vertical-tabs/).
- **Tab search:** Use the tab search button to find an open tab by title when the vertical list gets
  long. This config pins the button to the tab strip.
- **Tab groups:** Right-click a tab to add it to a named, color-coded group; collapse groups to keep
  a large vertical tab list manageable. To save a research session as bookmarks, use the **Bookmark
  all open tabs** shortcut above, which creates a folder. See
  [Brave's vertical tabs guide](https://brave.com/blog/vertical-tabs/).
- **Split View:** Right-click a tab and choose **New Split View** to put two tabs side by side, for
  example documentation next to a working page. Drag the divider to resize them. See
  [Brave's Split View guide](https://support.brave.app/hc/en-us/articles/35087087593997-How-do-I-use-Split-view-in-Brave).
- **Containers:** Right-click a tab, then choose **Open in Container** to use separate site sessions
  in one window, such as work and personal accounts. Manage containers under **Settings → Content →
  Containers**. See
  [Brave's Containers guide](https://support.brave.app/hc/en-us/articles/39077103885325-How-do-I-use-Containers-in-Brave).

### Reading and web apps

- **Speedreader:** On a supported article, click the reader icon in the address bar for a simpler
  layout. Its controls can make this the default for that site. See
  [Brave's Speedreader guide](https://support.brave.app/hc/en-us/articles/360045031392-What-is-Speedreader).
- **Web apps:** Use the Install icon in the address bar on a supported site to give it a separate
  app window and launcher shortcut. Manage installed sites at `brave://apps`. These windows are not
  always-on-top floating tabs. See
  [Brave's web app guide](https://support.brave.app/hc/en-us/articles/39077114659597-How-do-I-install-and-use-Web-Apps-in-Brave).
