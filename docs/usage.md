# Using Copybara

Copybara turns files inside your local Dropbox folder into links that open the same synced file on another Mac.

## Requirements

- macOS 15.0 or newer.
- Dropbox installed and syncing files locally.
- Copybara installed on every Mac that should open `copybara:` links.

Copybara links are local path links. They work best when everyone has access to the same Dropbox content, even if their Dropbox folder is in a different place on disk.

## Copy a Link

There are three ways to copy a Copybara link:

1. Drag a file or folder from Dropbox onto the Copybara icon in the menu bar.
2. Right-click a Dropbox item in Finder and choose **Copy Link with Copybara**.
3. Click the Copybara icon to expand its drop area, then drag a Dropbox file or folder onto it.

Copybara writes a `copybara:` link to the clipboard and keeps recent copied links in the menu for quick reuse.

## Open a Link

Open a `copybara:` link from any app that recognizes clickable links. Copybara locates the item inside your configured Dropbox folder, then opens it with the default macOS app.

If **Open enclosing folder only** is enabled in the Copybara menu, links reveal the item in Finder instead of opening the file directly.

If the linked item is missing from your Mac, Copybara shows **This item isn’t available on this Mac** with its Dropbox-relative path. The item may be excluded from sync, moved, or deleted. Use **Copy folder path** to copy the enclosing folder’s local path, or enable the folder in Dropbox Preferences → Sync and click **Retry**. **Cancel** dismisses the popup. This also applies to legacy `dropifier:` links, and the popup appears even when notifications are disabled.

## Dropbox Web Links

You can drag a Dropbox web link onto the Copybara menu bar icon. Copybara searches your configured Dropbox folder for a local file with the same name and opens the first match.

The attached drop area also accepts Dropbox web links.

This uses Spotlight, so results depend on the local Spotlight index and may be ambiguous if multiple files share the same name.

## Menu Options

Click the Settings gear in the drop area to open the options menu, including recent links. You can also right-click the Copybara icon for the same menu.

- **Show Drop Area...** opens a drop target attached beneath the Copybara icon. It stays open while you switch to Finder and closes after a drop. Use Escape, the close button, or click the icon again to dismiss it.
- **Dropbox:** shows the currently configured Dropbox folder.
- **Change Dropbox Folder...** chooses a different Dropbox folder.
- **Copied URL scheme** switches between `copybara:` and legacy `dropifier:` links.
- **Open enclosing folder only** reveals linked items in Finder instead of opening them.
- **Show notifications** controls Copybara notifications.
- **Launch at login** starts Copybara automatically when you sign in.
- **Copy recent item** copies a recently generated link again.
- **Check for Updates...** checks for a newer Copybara version.
- **Quit** closes Copybara.

## Troubleshooting

If macOS 27 opens Mission Control when you drag toward the menu bar, click the Copybara icon before starting the drag and drop onto the area that expands beneath it. You can also use **Copy Link with Copybara** in Finder.

If Copybara says your Dropbox folder is not set, open the menu and choose **Change Dropbox Folder...**.

If a file cannot be linked, make sure the selected item is inside the configured Dropbox folder.

If a link does not open on another Mac, confirm that Copybara is installed there and that the target file exists in that person's synced Dropbox folder.

If a Dropbox web link opens the wrong local file, use Finder to copy a Copybara link from the exact item instead.
