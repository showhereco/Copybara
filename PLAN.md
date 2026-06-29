# Copybara `0.1.0` CI Release Plan

## Goal
Publish Copybara `0.1.0` as a signed and notarized macOS DMG from GitHub Actions.

Release values:

| Item | Value |
| --- | --- |
| GitHub repository | `showhereco/Copybara` |
| Release version | `0.1.0` |
| GitHub tag/release | `v0.1.0` |
| App name | `Copybara` |
| Bundle identifier | `co.showhere.copybara` |
| Developer ID identity | `Developer ID Application: Showhere Limited (Z7BAN29RTJ)` |
| Expected DMG | `Copybara-0.1.0-macos.dmg` |
| Expected checksum | `Copybara-0.1.0-macos.dmg.sha256` |

## CI Release Requirements

A production CI release needs all of the following:

1. A **Developer ID Application** certificate for the Showhere Apple Developer team.
2. The certificate exported as a `.p12` including its private key.
3. The `.p12` export password.
4. An App Store Connect API **Team Key** for notarization.
5. The App Store Connect API Key ID.
6. The App Store Connect API Issuer ID.
7. GitHub repository secrets containing the private credential material.
8. Public workflow configuration for the exact signing identity name.
9. The release workflow run with `version=0.1.0`, or a pushed `v0.1.0` tag.

No release-candidate-specific handling is needed. The GitHub release/tag/artifact version and `CFBundleShortVersionString` can all use `0.1.0`.

## Local Apple Credential Checks

Verify the intended signing identity exists locally:

```sh
security find-identity -v -p codesigning
```

Expected relevant identity:

```text
Developer ID Application: Showhere Limited (Z7BAN29RTJ)
```

The `Apple Development: ...` identity is not used for the public DMG release.

## Export Developer ID Certificate

In Keychain Access:

1. Go to **My Certificates**.
2. Find `Developer ID Application: Showhere Limited (Z7BAN29RTJ)`.
3. Confirm it expands to show a private key.
4. Export the identity as a `.p12`.
5. Use a strong export password.
6. Store the `.p12` outside the repository.

Important: the exported `.p12` must include the private key, not just the public certificate.

## Create App Store Connect API Key

In App Store Connect:

1. Select the Showhere team.
2. Go to **Users and Access > Integrations > App Store Connect API**.
3. Generate a **Team Key** named `Copybara Notarization`.
4. Download the `.p8` immediately; Apple only allows one download.
5. Record:
   - Key ID
   - Issuer ID

The CI workflow uses `notarytool` with this key to notarize both the `.app` bundle and final `.dmg`.

## GitHub Repository Secrets

Use repository secrets on `showhereco/Copybara`.

Prepare local secret files:

```sh
REPO=showhereco/Copybara
SECRET_DIR=/tmp/copybara-release-secrets
mkdir -m 700 "$SECRET_DIR"

base64 -i /path/to/developer-id-application.p12 -o "$SECRET_DIR/cert.b64"
base64 -i /path/to/AuthKey_KEYID.p8 -o "$SECRET_DIR/notary-key.b64"
openssl rand -base64 32 > "$SECRET_DIR/keychain-password.txt"
```

Set GitHub secrets:

```sh
gh secret set DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64 --repo "$REPO" --body-file "$SECRET_DIR/cert.b64"
gh secret set DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD --repo "$REPO"
gh secret set DEVELOPER_ID_KEYCHAIN_PASSWORD --repo "$REPO" --body-file "$SECRET_DIR/keychain-password.txt"

gh secret set APP_STORE_CONNECT_API_KEY_BASE64 --repo "$REPO" --body-file "$SECRET_DIR/notary-key.b64"
gh secret set APP_STORE_CONNECT_KEY_ID --repo "$REPO"
gh secret set APP_STORE_CONNECT_ISSUER_ID --repo "$REPO"
```

Then verify secret names and remove temporary files:

```sh
gh secret list --repo "$REPO"
rm -rf "$SECRET_DIR"
```

Required secret names:

