# Copybara

Copybara is a small macOS menu bar app for sharing Dropbox files as local links.

Drag a file from your Dropbox folder onto the Copybara menu bar icon, or use the Finder service, and Copybara copies a link like:

```text
copybara:///WORK/ACME/Deck-final v2 (DO NOT USE) copy.pdf
```

Opening that link on another Mac with Copybara installed opens the matching local Dropbox file, without sending the file through a public share URL.

> [!IMPORTANT]
> Copybara requires macOS 15.0 or newer.

## Why Use It

- Share links to files that already live in Dropbox.
- Keep links local to each person's synced Dropbox folder.
- Open Copybara links directly in Finder or the default app.
- Use the `dropifier:` scheme for older links when needed.
- Resolve Dropbox web links back to local files when Spotlight can find a match.

## Install

Download the latest macOS DMG from [GitHub Releases](https://github.com/showhereco/Copybara/releases), open it, and drag `Copybara.app` to `Applications`.

The app appears as a link icon in the macOS menu bar. On first launch, Copybara tries to find your Dropbox folder automatically. If it cannot, choose the folder from the Copybara menu.

## Basic Use

1. Make sure Dropbox is installed and syncing locally.
2. Open Copybara.
3. Drag a Dropbox file or folder onto the Copybara menu bar icon.
4. Paste the copied `copybara:` link wherever you want to share it.

You can also right-click a Dropbox item in Finder and choose **Copy Link with Copybara**.

See [Using Copybara](docs/usage.md) for menu options, link behavior, and troubleshooting.

## TODO

- Add Sparkle-based automatic updates.

## Links

- [Using Copybara](docs/usage.md)
- [Development](docs/development.md)
