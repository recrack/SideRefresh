# SideRefresh brand assets

## Product copy

- Product name: **SideRefresh**
- Korean description: **개인용 iOS 앱 자동 갱신 도구**
- English description: **Automatic iOS app refresh from your own Xcode source**
- Korean tagline: **Personal Team 앱을 만료 전에 다시 설치하세요.**

Use the descriptions for product metadata and introductory copy. Use the
tagline when there is room for a user-facing benefit statement.

## Mark

The SideRefresh mark combines an `S`-shaped side-by-side path with a continuous
loop. It represents a Mac rebuilding and reconnecting a personal iOS
development app before its signing profile expires.

- `SideRefresh-AppIcon-1024.png`: transparent-corner 1024 px app icon master.
- `SideRefresh.icns`: macOS app icon generated from the PNG master.
- `SideRefresh-MenuBar.svg`: monochrome SVG template derived from the
  SideRefresh loop for the macOS menu bar.

The navy field is the stable Mac-side companion. The cobalt-to-cyan loop is
the build, sign, and reinstall cycle. The small mint bridge marks the point at
which a refreshed build reconnects to the same app identity.

## Usage

- Keep the mark free of text at menu-bar and app-icon sizes.
- Keep the menu-bar SVG monochrome and transparent. macOS supplies its color
  for light, dark, highlighted, and increased-contrast appearances.
- Do not recolor it to resemble an Apple or App Store mark.
- Do not use the symbol to imply an app store, jailbreak, or signing bypass.
- Pair it with the product name `SideRefresh` and the line
  `Automatic iOS app refresh from your own Xcode source`.

## Generation

The raster master was generated with OpenAI's built-in image generation tool.
Final production prompt:

> Create a distinctive, premium macOS app icon for SideRefresh. Combine an
> S-shaped path with a continuous renewal loop using two side-by-side flowing
> bands that turn and reconnect. Use a deep midnight indigo base, a
> cobalt-to-cyan mark, and one small mint reconnection accent. Keep precise,
> vector-like geometry, strong small-size legibility, generous safe margins,
> and no text, Apple logo, generic refresh arrows, shield, lock, or app-store
> imagery.

The generated source used a flat chroma-key canvas outside the rounded square.
That canvas was removed locally and the result was resized to the 1024 px
master before generating the `.icns` file.
