# ADR 0001: Apache-2.0 license and brand boundary

- Status: Accepted
- Date: 2026-08-08

## Context

SideRefresh is a public developer tool with a macOS app, CLI, background Agent,
MCP server, and reusable Swift core. It builds, signs, and installs user-owned
iOS projects, and it invites outside contributions. The public
`v0.2.0-beta.1` source was released under MIT with no external Swift package
dependencies.

The project needs explicit contributor patent terms and clearer attribution for
modified distributions. It also needs to distinguish open source from the
SideRefresh product identity so forks cannot appear to be official releases.

The public GitHub contributor record and the predecessor repository history
identify only `@recrack` or the SideRefresh maintainer as the source
contributor. `Package.swift` declares no external package dependencies, and no
separately licensed predecessor source is vendored. The maintainer authorized
this relicensing for the project-owned work; third-party materials retain their
own terms.

## Decision

Beginning with `v0.2.0-beta.2`:

- source code and prose documentation use Apache License 2.0;
- `NOTICE` carries project attribution and is distributed with the work;
- packaged app and Headless outputs include `LICENSE`, `NOTICE`, and the brand
  policy;
- the SideRefresh name and visual assets follow `BRAND_POLICY.md` and
  `docs/ASSET-LICENSE.md`; and
- contributions use the same Apache-2.0 terms as the project.

Versions through `v0.2.0-beta.1` remain under their original MIT terms. Their
tags, release notes, and historical records are not rewritten.

## Consequences

Apache-2.0 still permits commercial use, private modifications, and binary
distribution. It adds an explicit patent grant, requires preservation of
applicable notices, and requires changed files to identify modifications.

The license does not require forks to publish their source. Modified products
must replace SideRefresh names and visual identity except for truthful
attribution. User-owned iOS projects built by SideRefresh do not incorporate
SideRefresh code and are not relicensed by this decision.

Earlier research recommendations to keep MIT are historical and are superseded
for releases beginning with `v0.2.0-beta.2`.
