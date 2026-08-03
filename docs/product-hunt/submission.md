# Product Hunt submission kit

Updated: 2026-08-03

Use this document when creating the Product Hunt draft. Product Hunt’s live
form is the final authority: field names, limits, topic names, and scheduling
controls must be checked again before submission.

## Registration procedure

1. Create a **personal** Product Hunt account for the maker, not a branded or
   company account. Complete the real first and last name, personal photo,
   unique username, and headline/about section.
2. Complete onboarding and establish posting access at least one week before
   launch. Current official pages conflict: newer personal-account guidance says
   the account must be more than one week old, while the posting-access page
   still describes newsletter-based immediate access. Plan for the full wait and
   confirm access in the authenticated UI.
3. While signed in, choose **Post/Submit → New Product** and enter the direct
   SideRefresh product URL. A public GitHub repository is accepted, but it must
   provide the verified download rather than route visitors through a press
   post.
4. Complete the fields below in English, add every maker by Product Hunt
   username, upload the release-candidate assets, and save a draft.
5. Review the public preview from a logged-out browser. Do not schedule while
   the repository or release requires authentication.
6. Choose **Schedule Launch** only after the Go/No-Go review. The current help
   center permits a date within 30 days and allows the scheduled draft to keep
   being edited before launch.
7. Recheck the final listing and public download on launch day, then use the
   maker’s personally written comment to start a genuine feedback conversation.

