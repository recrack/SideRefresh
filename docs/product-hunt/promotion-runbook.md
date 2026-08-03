# Product Hunt promotion runbook

Updated: 2026-08-02

The goal is not to manufacture votes. The goal is to put a working open-source
product in front of relevant makers, invite genuine use, and turn their
questions into better software and documentation.

Unless an item cites a Product Hunt source, the timings, beta counts, channel
order, freeze windows, and stop choices below are SideRefresh strategy—not
Product Hunt requirements or predictions of ranking.

## Operating rules

- Ask people to **try SideRefresh and share honest feedback**, never to upvote.
- Do not offer incentives in exchange for upvotes, and do not use vote
  exchanges, coordinated voting groups, bots, purchased traffic, unsolicited
  bulk email, or mass direct messages.
- Share only in communities where the maker already participates or where the
  self-promotion rules explicitly permit it.
- Use the direct Product Hunt URL; do not use URL shorteners or tracking links.
- Disclose that you are the maker.
- Reply with evidence and limitations. Do not argue with bug reports or hide a
  requirement to improve conversion.
- Product Hunt prohibits AI-generated comments. As a conservative SideRefresh
  rule, write every Product Hunt comment and reply personally; do not use
  automated posting or replies.

These boundaries combine Product Hunt’s official rules with stricter
SideRefresh operating choices. See the
[sharing guidance](https://help.producthunt.com/en/articles/2690626-how-do-i-share-my-post),
[upvote-request policy](https://help.producthunt.com/en/articles/484935-can-i-ask-my-community-friends-family-to-upvote-a-product),
the [Community Guidelines](https://help.producthunt.com/en/articles/3615694-community-guidelines),
and the [Commenting Guidelines](https://help.producthunt.com/en/articles/10030102-commenting-guidelines).
See [the official-source research](research.md) and recheck it before launch.

## Timeline

### T−30 days or earlier: become a real community member

- Create and complete the maker’s personal Product Hunt profile. Product Hunt
  treats one week as a minimum for normal posting access and recommends joining
  much earlier for genuine participation.
- Use the product as a reason to learn from relevant launches, not as a reason
  to leave generic comments. Give specific, human-written feedback where the
  maker has actually tried or understood the product.
- Do not manufacture a posting history immediately before launch.

### T−21 to T−14 days: prove activation

- Complete the public-release and clean-account gates.
- Recruit 5–10 relevant, opt-in beta users who already use coding agents and
  have a Mac, Xcode, an Apple Account Personal Team, and a physical iPhone.
- Observe whether they can install from the public README without a call.
- Record their agent, project type, first blocked step, successful installation,
  and successful subsequent renewal without collecting credentials or source.

### T−14 to T−7 days: prepare the story

- Freeze the verified product promise and exclusions.
- Build the thumbnail, six gallery slides, and real 60-second demo from the
  release candidate.
- Prepare the listing from the [submission kit](submission.md), then have the
  maker personally write the first comment from its factual outline.
- List each intended community, its self-promotion rules, the maker’s existing
  relationship, and the exact message. Remove channels that depend on drive-by
  promotion.
- Invite contributors and beta users to review the draft. Do not ask them to
  promise launch-day votes.

### T−7 to T−2 days: schedule and rehearse

- Recheck the live Product Hunt form and official rules, then schedule within
  the allowed window.
- Prefer the start of the Product Hunt day only if the maker can support the
  full day. Product Hunt operates on Pacific Time; verify daylight saving and
  the corresponding Korea time on the selected date.
- Treat a weekend as a candidate, not a hack: Product Hunt reports more Visit
  clicks for weekend launches and notes that weekends can suit personal apps,
  but it also says there is no guaranteed best day. Support availability wins.
- Rehearse the public path in a clean browser: Product Hunt draft → repository
  → release → download → checksum → launch → first-run guide.
- Prepare a rollback/stop message and assign the solo-maker roles explicitly:
  release operator, Product Hunt replies, GitHub issue triage, and social posts.
- Freeze non-critical release changes 48 hours before launch.

### T−1 day: final gate

- Re-download and verify the exact public archive.
- Check Product Hunt links, GitHub status, release assets, screenshots, video,
  support route, security contact, and FAQ.
- Prewrite owned-channel posts, but do not send them yet.
- Confirm uninterrupted response windows and sleep coverage. Reschedule if the
  maker cannot support a broken download or security report.

### Launch day

**First 15 minutes**

- Confirm the listing is live with the correct maker, thumbnail, gallery,
  links, topics, and pricing.
- Post the maker first comment.
- Test the download once more from a logged-out session.

**First hour**

- Announce on the maker’s owned accounts and the project’s GitHub surfaces.
- Notify only opted-in beta users and contributors; ask them to try the public
  path and share honest feedback if they choose.
- Triage every report as question, documentation gap, reproducible bug,
  release blocker, or out-of-scope request.

**Rest of the Product Hunt day**

- Answer substantive comments promptly in public so later visitors benefit.
- Lead replies with the direct answer, then evidence, limitation, and next step.
- Link to a specific manual section or issue instead of pasting marketing copy.
- Fix safe documentation errors immediately. For code or artifact changes,
  publish a new version; never replace an immutable release silently.
- Share once in each pre-approved relevant community. Do not repeat the same
  post to manufacture bursts of traffic.

### T+1 to T+7 days: retain the value

- Thank commenters and publish a concise launch result without vote begging.
- Claim or request access to the long-lived Product Page and keep its release,
  links, reviews, and maker information current.
- Convert reproducible reports into labelled GitHub issues and link resolutions
  back to the original conversations where appropriate.
- Ship the smallest safe fixes and update the FAQ for repeated questions.
- Compare traffic with activation evidence, not just rank.
- At T+7, write a retrospective: promise clarity, download conversion, first
  setup, renewal evidence, common objections, useful channels, and next scope.
- Do not plan a relaunch as a quick second chance. Product Hunt currently
  requires a significant update and generally at least six months between
  launches of the same product.

## Channel order

1. **Product Hunt itself:** maker comment and factual replies.
2. **Owned surfaces:** GitHub README/Release/Discussions and the maker’s normal
   social accounts.
3. **Opt-in relationships:** beta users, contributors, and people who explicitly
   asked to hear about the release.
4. **Relevant communities:** only after reading their current self-promotion
   rules and adapting the post to that community’s problem.
5. **Editorial outreach:** newsletters, podcasts, or maintainers who cover open
   source, agent tooling, or personal iOS development; pitch the story and demo,
   never a vote.

Do not open every channel at once. Start with the people most likely to install
the product and answer their questions before expanding reach.

## Announcement templates

### English

> I launched SideRefresh today. It is an open-source Mac app that keeps personal iOS apps made with Claude Code, Codex, Cursor, or Xcode running by rebuilding and reinstalling them through Xcode Personal Team before signing expires. If this is your workflow, I’d value an honest test—especially where first setup becomes unclear: [Product Hunt URL]

### Korean

> 오늘 SideRefresh를 공개했습니다. Claude Code, Codex, Cursor 또는 Xcode로 만든 개인용 iOS 앱을 Personal Team 서명이 만료되기 전에 다시 빌드·설치하는 오픈소스 Mac 앱입니다. 같은 방식으로 개인 앱을 쓰고 있다면 직접 설치해보고, 특히 최초 설정에서 막히는 부분을 알려주세요: [Product Hunt URL]

### Community-specific opening

> I’m the maker of SideRefresh. I built it after repeatedly losing access to small personal iOS apps created with coding agents when free Personal Team signing expired. This community’s rules allow project sharing, so here is the source, exact scope, and the limitation I most want feedback on: [direct link]

Remove the post if the community’s current rules do not allow this format. Do
not append “please upvote,” even indirectly.

## Reply pattern

Use four parts:

1. **Answer:** yes, no, or the exact supported state.
2. **Evidence:** the relevant behavior, release, screenshot, or documentation.
3. **Boundary:** what is experimental, unsupported, or still Apple-controlled.
4. **Next step:** a workaround, issue link, diagnostic request, or planned
   decision—not a vague promise.

Example:

> Not yet. Tailscale can verify the selected peer and network path, but it does not replace Xcode pairing or prove pure-cellular installation. We currently support a verified first USB installation and only advertise routes that have completed the release checks. If remote renewal is your use case, please add your Mac/iPhone conditions to this issue: [issue URL].

## Metrics and retrospective

Capture at launch, T+1, and T+7:

| Signal | Source | Interpretation |
| --- | --- | --- |
| Independent successful first setups | Opt-in reports / GitHub discussions | Strongest evidence that positioning converts into use. |
| Verified subsequent renewals | Opt-in reports | Evidence for the core promise, not just installation. |
| Failure stage and recovery success | GitHub issues / support | Shows where product or docs need work. |
| Release downloads and GitHub visitors/clones | GitHub insights | Reach; downloads are not proof of activation. |
| Stars, watchers, contributors | GitHub | Continuing open-source interest. |
| Product Hunt comments and maker analytics | Product Hunt | Message resonance and questions. |
| Product Hunt rank/points | Product Hunt | Visibility context only; do not treat as the launch objective. |

Before launch, record the starting values and choose a named owner for the
retrospective. Do not add covert app telemetry just to fill this table.

## Stop conditions

Pause announcements immediately when any of these occurs:

- public download, checksum, signature, notarization, or Gatekeeper verification
  fails;
- a security, privacy, credential, signing-material, device-identifier, or
  repository-history exposure is suspected;
- the listing materially overstates supported installation or renewal;
- first setup is broadly blocked by a reproducible release defect; or
- Product Hunt or a community moderator flags the sharing behavior.

Post a factual status, keep evidence, fix with a new reviewed artifact when
needed, and resume only after the same public path passes again.
