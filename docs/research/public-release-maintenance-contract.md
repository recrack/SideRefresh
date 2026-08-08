# Public release and maintenance contract

> Decision date: 2026-07-31
>
> Scope: SideRefresh's first credible public open-source release

This contract turns the existing open-source research into release gates. It
does not make the repository public, publish a release, buy an Apple Developer
Program membership, or promise unsupported product behavior.

## Decision

SideRefresh will use a two-stage public launch:

1. Publish the Apache-2.0-licensed repository and a source-build prerelease for Agent
   app makers who already have a Mac and Xcode.
2. Publish the first stable release only when a Developer ID-signed, notarized
   macOS binary and the Simple workspace acceptance evidence are ready.

The source prerelease may be public without a binary, but it must be marked as
a prerelease and must not instruct users to bypass Gatekeeper. Product Hunt and
other broad launch activity wait for the stable binary.

The stable channel is GitHub Releases. Homebrew, an in-app updater, the Mac App
Store, paid support, and a package registry are not first-release requirements.

## Historical repository audit

The following facts describe the private predecessor observed on 2026-07-31,
not the public-source snapshot:

| Area | Historical state |
| --- | --- |
| Visibility | Private predecessor; never the publication target |
| License | MIT `LICENSE`; GitHub recognizes SPDX `MIT` |
| Existing release | `v0.1.0`, titled `SideRenew v0.1.0`, source-only, no attached assets |
| Community files | `README.md`, `CONTRIBUTING.md`, and `SECURITY.md` exist |
| Missing community files | Code of Conduct, issue forms, pull-request template, and `SUPPORT.md` were absent |
| CI | Read-only `pull_request` workflow on `macos-15`; Swift, sample, and Headless validation |
| Dependencies | No external Swift package dependency |
| Binary build | Host architecture; ad-hoc signed unless a Developer ID identity is supplied |
| Distribution | Source build only; no signed/notarized public binary |
| Git history | Personal author metadata existed in the private development graph |
| Additional material | `.scratch` investigations and Actions logs existed in the private predecessor |

The public candidate resolves those findings by exporting only the reviewed
tree as one new root commit. It includes the community files and CI checks, and
copies no predecessor branches, tags, releases, Actions logs, or `.scratch`
material. The private predecessor remains a separate archive.

Changing visibility makes code, activity, and Actions history public and allows
anyone to fork the repository. GitHub explicitly calls out those consequences,
so visibility changes only after the history, logs, branches, tags, and tracked
research receive a human privacy review.
[GitHub: setting repository visibility](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility)

## License and contribution terms

### Project license

Beginning with `v0.2.0-beta.2`, use Apache License 2.0 with SPDX identifier
`Apache-2.0`. Keep the canonical license text unmodified and include the
project attribution in `NOTICE`.
[SPDX: Apache-2.0](https://spdx.org/licenses/Apache-2.0)

The release must include `LICENSE` and `NOTICE` in source and binary packages.
Source code and prose documentation use Apache-2.0. SideRefresh names and
visual assets follow `BRAND_POLICY.md` and `docs/ASSET-LICENSE.md`, which must
also accompany packages containing those assets.

The MIT terms attached to versions through `v0.2.0-beta.1` remain valid. Do not
move those tags or rewrite their historical license and release records.

Before public visibility:

- audit code, sample projects, icons, generated images, and copied snippets for
  provenance;
- confirm that the maintainer has the right to publish every tracked asset;
- record every bundled third-party component and its license;
- do not copy or bundle GPL/AGPL code into the Apache-2.0 distribution without an
  explicit compatibility and distribution review;
- add `THIRD_PARTY_NOTICES.md` when the first distributable third-party
  component is introduced.

SideRefresh currently has no external Swift package dependency, so an SBOM adds
little information to the first source prerelease. An SBOM becomes a release
requirement when the binary begins bundling third-party components. Build
provenance is required for the stable binary regardless.

### Inbound contributions

Use inbound-equals-outbound licensing: by contributing, a contributor licenses
the contribution under Apache-2.0, as `CONTRIBUTING.md` states.

Do not require a CLA or DCO for the first release. Either would add contributor
friction without a dual-licensing or multi-organization
governance requirement. Revisit only if that need becomes real.

Add Contributor Covenant 2.1 with a real maintainer enforcement contact.
[Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/)

## Publication and version sequence

Keep `v0.1.0` unchanged in the private archive. Do not copy or reuse that tag in
the clean public repository; its first release starts from the sequence below.

Use this sequence:

| Stage | Version | Channel |
| --- | --- | --- |
| Public source preview | `v0.2.0-beta.1` | GitHub prerelease; source build instructions |
| Additional preview fixes | `v0.2.0-beta.N` | GitHub prerelease |
| First stable public release | `v0.2.0` | Signed/notarized GitHub Release binary plus source |
| Compatible bug fix | `v0.2.Z` | Stable patch |
| New or intentionally breaking pre-1.0 behavior | `v0.Y.0` | Stable minor, with migration notes |

SemVer defines `0.y.z` as initial development where the public API is not yet
stable, and says released contents must not be modified. SideRefresh adopts
those rules while also documenting breaking CLI, MCP, configuration, and UI
workflow changes explicitly.
[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)

The tag uses the `v` prefix. `CFBundleShortVersionString` uses the corresponding
version without `v` or prerelease metadata for stable builds.
`CFBundleVersion` is a monotonically increasing integer and is never reused for
a distributed binary.

Continue the existing Keep a Changelog structure. Every release moves relevant
items out of `Unreleased` and identifies added, changed, deprecated, removed,
fixed, security, and known-limitation entries as applicable.
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/)