Official references: [How to post a product](https://help.producthunt.com/en/articles/479557-how-to-post-a-product),
[personal versus company accounts](https://help.producthunt.com/en/articles/771527-personal-account-vs-company-account),
[posting access](https://help.producthunt.com/en/articles/481909-how-can-i-get-access-to-post),
and [scheduling](https://help.producthunt.com/en/articles/2724119-how-to-schedule-a-post).

## Ready-to-paste listing

The expanded live-form fields, owner decisions, Shoutouts, and exact current
copy are maintained in [copy/listing.md](copy/listing.md).

**Product name**

> SideRefresh

**Tagline**

> Keep agent-built iOS apps alive on your iPhone

**Short description**

> SideRefresh is an open-source Mac app that rebuilds, signs, and reinstalls agent-built iOS apps before free Personal Team signing expires. Personal use needs no paid Apple Developer Program membership; Mac, Xcode, and an Apple Account are required.

**Pricing**

> Free

**Status after the stable-release gate passes**

> Available now

**Promo**

> None

**Primary URL after public-release verification**

> https://github.com/recrack/SideRefresh

After the public-readiness and stable-release gates pass, replace this draft
value with `https://recrack.github.io/SideRefresh/`. Add the exact immutable
GitHub Release asset as the download link; do not use `/releases/latest` while
historical releases carry the old product name.

The root product page is English for Product Hunt. It links to complete Korean,
Japanese, and Simplified Chinese explanations while stating separately that
the shipped app interface currently supports English and Korean.

The README must behave like a landing page: the signed download and three-step
setup appear before contributor-only build instructions. Add the exact GitHub
Release as a secondary link when the form permits it. Do not use shortened or
tracking URLs.

**Topic candidates**

- Open Source
- Developer Tools
- AI Coding Agents or Vibe Coding Tools, if that exact relevant label exists

Choose at most the number allowed by the live form and only exact topics that
exist there. Do not add broad topics merely for reach.

## Positioning guardrails

Use:

- `agent-built iOS apps`
- `your own Xcode project`
- `free Xcode Personal Team`
- `rebuilds, signs, and reinstalls before expiration`
- `no paid Apple Developer Program membership for personal-device use`

Avoid:

- `no developer account required`
- `permanent signing`
- `install any IPA`
- `remote install from anywhere`
- `works without Xcode`
- `fully automatic` without stating the initial Apple-required setup

## Thumbnail and gallery

Use the [240×240 static PNG](assets/thumbnail-240.png), derived from the
canonical app icon and kept below 3 MB. It contains no small text or animation.

Build one 1270×760 English gallery story:

| Slide | Headline | Visual proof |
| --- | --- | --- |
| 1 | **Your agent builds it. SideRefresh keeps it running.** | App icon and an abstract renewal loop; no Apple product artwork. |
| 2 | **Free Personal Team apps expire.** | A short lifecycle showing build → install → expiration → renewal. |
| 3 | **One app. One iPhone. One next action.** | The real Simple workspace with the selected app, selected iPhone, and renewal condition. |
| 4 | **Refresh through Apple’s normal Xcode flow.** | Xcode project → SideRefresh → paired iPhone; never imply a signing bypass. |
| 5 | **Your source stays on your Mac.** | Local processing, no Apple password collection, explicit project and device access. |
| 6 | **Open source. Local by design.** | MIT source, public checks, English/Korean UI, and the signed/notarized release gate. |

The checked-in draft uses a DEBUG fixture that mirrors the repository's
`SideRefresh Sample` project. Every public screenshot must replace it with the
exact release candidate using that real Sample app. Do not composite an
unimplemented state or depict experimental Tailscale reachability as a
verified installation.

The review-ready images and editable sources are in [assets](assets/README.md).
They remain visibly marked as drafts until the release-candidate replacement
and fact check in the asset checklist.

## 60-second demo

1. **0–7 seconds:** show the tagline and the Personal Team expiration problem.
2. **8–18 seconds:** show a real app made with a coding agent in Xcode.
3. **19–32 seconds:** choose its workspace/project and one paired iPhone in
   SideRefresh.
4. **33–50 seconds:** run a real refresh, condensing elapsed build time without
   changing the result.
5. **51–60 seconds:** show the Verified renewal evidence and next scheduled
   refresh.

Use English captions and a full public or Unlisted YouTube URL. Private videos
and short `youtu.be` URLs are not supported. Never claim an outcome that the
recording did not verify. Use the complete [demo package](demo/README.md).

## Maker first-comment outline

Product Hunt’s [Commenting Guidelines](https://help.producthunt.com/en/articles/10030102-commenting-guidelines)
prohibit AI-generated comments. As a conservative SideRefresh operating rule,
the maker writes and posts the comment personally; do not paste generated prose
from this repository or use automated posting or replies. Cover these factual
points:

1. **Personal origin:** the small personal iOS app the maker built with a coding
   agent and why repeating the Personal Team refresh became a real problem.
2. **Exact workflow:** one Xcode project, one paired iPhone, first verified
   installation, then a local rebuild/sign/reinstall before expiration.
3. **Trust boundary:** Apple’s normal Xcode tooling, local source, no Apple
   password collection, no IPA store, and no signing bypass.
4. **Requirements:** Mac, Xcode, Apple Account Personal Team, initial pairing,
   trust, and Developer Mode; no paid Apple Developer Program membership for
   the user’s personal app.
5. **Deliberate scope:** one app and one iPhone in the first release.
6. **Specific question:** ask where first setup was unclear, which coding-agent
   workflow the visitor uses, or which failure needs a clearer next action.

Before posting, the maker should read the final comment aloud, remove generic
marketing language, verify every claim against the release, and make it sound
like a real account of why they built SideRefresh.

Use the [human-only worksheet](copy/first-comment-worksheet.md); it is not a
comment draft and must not be pasted into Product Hunt.

## FAQ answers

These answers are approved product facts for the listing, README, and support
documentation. When responding to a Product Hunt comment, the maker must answer
personally rather than paste generated wording.

**Who is it for?**

> People using Claude Code, Codex, Cursor, or Xcode to build personal iOS apps that are not intended for App Store distribution.

**Does it remove Apple’s expiration?**

> No. It repeats Apple’s normal development build, signing, and installation path before expiration.

**Do I need a paid developer membership?**

> Not for your personal iOS app. You still need an Apple Account Personal Team. Separately, the public SideRefresh Mac binary is Developer ID signed and Apple notarized by its distributor.

**Does SideRefresh receive my Apple Account password?**

> No. Account sign-in, agreements, certificates, pairing, trust, and Developer Mode stay in Apple’s Xcode and system flows.

**Does it upload my source code?**

> No. SideRefresh rebuilds the selected local source on your Mac with Xcode.

**Can it install downloaded third-party IPAs?**

> No. The first release supports one app you own from one selected Xcode project or workspace.

**Does Tailscale make remote installation fully supported?**

> Not yet. Tailscale discovery is experimental and does not replace Xcode pairing or prove pure-cellular CoreDevice installation.

**What should I try first?**

> Follow the first-run guide, complete one verified USB installation, then explicitly enable automatic refresh.

## Final draft review

- [ ] Tagline fits the current limit and stays readable without the description.
- [ ] Description fits the current limit and names every material requirement.
- [ ] The primary URL opens without authentication and the download works.
- [ ] Thumbnail, gallery, and demo reflect the exact public build.
- [ ] Makers are attached by their personal Product Hunt usernames.
- [ ] The maker has personally written and fact-checked the first comment.
- [ ] FAQ answers match README, manuals, release notes, and actual behavior.
- [ ] English spelling, captions, contrast, and small-screen crops are checked.
- [ ] No text asks for an upvote or promises unsupported remote behavior.
- [ ] No Product Hunt comment or reply is AI-generated or automatically posted.
