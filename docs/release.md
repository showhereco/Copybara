# Release Process

Copybara releases are built by GitHub Actions from version tags or manual workflow dispatch.

## Publish a Version

```sh
git tag v0.1.0
git push origin v0.1.0
```

The release workflow builds `Copybara-<version>-macos.dmg`, attaches it to a GitHub Release, and uploads a `.sha256` checksum.

The workflow can also be run manually with a version input. If the matching tag does not already exist, the workflow creates and pushes it.

## Signing and Notarization

Without signing secrets, the workflow uses ad-hoc app signing and skips notarization. Production releases should use Developer ID signing and App Store Connect API key notarization.

For Developer ID signing and notarization under the Showhere Apple Developer team, configure these repository secrets:

- `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64`
- `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD`
- `DEVELOPER_ID_KEYCHAIN_PASSWORD`
- `APP_STORE_CONNECT_API_KEY_BASE64`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`

The signing identity name is public configuration in `.github/workflows/release.yml`, not a secret:

```yaml
CODESIGN_IDENTITY: "Developer ID Application: Showhere Limited (Z7BAN29RTJ)"
```

If a Developer ID certificate is present but App Store Connect API key secrets are incomplete, the workflow fails before publishing. This avoids releasing a signed but non-notarized production artifact.

The workflow notarizes and staples both the app bundle and the DMG. The final checksum is generated after DMG notarization and stapling.

## Local DMG

To package a local ad-hoc DMG manually:

```sh
./scripts/package-app.sh
./scripts/package-dmg.sh .build/release/Copybara.app 0.1.0 .build/artifacts
shasum -a 256 .build/artifacts/Copybara-0.1.0-macos.dmg > .build/artifacts/Copybara-0.1.0-macos.dmg.sha256
```

This creates a read-only compressed DMG containing `Copybara.app` and an `/Applications` symlink. Set `SIGN_IDENTITY` to `Developer ID Application: Showhere Limited (Z7BAN29RTJ)` to sign the local app and DMG.

## Future Updates

Sparkle is intentionally not included in v1. The DMG naming and monotonically increasing `CFBundleVersion` are stable so the same artifact shape can be used later for Sparkle appcasts. Sparkle EdDSA keys are separate from Apple Developer ID and notarization credentials.
