# Product Hunt launch assets

Updated: 2026-08-03 · Status: **draft / pre-release**

These files are review-ready, but they are not approved for public launch.
The stable-release gate must first provide a Developer ID-signed and
Apple-notarized release candidate. The checked-in screenshots are controlled
DEBUG fixtures from the real SideRefresh workspace, not release-binary
evidence. Replace every public-facing fixture with a capture of that candidate
before removing the visible draft label.

## Asset set

| File | Size | Status | Purpose |
| --- | ---: | --- | --- |
| [Thumbnail](thumbnail-240.png) | 240×240 | Reusable | Product Hunt thumbnail; derived from the canonical app icon. |
| [Gallery 01](gallery/01-agent-builds.png) | 1270×760 | Draft | Core outcome and audience. |
| [Gallery 02](gallery/02-expiration-cycle.png) | 1270×760 | Draft | Personal Team expiration problem. |
| [Gallery 03](gallery/03-simple-workspace.png) | 1270×760 | Draft | English Simple workspace sample fixture. |
| [Gallery 04](gallery/04-xcode-flow.png) | 1270×760 | Draft | Supported Apple-tooling flow. |
| [Gallery 05](gallery/05-local-and-private.png) | 1270×760 | Draft | Local-source and credential boundary. |
| [Gallery 06](gallery/06-open-source.png) | 1270×760 | Draft | Open-source trust and release gate. |
| [Social preview](social-preview-1280x640.png) | 1280×640 | Draft | GitHub repository social preview. |
| [Public-site social preview](social-preview-public-1280x640.png) | 1280×640 | Reusable | Restrained website link preview with the renewal evidence rail. |
| [Video thumbnail](demo/youtube-thumbnail-1280x720.png) | 1280×720 | Draft | YouTube demo thumbnail. |

The six safe English UI captures are in [screenshots/en](screenshots/en). They
mirror the checked-in `Examples/SideRefreshSampleApp` metadata using DEBUG
fixture data, not the maintainer's app, device, account, paths, network, or
signing records. Alt text is in [alt-text.md](alt-text.md), and the
machine-readable inventory is [manifest.json](manifest.json).

## Reproduce

Tested on macOS 26.6 with Apple Swift 6.3.3, Playwright 1.62.1 plus Chromium,
ImageMagick 7.1.2-13, Tesseract 5.5.1, FFmpeg 8.0, jq 1.8.1, and ripgrep
15.2.0. Draft capture/render needs Swift, Playwright/Chromium, ImageMagick,
`sips`, jq, and ripgrep. Final validation additionally requires Tesseract;
demo export requires FFmpeg and ffprobe.

On a clean Mac, install the command-line dependencies and the pinned browser:

```sh
brew install imagemagick jq ripgrep tesseract ffmpeg
npm --prefix docs/product-hunt/assets/source ci
npx --prefix docs/product-hunt/assets/source playwright install chromium
```

Capture must run inside a logged-in macOS graphical session because AppKit
creates the fixture window. CI only validates checked-in outputs; it does not
attempt to open a window or regenerate captures.

```sh
Scripts/capture-product-hunt-ui.sh
Scripts/render-product-hunt-assets.sh
Scripts/validate-product-hunt-assets.sh
```

To inspect the same safe Sample-app fixture interactively, run
`Scripts/capture-product-hunt-ui.sh --preview` and quit it with Command-Q.
Preview mode adds a persistent **Sample Preview** notice, and its My App,
Settings, Help, and Diagnostics sidebar pages use synthetic, read-only data.
The automated draft captures stay on My App and omit that review-only notice.
Neither mode is release evidence or part of the Release binary.

The validator detects common private-data formats. For a final local check
against known values without committing them, add a case-insensitive regular
expression only for that command:

```sh
SIDEREFRESH_PRIVATE_SCAN_PATTERN='private-value-1|private-value-2' \
  Scripts/validate-product-hunt-assets.sh
```

`capture-product-hunt-ui.sh` is draft-only. For final media, follow the
[release-candidate capture checklist](final-capture-checklist.md), update the
manifest evidence and gates using the checked-in
`release-candidate-evidence.template.json`, then render without the draft badge using the
explicit attestation:

```sh
SIDEREFRESH_ASSET_STATUS=final \
SIDEREFRESH_FINAL_ASSET_ATTESTATION=signed-release-approved \
  Scripts/render-product-hunt-assets.sh
```

Never use final mode merely to make a draft look finished.

The capture script builds a temporary DEBUG app with a dedicated capture bundle
identifier and disabled state restoration, then has the app render its own
SwiftUI content. It does not require Screen Recording permission. Rendering
requires Playwright, Chromium, ImageMagick, and macOS `sips`.

Editable HTML/CSS/JavaScript lives in [source](source). The selected abstract
background and its exact generation record are documented in
[image-generation.md](source/image-generation.md). The canonical icon in
`Assets/Brand` remains the source of truth and was not replaced.

## Final release gate

- [ ] Public repository and stable release are available without login.
- [ ] The exact release is Developer ID signed and Apple notarized.
- [ ] One clean-account setup and one subsequent renewal are verified.
- [ ] Public UI media uses the exact release candidate and checked-in Sample app.
- [ ] Every claim matches the shipped behavior and current documentation.
- [ ] Assets are re-rendered with `SIDEREFRESH_ASSET_STATUS=final`.
- [ ] Dimensions, file sizes, English copy, and privacy scan pass again.
- [ ] Product Hunt's live form and official media requirements are rechecked.

Do not add Apple logos, Xcode icons, generated device hardware, Product Hunt
badges, private identifiers, or unsupported remote-installation claims.