## Installation and distribution

### Source preview

The public prerelease provides:

- a pinned tag and GitHub-generated source archives;
- clone, test, build, open, and uninstall instructions;
- exact minimum build requirements;
- the exact macOS, Xcode, iOS, architecture, and connection combinations that
  were actually tested;
- a statement that the local app is ad-hoc signed and intended for source
  builders;
- no binary asset presented as a normal consumer download.

GitHub releases are tag-based and automatically expose source ZIP and TAR
archives.
[GitHub: about releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)

### Stable binary

The stable release provides:

- `SideRefresh-v0.2.0-universal-macos.zip`;
- `SHA256SUMS`;
- `LICENSE`;
- `NOTICE` and the applicable brand policy;
- release notes and a link to the full changelog;
- installation, update, and complete-uninstall instructions;
- a compatibility table and known limitations;
- a build provenance attestation.

If universal output is not technically validated, architecture-specific assets
may replace it, but their filenames and compatibility table must say `arm64` or
`x86_64` explicitly. A host-architecture binary must never be labelled
universal.

Apple's supported path for software downloaded outside the Mac App Store is a
Developer ID certificate plus notarization. Notarization also requires valid
signatures for distributed executables, hardened runtime, and a secure
timestamp.
[Apple: Developer ID](https://developer.apple.com/support/developer-id/)
[Apple: notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

Therefore the stable binary gate requires:

1. Apple Developer Program membership and a Developer ID Application
   certificate.
2. Developer ID signing of the embedded Agent, iOS helper, and outer app.
3. Hardened runtime and secure timestamps.
4. `notarytool` acceptance, stapling, and stapler validation.
5. `codesign --verify` and Gatekeeper `spctl` assessment.
6. Download and first launch from a clean macOS account.
7. Background Agent approval, Setup check, and a real supported-device renewal
   on the final archive.

The Apple Developer Program currently costs USD 99 per membership year in
eligible regions. This fee is paid by the SideRefresh binary distributor; users
still use their free Xcode Personal Team for their own iOS apps.
[Apple Developer Program membership](https://developer.apple.com/programs/whats-included/)

If the Developer ID gate is unavailable, stay on the source prerelease. Do not
publish an ad-hoc binary as stable and do not document quarantine removal or
Gatekeeper disabling as installation steps.

### Release integrity

Enable immutable releases before publishing new public releases. Build a draft,
attach every asset and checksum, verify them, and publish once. GitHub immutable
releases prevent tag movement and asset replacement and generate a release
attestation.
[GitHub: immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)

When the binary is built in GitHub Actions, generate an artifact attestation so
users can connect the archive to its workflow and source revision.
[GitHub: artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations)

Do not publish secrets to pull-request jobs. The signing/notarization job runs
only for a protected release tag or manually approved release environment.
Third-party actions are pinned to full commit SHAs and token permissions remain
least-privilege.
[GitHub Actions secure use](https://docs.github.com/en/actions/reference/security/secure-use)

## Community and governance

Before public visibility, add:

- `CODE_OF_CONDUCT.md`;
- `.github/ISSUE_TEMPLATE/bug.yml`;
- `.github/ISSUE_TEMPLATE/compatibility.yml`;
- `.github/ISSUE_TEMPLATE/feature.yml`;
- `.github/ISSUE_TEMPLATE/config.yml`;
- `.github/PULL_REQUEST_TEMPLATE.md`;
- `SUPPORT.md`.

GitHub's community profile uses these files to signal that a public project is
prepared for use and contribution. Templates standardize the information
contributors provide, and a Support file routes help away from unsuitable issue
types.
[GitHub: community profiles](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)
[GitHub: issue and PR templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
[GitHub: support resources](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/adding-support-resources-to-your-project)

Issue forms request:

- SideRefresh version and installation channel;
- macOS, Xcode, and iOS versions;
- project or workspace;
- USB, local-network, Tailnet, or custom-address path;
- Setup check, manual renewal, or background renewal;
- failed phase and redacted diagnostic output;
- last known working version.

Every log field warns users not to post Apple Account details, Team ID, UDID,
Tailnet address, local paths, provisioning profiles, certificates, or project
source. Sensitive reports go through private vulnerability reporting.

Enable GitHub Discussions for user questions and setup help. Issues remain for
reproducible defects, confirmed compatibility regressions, scoped enhancements,
and release work.

The maintainer owns releases and security decisions initially. A separate
governance document becomes necessary only when another person receives merge,
release, or security authority.

## Security reporting and repository controls

Keep `SECURITY.md`, update its supported-version table for every stable release,
and enable GitHub private vulnerability reporting immediately after the
repository becomes public. GitHub then provides a private structured reporting
path without requiring a public issue.
[GitHub: private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository)

Security response targets are operational goals, not paid-service SLAs:

- acknowledge a report within 48 hours;
- confirm scope or request information within seven days;
- coordinate disclosure and remediation privately;
- publish an advisory and fixed release when users must act;
- never request real Apple credentials, signing keys, or an unredacted device
  profile as reproduction data.

Before publishing the clean snapshot:

- ensure no predecessor branch, tag, commit, Actions log, or release is copied;
- create the root commit with public-safe author metadata;
- exclude `.scratch` material from the exported tree;
- remove or rotate every credential found before exposure;
- inspect the repository from a clean clone.

After publishing the snapshot:

- inspect GitHub's whole-history secret-scanning results;
- enable private vulnerability reporting;
- enable CodeQL default setup for Swift and inspect its first successful result;
- enable available push protection;
- protect the default branch with pull requests, required CI, resolved
  conversations, deletion protection, and no force pushes;
- keep Actions read-only by default.

GitHub scans the full history of public repositories for supported secret
patterns, but that is a post-publication defense, not permission to skip the
pre-public audit.
[GitHub: secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)
[GitHub: CodeQL default setup](https://docs.github.com/en/code-security/how-tos/find-and-fix-code-vulnerabilities/configure-code-scanning/configure-code-scanning)

## Support and compatibility

SideRefresh is a community-supported developer tool with no uptime, response,
or device-compatibility SLA.

For the pre-1.0 period:

- security fixes target the latest stable release;
- normal bug fixes target the latest stable release;
- prereleases receive best-effort support;
- old releases remain downloadable but are not maintained unless a security
  advisory says otherwise.

Each release distinguishes:

- minimum build/runtime requirements;
- combinations verified by CI;
- combinations verified on a real iPhone;
- experimental paths;
- unsupported paths.

Do not claim a broad `macOS 13+`, `Xcode 16.2+`, or iOS range merely because the
code compiles. Publish exact tested combinations and expand the compatibility
claim only when the matrix has evidence.

The first stable product support boundary remains:

- one Agent-made personal app;
- one paired iPhone;
- a Mac with Xcode and an existing Personal Team;
- first installation over USB;
- automatic renewal over USB or a verified local-network CoreDevice path.

Pure cellular mode, the CoreDevice/Tailnet bridge, and any unverified direct-IP
path are experimental. Third-party IPA installation, multiple apps or iPhones,
Xcode-free use, team fleet management, Apple Account collection, and signing
bypass remain unsupported.

## Public release gates

### Repository-public gate

- [ ] The public repository has exactly one reviewed root commit and no copied
      predecessor tags, releases, Actions logs, or pull-request refs.
- [ ] The exported tree passes secret, identifier, path, and privacy scans.
- [ ] Asset and dependency licensing audit is recorded.
- [ ] SideRefresh naming and identifiers are consistent; the private archive's
      `v0.1.0` is not copied or reused.
- [ ] README states the Personal Team limitation, user requirements, privacy
      boundary, supported scope, and unsupported IPA/distribution models.
- [ ] Code of Conduct, issue forms, PR template, Support, Contributing, Security,
      License, and Changelog are present.
- [ ] Pull-request CI matches the documented contributor checks.

### Source-prerelease gate

- [ ] `v0.2.0-beta.1` is built and tested from a clean clone.
- [ ] Simple workspace acceptance status and Legacy fallback are described
      accurately.
- [ ] Source build, uninstall, support, compatibility, and security-reporting
      instructions are linked from the release.
- [ ] Release is marked prerelease and source-only.

### Stable-binary gate

- [ ] Simple is the default workspace and all applicable migration acceptance
      gates pass.
- [ ] Universal or architecture-labelled binaries are validated.
- [ ] Developer ID, hardened runtime, timestamp, notarization, stapling,
      signature, and Gatekeeper checks pass.
- [ ] Clean-account download, launch, Setup check, background approval, and
      real-device renewal pass on the final archive.
- [ ] Immutable draft contains archive, checksum, license, notes, compatibility,
      limitations, and provenance before publication.
- [ ] No unresolved release-blocking security, privacy, installation, renewal,
      or Legacy-only issue remains.

## Explicitly deferred

- Homebrew Cask until a stable notarized archive and upgrade process exist;
- an in-app updater until signing, rollback, and update security are designed;
- a Mac App Store build;
- package-manager publication of `SideRefreshCore`;
- telemetry beyond GitHub's aggregate repository and release statistics;
- a CLA, DCO, formal multi-maintainer governance, sponsorship, and paid support;
- a mandatory SBOM while no third-party component is distributed.
