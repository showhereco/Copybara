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
- On macOS 27.0 through the releases before 27.2, `NSStatusItem.view` hosts the drop target and icon, with item target/action support for activation.
- On earlier versions and on macOS 27.2 or later, `NSStatusItem.button` hosts the `DropTargetView` overlay for file and text drops.
- On macOS 27 releases before 27.2, a primary click opens the drop popover. On other releases, it opens the menu. Right-clicking always opens the menu, and **Show Drop Area...** opens the popover from that menu.
- MacGeneration observed that file drops onto menu bar icons worked again without triggering Mission Control on macOS 27.2, which Apple released on 26 October 2026. [MacGeneration’s test](https://www.macg.co/macos/2026/11/macos-272-remet-mission-control-daplomb-312105) · [Apple’s release date](https://support.apple.com/en-us/149521)
- The animated `NSPopover` is anchored beneath the status item. Its Settings gear opens the options and recent-links menu beneath the button without closing the popover.
- The popover accepts the same drops without reaching the screen's top edge. Its application-defined behavior keeps it open when Finder becomes active, and it closes after a drop, Escape, another icon click, or the close button.
- Dropping a Dropbox file copies a local URL, defaulting to `copybara://relative/path`.
- The Finder service adds **Copy Link with Copybara** for Dropbox items.
- The app opens `copybara:` links in Finder or the default app.
- `dropifier:` links are supported for backward compatibility.
- Dropbox root discovery reads `~/.dropbox/info.json`; users can also choose a folder manually.
- Dropbox web URL lookup uses a literal Spotlight `kMDItemFSName` query.
- Login item state uses `SMAppService.mainApp.status` as the source of truth.
- App icon source and output are `Resources/AppIcon.svg` and `Resources/AppIcon.icns`.
