# Multilingual SideRefresh homepage design

## Subject and job

SideRefresh is an open-source Mac utility for an Agent app maker who owns one
Xcode project and uses one paired iPhone. The page has one job: explain the
Personal Team renewal workflow accurately, then lead to source or verified
release status without pretending a downloadable release already exists.

## Chosen visual direction

- Canvas `#F4F5F7`, paper `#FFFFFF`, ink `#17191D`, muted `#606771`, rule
  `#D9DDE3`, SideRefresh blue `#1267D6`, verified green `#16845B`.
- Restrained SF system display/body type with SF Mono for signing evidence.
- A quiet, light macOS utility layout: copy and the real app capture share the
  first viewport; ruled sections replace glass cards and decorative gradients.
- The single signature element is the product-specific evidence rail:
  `Verified install → Refresh before expiry → Signing expires`.
- Motion is absent by default. Only a small button lift may run when the user
  has not requested reduced motion.

## Information architecture

```text
Brand + product navigation + four direct language links
Exact value statement + source/release actions | real app capture
Verified install — next refresh — signing expiry evidence rail
Three actual workflow steps
Requirements | local privacy boundary
First-release limits | website/app language disclosure
MIT and Apple trademark footer
```

## Localization

- `/` English, `/ko/` Korean, `/ja/` Japanese, `/zh-cn/` Simplified Chinese.
- HTML language and hreflang use `zh-Hans`; the route remains `/zh-cn/`.
- Each page translates its title, metadata, navigation, body, image alt text,
  status text, and footer. English remains the Product Hunt entry route.
- Every page states that the product page has four languages while the macOS
  app interface currently has English and Korean only.
- No browser-language redirect, flags, custom selector, or translation script.

## Truth and release boundaries

- Keep one app, one iPhone, Mac/Xcode, free Personal Team, Developer Mode,
  pairing, reachability, and awake-at-renewal requirements explicit.
- Keep third-party IPA installation, fleets, Xcode-free use, and pure-cellular
  renewal outside the first-release claim.
- Label the current UI capture as a synthetic sample.
- Link to source and release status only; do not claim a Mac download yet.
- Publish Pages as a source-and-status site; keep the download CTA disabled
  until the signed-release gate is complete.

## Validation

The site validator covers four routes, reciprocal metadata, language-specific
copy, relative links, anchors, private strings, premature release claims,
scripts, tracking, and the repository file-size rule. CI and pre-push keep the
existing validator entry point.
