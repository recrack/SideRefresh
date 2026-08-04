# SideRefresh public-readiness audit

Audited: 2026-08-03

## Verdict

| Gate | Verdict | Reason |
| --- | --- | --- |
| Source publication | **GO through clean snapshot** | Publish only the reviewed tree as a new root commit; never expose the private development graph. |
| Legal and license | **READY** | Project code and project-created assets are covered by the root MIT license and asset notice. |
| Signed binary release | **NO-GO** | No Developer ID-signed, notarized, stapled archive and checksum are public yet. |
| Product Hunt launch | **NO-GO** | The trusted download and exact-release media remain outstanding. |

## Source-publication contract

The original development repository contains personal commit metadata and
historical device/app identifiers. Deleting files at its tip cannot make that
history safe. It therefore remains a separate private archive.

The public repository is created from a reviewed tree export with these
properties:

- one root commit authored and committed with the maintainer's GitHub noreply
  address;
- no copied branches, tags, pull-request refs, releases, Actions logs, or
  reflogs;
- community, support, security, contribution, and license files present;
- dependency actions pinned to reviewed full commit SHAs;
- automated checks for personal paths, emails, device IDs, Tailnet names,
  private Bundle IDs, and links to the private tracker; and
- secret scanning, push protection, private vulnerability reporting, and
  default-branch rules enabled on GitHub.

This avoids publishing the unsafe graph rather than claiming that historical
data was erased everywhere. See GitHub's guidance on
[repository visibility](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility)
and [sensitive-data removal](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository).

## Legal and asset boundary

The root MIT license covers project source and project-created visual assets as
recorded in [the asset notice](../ASSET-LICENSE.md). SwiftPM declares no runtime
third-party package dependency. Marketing build tools and downloaded browser
artifacts retain their upstream licenses and are not bundled.

Apple and Tailscale names and trademarks remain their owners' property. This
audit records repository readiness, not legal advice.

## Remaining release gates

Before offering a public Mac download:

1. Sign with Developer ID Application, hardened runtime, and secure timestamp.
2. Notarize, staple, archive, and publish SHA-256 provenance.
3. Verify Gatekeeper and first launch on a clean macOS account.
4. Verify one real installation and one subsequent renewal for the declared
   one-app × one-iPhone scope.
5. Replace DEBUG fixture media with captures from that exact release candidate.

Apple's official references are [Developer ID](https://developer.apple.com/help/glossary/developer-id-certificate/)
and [notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

[GitHub Pages](https://recrack.github.io/SideRefresh/) now explains the public
source without presenting an unavailable download. Product Hunt scheduling and
the download CTA stay disabled until these release and media gates pass.
