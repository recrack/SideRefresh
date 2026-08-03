# SideRefresh Product Hunt launch kit

[English](PRODUCT-HUNT.md) | [한국어](PRODUCT-HUNT.ko.md)

Updated: 2026-08-02

This is the English launch-copy reference and readiness checklist. Current draft
fields and the operational registration and promotion plan live in the
[Product Hunt playbook](product-hunt/README.md). Neither document means the
product has been submitted.

## Current decision: not ready to schedule

As of the update date:

- the source repository is ready through a sanitized, single-commit public
  snapshot;
- GitHub Pages intentionally has no public download yet;
- no Developer ID-signed and notarized stable Mac download is available; and
- Product Hunt scheduling remains gated by that stable release and final
  real-build media.

The bilingual app and documentation can support Product Hunt visitors, but the
listing should be scheduled only after every Go/No-Go item below is satisfied.

## Listing copy

Product name:

> SideRefresh

Tagline:

> Keep agent-built iOS apps alive on your iPhone

Short description:

> SideRefresh is an open-source Mac app that rebuilds, signs, and reinstalls agent-built iOS apps before free Personal Team signing expires. Personal use needs no paid Apple Developer Program membership; Mac, Xcode, and an Apple Account are required.

Suggested topics, subject to the exact options in the submission UI:

- Open Source
- Developer Tools
- Artificial Intelligence

Pricing:

> Free

Primary URL:

> https://github.com/recrack/SideRefresh

## Maker first comment

Product Hunt prohibits AI-generated comments. As a conservative SideRefresh
operating rule, the maker personally writes the product origin, exact workflow,
trust boundary, requirements, first-release scope, and one specific feedback
question. Do not paste generated prose or use automated posting or replies. Use
the human-writing checklist in the
[submission kit](product-hunt/submission.md#maker-first-comment-outline).

## One-line answers

Who is it for?

> People using Claude Code, Codex, Cursor, or Xcode to build personal iOS apps
> that are not intended for App Store distribution.

What does it automate?

> A local Xcode rebuild, Personal Team signing, Bundle ID validation,
> CoreDevice installation, and expiration evidence before the app expires.

Does it remove Apple's expiration?

> No. It repeats Apple's normal development build and installation path before
> expiration.

Is a paid developer membership required?

> Not for the user's personal iOS app. An Apple Account Personal Team is still
> required. Separately, the public SideRefresh Mac binary must be Developer ID
> signed and notarized by the distributor.

Does Tailscale make installation remote?

> Tailscale support is experimental. It checks peer identity and a remote
> address, but does not replace Xcode pairing or prove CoreDevice reachability.
> Pure-cellular installation is not yet a supported public claim.

## Gallery plan

Use 1270×760 images with English UI for the Product Hunt listing. Korean UI can
appear in the README and launch follow-up.

1. **Hero:** “Your agent builds it. SideRefresh keeps it running.”
2. **Problem:** Personal Team signing expires; the app must be rebuilt and
   installed again.
3. **Simple home:** one condition, one next action, app → iPhone, and last
   verified evidence.
4. **Same-window setup:** app and iPhone selection with a fixed confirmation
   footer.
5. **Connection:** Xcode/CoreDevice always visible; optional Tailscale clearly
   marked experimental.
6. **Open source:** local source, MIT license, GitHub, and the exact privacy
   boundary.

Recommended demo: 45–75 seconds showing an agent-built project, selection,
first verified installation, and the ready state. Do not simulate an unverified
remote installation.

## Honest first-release scope

Included:

- one user-owned app;
- one Xcode project or workspace;
- one paired physical iPhone;
- a Mac with Xcode and an Apple Account Personal Team;
- English and Korean Simple workspace, first-run Settings/selectors, an in-app
  language picker, and user documentation.

Excluded:

- third-party IPA installation;
- multiple apps or multiple iPhones at the same time;
- users without Xcode;
- team or fleet device management; and
- any claim that signing becomes permanent.

## Go/No-Go checklist

- [ ] Audit the full Git history, Actions logs, docs, and assets for secrets,
  personal paths, Apple Account data, signing material, UDIDs, and Tailnet IDs.
- [ ] Make the GitHub repository public and verify every public link.
- [ ] Add a repository description, homepage, topics, and social preview.
- [ ] Publish a stable Developer ID-signed and Apple-notarized Mac download.
- [ ] Publish the archive checksum and verify Gatekeeper on a clean account.
- [ ] Complete a fresh first installation and a second real refresh for one
  agent-built app on one iPhone.
- [ ] Verify the English and Korean Simple setup flow from the shipped bundle.
- [ ] Verify README, manuals, privacy boundary, support policy, and uninstall
  instructions against the release artifact.
- [ ] Prepare the thumbnail, gallery, public demo, maker profile, and support
  coverage for launch day.
- [ ] Confirm the final Product Hunt limits and field names in the live
  submission UI before scheduling.

Do not ask for upvotes or offer incentives in exchange for upvotes. Do not use
bots, purchased traffic, or bulk unsolicited messages. Ask people to try the
product and share genuine feedback.

Current Product Hunt policy research and source links are kept in the
[official-source research](product-hunt/research.md).
