# SideRefresh Product Hunt playbook

Updated: 2026-08-03

This folder is the operating manual for registering and promoting SideRefresh
on Product Hunt. Operational copy is kept in English because every Product Hunt
submission must be English; the official-source research is maintained in
Korean for the project owner.

## Current decision

**Do not schedule the launch yet.** The launch remains blocked by the verified
stable-release gate. The source repository is published from a sanitized,
single-commit snapshot, but there is no Developer ID-signed and
Apple-notarized stable Mac download.

The static public product site now uses [`docs/index.html`](../index.html) for
English, with complete [Korean](../ko/index.html),
[Japanese](../ja/index.html), and [Simplified Chinese](../zh-cn/index.html)
explanation pages. The macOS app interface itself remains English and Korean.
GitHub Pages must remain disabled. The
[public-readiness audit](public-readiness-audit.md) explains why private
development history is kept in a separate archive. Complete the signed-release
gate before publishing the page or activating its download CTA.

Product Hunt registration itself does not require Developer ID. SideRefresh
requires a trusted binary as a product decision: asking someone to bypass
Gatekeeper before giving an app access to Xcode projects and an iPhone would
undermine first-run trust.

## Launch contract

The first launch makes one narrow promise:

> Keep agent-built iOS apps alive on your iPhone.

The explanation immediately below it must say that SideRefresh rebuilds,
signs, and reinstalls one user-owned app through Xcode Personal Team before
signing expires. It must also disclose that a Mac, Xcode, an Apple Account,
initial pairing, trust, and Developer Mode are required.

Do not present SideRefresh as an IPA store, an Apple-signing bypass, a permanent
profile, a fleet manager, or a verified pure-cellular installer. Tailscale is
experimental and is not the launch headline.

## Document map

| Document | Use |
| --- | --- |
| [Submission kit](submission.md) | Use the approved English listing fields, gallery story, demo plan, human-written first-comment outline, and FAQ in the Product Hunt draft. |
| [Launch assets](assets/README.md) | Review the generated thumbnail, six gallery images, social preview, safe English UI captures, editable sources, and final-release gates. |
| [Copy package](copy/listing.md) | Paste the exact listing fields and prepare bilingual press, support, outreach, announcements, and the human-only maker worksheet. |
| [Demo package](demo/README.md) | Record and export the 60-second walkthrough with captions, narration, privacy checks, thumbnail, and YouTube metadata. |
| [Promotion runbook](promotion-runbook.md) | Prepare real users, announce ethically, operate launch day, answer comments, measure results, and stop promotion safely when needed. |
| [Official-source research](research.md) | Recheck Product Hunt rules and distinguish official requirements from SideRefresh strategy. |
| [Public-readiness audit](public-readiness-audit.md) | Resolve source, license, signed-binary, and Product Hunt publication gates without exposing private values. |
| [Comparable macOS launches](../research/product-hunt-macos-comparable-launches.md) | Understand the observed patterns behind the positioning and release-quality decisions. |

The bilingual launch-copy references remain available in
[English](../PRODUCT-HUNT.md) and [Korean](../PRODUCT-HUNT.ko.md). This folder is
the operational source of truth, and the submission kit owns the current draft
fields.

## What tends to work

These are SideRefresh launch hypotheses, not promises from Product Hunt:

1. **Lead with the result.** “Keep … alive” is easier to understand than
   CoreDevice, provisioning, or background-agent internals.
2. **Offer a product that works now.** A public repository plus a verified,
   signed, notarized download lets visitors try the claim immediately.
3. **Remove trust objections early.** State what stays local, that SideRefresh
   never receives the Apple Account password, and that it uses Apple’s normal
   Xcode flow.
4. **Tell one visual story.** Problem → agent-built project → SideRefresh →
   iPhone → verified renewal is stronger than a gallery of unrelated settings.
5. **Bring genuine first users, not votes.** A small opt-in beta group that has
   already installed the app can ask useful questions and report real failures.
6. **Make the maker visible.** A clear first comment, quick factual replies,
   honest limitations, and public fixes create more trust than launch slogans.
7. **Measure activation.** Independent successful setups and actionable
   feedback matter more than the daily rank alone.

The official basis is Product Hunt’s current emphasis on live products and the
`Useful`, `Novel`, `High Craft`, and `Creative` featuring signals, plus its
warning that no launch-day tactic guarantees ranking. See the
[Featuring Guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines)
and [launch preparation guide](https://www.producthunt.com/launch/preparing-for-launch).

Product Hunt prohibits AI-generated comments. As a conservative SideRefresh
operating rule, the maker writes the first comment and replies personally; do
not auto-post or auto-reply.

The current visual package is deliberately marked `DRAFT · PRE-RELEASE` until
the signed and notarized release gate passes. It is complete enough for factual
and visual review, not for public submission.

## Go / No-Go

Schedule only when every product gate is checked:

- [x] Public source is isolated in a sanitized, single-commit snapshot; private
  development history is not reachable from it.
- [ ] The repository name, description, topics, social preview, README, and
  release all consistently say `SideRefresh`.
- [ ] GitHub Pages serves the reviewed `master /docs` source only after the
  signed-release gate passes, with the exact immutable download link.
- [ ] A stable Developer ID-signed and Apple-notarized download is public.
- [ ] A fresh public download passes checksum, provenance, Gatekeeper, launch,
  version, and clean-account checks.
- [ ] At least one independent user completes first setup from the public docs.
- [ ] A real first installation and subsequent Verified renewal pass for the
  declared one-app × one-iPhone scope.
- [ ] English and Korean app UI, all four product-page translations, privacy
  boundary, support route, and uninstall instructions match the shipped artifact.
- [ ] Listing copy, thumbnail, gallery, demo, maker profile, and first comment
  have received a final factual review.
- [ ] The maker can support the launch for the first Product Hunt day.
- [ ] The live Product Hunt submission UI and current official rules have been
  rechecked immediately before scheduling.

If a download, Gatekeeper, security, privacy, or core setup check fails, pause
promotion and fix the release before resuming. Do not preserve a launch date at
the cost of a broken first experience.

## Success definition

Use three layers of evidence:

| Priority | Evidence | Why it matters |
| --- | --- | --- |
| Primary | Independent first setup and Verified renewal reports | Proves that the product promise works outside the maker’s Mac. |
| Primary | Specific questions, reproducible bugs, and setup drop-off points | Improves the next release and documentation. |
| Secondary | GitHub release downloads, unique visitors/clones, stars, and contributors | Shows reach and continuing open-source interest. |
| Context only | Product Hunt points and daily rank | Useful visibility signal, but not a product outcome or guaranteed by any tactic. |

SideRefresh does not add hidden telemetry for launch measurement. Prefer public
GitHub data, Product Hunt analytics available to the maker, support reports,
and an explicit opt-in feedback form.
