# Development

Copybara is a native macOS menu bar app built with Swift and AppKit. It uses Sparkle for automatic updates.

## Requirements

- macOS 15.0 or newer.
- Xcode command line tools with Swift 6 support.

## Build

```sh
./scripts/package-app.sh
```

The packaged app is written to:

```text
.build/release/Copybara.app
```

## Run Locally

```sh
./scripts/run-app.sh
```

Local builds use ad-hoc signing by default.

Packaged builds are universal by default. For a faster native-only local build, override the architecture list:

```sh
SWIFT_BUILD_ARCHS="$(uname -m)" ./scripts/package-app.sh
```

## Release

The release version is tracked in `VERSION`. To publish a new release, update `VERSION`, commit the change, and push it to `main`.

The release workflow reads `VERSION`, builds and verifies the signed/notarized macOS DMG, signs that DMG for Sparkle, generates `appcast.xml`, then publishes the GitHub Release for that version.

Sparkle updates use the same GitHub Release DMG. To republish a deleted release for the current `VERSION`, run the release workflow manually from GitHub Actions.

## Implementation Notes

- `LSUIElement` menu bar app.
- App identifier: `co.showhere.copybara`.
- On macOS 27, `NSStatusItem.view` hosts the drop target and icon, with item target/action support for activation.
- On earlier versions, `NSStatusItem.button` hosts the existing `DropTargetView` overlay for file and text drops.
- Clicking the icon opens an animated `NSPopover` anchored beneath the status item. The popover's Settings gear opens the existing options and recent-links menu beneath the button without closing its anchor. Right-clicking the status item opens the same menu.
- The popover accepts the same drops without reaching the screen's top edge. Its application-defined behavior keeps it open when Finder becomes active, and it closes after a drop, Escape, another icon click, or the close button.
- Dropping a Dropbox file copies a local URL, defaulting to `copybara://relative/path`.
- The Finder service adds **Copy Link with Copybara** for Dropbox items.
- The app opens `copybara:` links in Finder or the default app.
- `dropifier:` links are supported for backward compatibility.
- Dropbox root discovery reads `~/.dropbox/info.json`; users can also choose a folder manually.
- Dropbox web URL lookup uses a literal Spotlight `kMDItemFSName` query.
- Login item state uses `SMAppService.mainApp.status` as the source of truth.
- App icon source and output are `Resources/AppIcon.svg` and `Resources/AppIcon.icns`.
