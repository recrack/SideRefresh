# SideRefresh README and Pages redesign

Date: 2026-08-04
Status: approved for local preview

## Goal

Make the public repository explain SideRefresh in one screen, show real product
proof before technical detail, and give the README and GitHub Pages one visual
identity without implying that a signed download already exists.

## Project story

- Audience: people using coding agents or Xcode to build a personal iOS app.
- Value: rebuild, sign, and reinstall one owned app before Personal Team signing
  expires.
- Proof: the real SwiftUI workspace rendered with clearly labelled synthetic
  fixture data; it demonstrates the product state without claiming release
  evidence.
- First success: prepare Xcode once, select one app and iPhone, then verify one
  refresh.
- Theme: the SideRefresh renewal loop connecting Mac, Xcode, and iPhone.

## Art direction

- Palette: midnight `#050817`, paper `#F7FAFF`, cobalt `#2878FF`, cyan
  `#35C8FF`, mint `#5CE1B8`, fog `#A9B4C7`.
- Type: Apple system display and body faces; monospace only for evidence, dates,
  and build/sign/install labels.
- Shape: 20–28 px radii, one-pixel cool-gray rules, eight-pixel spacing rhythm.
- Motif: the S-shaped reconnection loop and a verified → refresh → expiry rail.
- Composition: calm dark technical canvas with one large real product screen.

## README structure

```text
pure SVG title + renewal flow
language / site / source links
real healthy workspace screenshot
what happens in three steps
requirements + source quick start
honest first-release limits
automation surfaces + documentation
contributing + license
```

The README remains useful without images, keeps commands in Markdown, and is
reduced below 100 lines. The Korean README keeps the same shorter order.

## Pages structure

```text
compact product + language navigation
thesis headline | large real workspace
verified-install renewal rail
three-step Xcode path
requirements | local privacy boundary
deliberately narrow first-release scope
source / release-status footer
```

All four localized pages keep equivalent structure, canonical and alternate
links, semantic headings, keyboard focus, reduced-motion behavior, and current
no-download wording. No script, analytics, tracker, generated art, remote font,
or unreviewed image is added.

## Verification

- Contract test requires the README hero, real proof, and unified Pages motif.
- Existing public-source, localization, privacy, artifact, and Pages tests pass.
- Localized HTML, CSS, shell validators, and the SVG remain below 100 lines;
  public raster assets remain below the existing size and OCR privacy limits.
- The curated Pages allowlist and build scripts remain unchanged because the
  redesign reuses only assets already present in the deployed artifact.
- README audit passes and every SVG has title, description, and a 1200-unit
  viewBox.
- Local screenshots are inspected at desktop and mobile widths.
- No commit, push, pull request, Pages deployment, or repository metadata change
  occurs before explicit approval of the preview.
