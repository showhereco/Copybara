# Using Copybara

Copybara turns files inside your local Dropbox folder into links that open the same synced file on another Mac.

## Requirements

- macOS 15.0 or newer.
- Dropbox installed and syncing files locally.
- Copybara installed on every Mac that should open `copybara:` links.

Copybara links are local path links. They work best when everyone has access to the same Dropbox content, even if their Dropbox folder is in a different place on disk.

## Copy a Link

There are two ways to copy a Copybara link:

1. Drag a file or folder from Dropbox onto the Copybara icon in the menu bar.
2. Right-click a Dropbox item in Finder and choose **Copy Link with Copybara**.

Copybara writes a `copybara:` link to the clipboard and keeps recent copied links in the menu for quick reuse.

## Open a Link

Open a `copybara:` link from any app that recognizes clickable links. Copybara locates the item inside your configured Dropbox folder, then opens it with the default macOS app.

If **Open enclosing folder only** is enabled in the Copybara menu, links reveal the item in Finder instead of opening the file directly.

## Dropbox Web Links

You can drag a Dropbox web link onto the Copybara menu bar icon. Copybara searches your configured Dropbox folder for a local file with the same name and opens the first match.

This uses Spotlight, so results depend on the local Spotlight index and may be ambiguous if multiple files share the same name.

## Menu Options

- **Dropbox:** shows the currently configured Dropbox folder.
- **Change Dropbox Folder...** chooses a different Dropbox folder.
- **Copied URL scheme** switches between `copybara:` and legacy `dropifier:` links.
- **Open enclosing folder only** reveals linked items in Finder instead of opening them.
- **Show notifications** controls Copybara notifications.
- **Launch at login** starts Copybara automatically when you sign in.
- **Copy recent item** copies a recently generated link again.

## Troubleshooting

If Copybara says your Dropbox folder is not set, open the menu and choose **Change Dropbox Folder...**.

If a file cannot be linked, make sure the selected item is inside the configured Dropbox folder.

If a link does not open on another Mac, confirm that Copybara is installed there and that the target file exists in that person's synced Dropbox folder.

If a Dropbox web link opens the wrong local file, use Finder to copy a Copybara link from the exact item instead.