| Secret | Purpose |
| --- | --- |
| `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64` | Base64-encoded `.p12` Developer ID Application identity |
| `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `DEVELOPER_ID_KEYCHAIN_PASSWORD` | Temporary CI keychain password |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded App Store Connect `.p8` key |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect issuer ID for the Showhere team |

Public workflow configuration:

| Variable | Value |
| --- | --- |
| `CODESIGN_IDENTITY` | `Developer ID Application: Showhere Limited (Z7BAN29RTJ)` |

## GitHub Repository Settings

Confirm these repo settings before release:

- GitHub Actions is enabled for the repository.
- The release workflow has permission to write repository contents.
- `.github/workflows/release.yml` includes:
  - `permissions: contents: write`
  - manual `workflow_dispatch` input named `version`
  - tag trigger for `v*`

The current workflow is expected to:

1. Import the Developer ID `.p12` into a temporary keychain.
2. Set `SIGN_IDENTITY` from `CODESIGN_IDENTITY`.
3. Build `Copybara.app`.
4. Generate an `Info.plist` with bundle identifier `co.showhere.copybara`.
5. Sign the app with hardened runtime and timestamp.
6. Notarize and staple the app.
7. Build the DMG.
8. Sign the DMG.
9. Notarize and staple the DMG.
10. Verify the app and DMG with `codesign`, `spctl`, and `hdiutil`.
11. Generate a SHA-256 checksum.
12. Upload workflow artifacts.
13. Create GitHub release `v0.1.0` if it does not already exist.

## Preflight Local Validation

Before running the CI release, confirm the bundle identifier locally:

```sh
./scripts/package-app.sh
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" .build/release/Copybara.app/Contents/Info.plist
```

Expected output:

```text
co.showhere.copybara
```

Optional local Developer ID signing check:

```sh
SIGN_IDENTITY="Developer ID Application: Showhere Limited (Z7BAN29RTJ)" ./scripts/package-app.sh
codesign --verify --deep --strict --verbose=2 .build/release/Copybara.app
spctl --assess --type execute --verbose=4 .build/release/Copybara.app
```

Local notarization is optional because CI performs notarization using GitHub secrets.

## Release Run

After secrets and repo settings are ready, run the workflow manually:

```sh
gh workflow run release.yml --repo showhereco/Copybara -f version=0.1.0
gh run list --repo showhereco/Copybara --workflow release.yml --limit 1
gh run watch --repo showhereco/Copybara
```

Expected release assets:

```text
Copybara-0.1.0-macos.dmg
Copybara-0.1.0-macos.dmg.sha256
```

Alternative tag-driven release:

```sh
git tag v0.1.0
git push origin v0.1.0
```

Use only one release trigger path. Manual workflow dispatch is usually cleaner for the first signed release because it creates the tag only after the workflow reaches the publish step.

## Acceptance Checks

CI must show:

- Developer ID certificate imported successfully.
- `SIGN_IDENTITY` resolves to `Developer ID Application: Showhere Limited (Z7BAN29RTJ)`.
- App bundle identifier is `co.showhere.copybara`.
- App binary is universal: `x86_64 arm64`.
- App signing verification passes.
- App notarization and stapling pass.
- App Gatekeeper assessment passes.
- DMG creation succeeds.
- DMG signing verification passes.
- DMG notarization and stapling pass.
- DMG Gatekeeper assessment passes.
- GitHub Release `v0.1.0` is published.
- DMG and `.sha256` assets are attached to the release.

Manual smoke test:

1. Download `Copybara-0.1.0-macos.dmg` from GitHub Releases on a clean Mac.
2. Open the DMG.
3. Drag `Copybara.app` to Applications.
4. Launch the app.
5. Confirm Gatekeeper accepts it without warnings.
6. Test the menu bar app behavior and Dropbox link copy flow.

## If the Release Is Bad

If `v0.1.0` is created but should not remain public:

```sh
gh release delete v0.1.0 --repo showhereco/Copybara --cleanup-tag --yes
```

If anyone may already have downloaded it, prefer publishing a follow-up `0.1.1` instead of reusing `0.1.0`.

## Notes

- Developer ID distribution does not require an App Store provisioning profile.
- The App Store Connect key must belong to the same Apple team used for notarization access.
- Changing the bundle identifier changes the app's preferences domain. Existing local preferences from `com.dnco.copybara` will not automatically carry over to `co.showhere.copybara`.
- Keep `.p12`, `.p8`, passwords, and temporary base64 files out of the repository.
