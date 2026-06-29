# Development

Copybara is a native macOS menu bar app built with Swift and AppKit. It has no package dependencies.

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

## Implementation Notes

- `LSUIElement` menu bar app.
- App identifier: `co.showhere.copybara`.
- `NSStatusItem.button` hosts a `DropTargetView` overlay for file and text drops.
- Dropping a Dropbox file copies a local URL, defaulting to `copybara:///relative/path`.
- The Finder service adds **Copy Link with Copybara** for Dropbox items.
- The app opens `copybara:` links in Finder or the default app.
- `dropifier:` links are supported for backward compatibility.
- Dropbox root discovery reads `~/.dropbox/info.json`; users can also choose a folder manually.
- Dropbox web URL lookup uses a literal Spotlight `kMDItemFSName` query.
- Login item state uses `SMAppService.mainApp.status` as the source of truth.
- App icon source and output are `Resources/AppIcon.svg` and `Resources/AppIcon.icns`.
