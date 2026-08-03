# Product Hunt 등록·출시·홍보 공식 조사

기준일: **2026-08-02**

대상 제품: **SideRefresh** — 코딩 에이전트가 만든 개인용 iOS 앱을 무료 Xcode Personal Team 흐름으로 다시 빌드·서명·설치하도록 돕는 오픈소스 macOS 앱.

## 조사 범위와 읽는 법

- Product Hunt가 직접 운영하는 `producthunt.com` Launch Guide·Stories와 `help.producthunt.com` Help Center만 정책 근거로 사용했다. 커뮤니티 게시물, 대행사 글, SEO 블로그, 개인 경험담은 근거에서 제외했다.
- **공식 사실**은 Product Hunt가 명시한 자격·정책·권장 사항이다. 각 핵심 주장 옆에 공식 원문과 확인일을 붙였다.
- **SideRefresh 적용(전략적 추론)**은 공식 기준을 현재 제품에 적용한 제안이다. Product Hunt가 성공이나 Featured 노출을 보장한다는 뜻이 아니다.
- 저장소 상태는 Product Hunt 정책 출처가 아니라 현재 로컬 문서와 GitHub 저장소를 확인한 결과다.

## 결론

**SideRefresh는 Product Hunt의 디지털 제품 범주와 잘 맞지만, 현재는 예약하지 않는 것이 맞다.** Product Hunt는 즉시 사용할 수 있는 live digital product를 우선 Featured 대상으로 삼고 waitlist·vaporware는 배제하거나 불리하게 본다. 오픈소스라는 사실 자체는 공식 Featured 가산점이 아니며, `Useful`, `Novel`, `High Craft`, `Creative` 중 한두 가지가 강하게 드러나야 한다. — [Featuring Guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines) · 확인 2026-08-02

개인정보를 제거한 단일 커밋 공개 소스 후보와 커뮤니티 파일은 준비됐다.
Developer ID로 서명·공증한 안정 Mac 바이너리는 아직 없으므로 Product Hunt는
계속 보류한다. 현재 게이트는 [공개 준비 감사](public-readiness-audit.md)와
[SideRefresh 배포 문서](../DISTRIBUTION.md)를 따른다. · 업데이트 2026-08-03

**권장 출시 포지션은 “sideloading 도구”보다 “agent app maker의 개인 iOS 앱을 계속 실행 가능하게 유지하는 Mac 앱”이다.** 이는 SideRefresh가 타인의 IPA 설치나 Apple 서명 우회를 제공하지 않는다는 제품 경계를 선명하게 하면서, 공식 기준의 usefulness와 novelty를 동시에 설명하는 전략적 추론이다.

## 공식 문서 간 차이와 적용 원칙

Product Hunt의 Help Center와 Launch Guide 일부가 서로 다르다. 실제 등록 시에는 **더 최신 Help Center → 현재 제출 UI → 오래된 Launch Guide 예시** 순으로 판단한다.

| 항목 | 공식 문서 상태 | 이 문서의 안전한 적용 |
| --- | --- | --- |
| 제출 종료 동작 | Launch Guide에는 `Launch now`가 남아 있지만, Help Center는 이를 없애고 `Create Draft`와 `Schedule`만 제공한다고 명시한다. — [Launch Now 제거](https://help.producthunt.com/en/articles/9823193-where-did-launch-now-go) · 확인 2026-08-02 | `Create Draft`로 검토한 뒤 `Schedule`한다. |
| 예약 범위 | 2026-02-02 Help Center는 현재 날짜로부터 30일 이내를 예약할 수 있다고 한다. — [예약 방법](https://help.producthunt.com/en/articles/2724119-how-to-schedule-a-post) · 확인 2026-08-02 | 30일보다 일찍 Product Hunt에 등록하려 하지 말고 외부 준비를 먼저 한다. |
| Description 길이 | Help Center는 260자, Launch Guide는 500자로 안내한다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product), [콘텐츠 체크리스트](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | 260자 이하로 작성하고 제출 UI의 실제 제한을 마지막에 확인한다. |
| 시간대 표기 | 공식 문서는 `PST`, `PT`, 자정 또는 12:01 a.m.을 혼용한다. 다만 사이트가 Pacific Time 기준 24시간 주기로 동작하고, 준비된 제품은 시작 시점에 맞춰 예약하라는 취지는 일치한다. — [Getting Started](https://help.producthunt.com/en/articles/2305333-getting-started), [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | 캘린더 날짜를 정한 후 예약 UI에 표시되는 실제 시각·시간대를 확인한다. 한국 시각은 임의로 고정하지 않는다. |

## 1. 등록 자격과 계정 준비

### 공식 사실

- 제품을 게시하려면 **개인 계정**이 필요하다. 회사·브랜드 계정은 게시, 투표, 댓글을 할 수 없다. — [게시 권한](https://help.producthunt.com/en/articles/481909-how-can-i-get-access-to-post), [Getting Started](https://help.producthunt.com/en/articles/2305333-getting-started) · 확인 2026-08-02
- 프로필은 실제 개인을 나타내야 하며 이름과 성, 본인 사진, headline/about, 회사명이 아닌 고유 username을 갖추는 것이 공식 요구사항이다. 불완전하거나 오해를 주는 프로필은 검토·노출 제한·삭제 가능성이 커진다. — [Community Guidelines](https://help.producthunt.com/en/articles/3615694-community-guidelines) · 확인 2026-08-02
- 새 개인 계정의 게시 권한에 관한 공식 안내는 충돌한다. 최신 [개인 계정과 회사 계정 안내](https://help.producthunt.com/en/articles/771527-personal-account-vs-company-account)는 계정 생성 후 1주가 지나야 한다고 하지만, [게시 권한 안내](https://help.producthunt.com/en/articles/481909-how-can-i-get-access-to-post)는 newsletter 구독 시 즉시 권한을 받을 수 있다고 한다. 안전하게 1주를 계획하고 로그인된 UI에서 최종 확인한다. · 확인 2026-08-02
- Launch Guide는 1주를 최소치로 보고 가능하면 출시 3개월 이상 전에 가입해 실제 커뮤니티 활동을 쌓으라고 권장한다. — [Before launch](https://www.producthunt.com/launch/before-launch) · 확인 2026-08-02
- 모든 제출물은 영어로 작성해야 하며 비영어 제출물은 삭제될 수 있다. — [게시물 삭제 사유](https://help.producthunt.com/en/articles/3539992-why-was-my-comment-or-post-removed) · 확인 2026-08-02
- Product Hunt는 사용자가 즉시 탐색하고 사용할 수 있는 완전 출시 제품을 우선한다. 이메일 가입만 있는 제품은 홈페이지 대상이 아니다. — [미출시 제품 정책](https://help.producthunt.com/en/articles/484932-can-i-submit-an-unreleased-product) · 확인 2026-08-02

### SideRefresh 적용(전략적 추론)

1. Maker 본인의 실명·얼굴 사진·소개·개인 링크가 있는 계정을 지금 만들고, 출시를 위해 만든 일회성 계정처럼 보이지 않게 한다.
2. 한국어를 지원하는 앱이어도 Product Hunt의 이름, tagline, description, gallery 문구, 첫 댓글과 답글은 영어로 운영한다. README와 앱에서 한국어를 병행하는 것은 제품 기능으로 소개할 수 있다.
3. 소스 빌드만 가능한 private 저장소 상태로는 출시하지 않는다. 최소 조건은 public 저장소, 실제 다운로드 가능한 안정 릴리스, 깨끗한 Mac에서의 다운로드·첫 실행 검증이다.
4. Developer ID 서명·Apple 공증 여부를 랜딩 페이지에 명확히 표시한다. Gatekeeper 경고를 우회하도록 요구하는 흐름은 live/high-craft 인상을 크게 해치므로 출시 게이트로 본다.

## 2. Hunter와 Maker

### 공식 사실

- Hunter는 게시한 사람이고 Maker는 제품을 만든 사람이다. Maker로 태그되면 Maker badge와 댓글 권한으로 제품 제작자임을 명확히 보여줄 수 있다. — [Hunter vs Makers](https://help.producthunt.com/en/articles/10082986-hunter-vs-makers-and-how-to-change-them) · 확인 2026-08-02
- 별도의 유명 Hunter는 필요하지 않다. Product Hunt는 Maker가 직접 self-hunt해 출시 통제권을 갖는 방식을 권장한다. Launch Guide는 Featured 게시물의 79%, Product of the Day 1위의 60%가 self-hunt였다고 공개한다. — [Before launch](https://www.producthunt.com/launch/before-launch) · 확인 2026-08-02
- Hunter의 follower는 출시 이메일을 받지 않으며, Maker의 follower는 게시물이 홈페이지에 Featured될 경우 이메일 알림을 받는다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product) · 확인 2026-08-02
- Hunter나 promoter에게 돈을 주거나, 돈을 받고 트래픽을 보내는 서비스는 정책 위반이다. 제품 unfeature·삭제와 Maker 계정 영구 제한까지 이어질 수 있다. — [Before launch](https://www.producthunt.com/launch/before-launch) · 확인 2026-08-02

### SideRefresh 적용(전략적 추론)

- SideRefresh를 가장 잘 설명하고 당일 기술 질문에 답할 수 있는 maintainer가 직접 self-hunt한다.
- 실제로 제품을 만든 공동 기여자만 Maker로 추가하고, 각 Maker가 출시 전에 정상 개인 계정을 준비하게 한다.
- “유명 Hunter를 구하면 노출된다”는 가정과 유료 홍보 제안은 계획에서 제외한다.

## 3. 등록 절차와 제출 필드

### 공식 등록 순서

1. 개인 계정으로 로그인하고 상단 `Post`에서 제품 URL을 입력해 제출 흐름을 시작한다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product) · 확인 2026-08-02
2. 모든 필드를 채우고 preview를 검토한 뒤 `Create Draft`를 만든다. Draft는 검색·색인되지 않으며 공동 Maker와 검토할 수 있다. — [Launch Now 제거](https://help.producthunt.com/en/articles/9823193-where-did-launch-now-go) · 확인 2026-08-02
3. 출시일이 정해지면 현재 날짜로부터 30일 이내의 날짜로 `Schedule Launch`한다. 예약 뒤에도 `My Products`에서 편집할 수 있고, 예약 시각 전에는 upvote할 수 없다. — [예약 방법](https://help.producthunt.com/en/articles/2724119-how-to-schedule-a-post) · 확인 2026-08-02
4. 예약 페이지는 기본적으로 연결된 Maker와 제품 팀만 볼 수 있다. 필요하면 상단 lock icon에서 `Public`으로 바꿔 링크 보기를 허용할 수 있다. — [예약 출시 공유](https://help.producthunt.com/en/articles/15706445-how-to-share-a-scheduled-launch) · 확인 2026-08-02

### 필드별 준비안

| 필드 | 공식 요건·권장 | SideRefresh 준비안(전략적 추론) |
| --- | --- | --- |
| Primary URL | 제품을 사용하거나 다운로드할 수 있는 직접 링크를 쓴다. 보도자료·블로그 링크는 피하고, Launch Guide는 GitHub 저장소도 가능한 URL로 든다. 단축·추적 URL은 허용하지 않는다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product), [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | 한 가지 `Download for Mac` CTA가 있는 영어 랜딩 페이지를 우선한다. 없으면 public GitHub 저장소를 사용하되 최신 notarized release가 첫 화면에서 바로 보여야 한다. |
| Product name | 설명이나 emoji를 붙이지 않고 제품명만 쓴다. — [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | `SideRefresh` |
| Tagline | 최대 60자이며 과장보다 무엇을 하는지 즉시 이해되는 짧은 문구를 권장한다. — [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | `Keep agent-built iOS apps alive on your iPhone` |
| Description | 공식 페이지의 제한이 260자와 500자로 충돌한다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product), [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | 아래 260자 이하 초안을 사용하고 실제 UI에서 재확인한다. |
| Launch tags/topics | 제품과 가장 강하게 관련된 소수만 선택한다. Launch Guide는 최대 3개를 안내한다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product), [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | 실제 UI 명칭 중 `Open Source`, `Developer Tools` 또는 `Engineering & Development`, `AI Coding Agents` 또는 `Vibe Coding Tools` 계열에서 정확히 3개 이하를 선택한다. |
| Download/additional links | App Store·Google Play 등 추가 링크를 별도 입력할 수 있다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product) · 확인 2026-08-02 | GitHub Release, source repository, English manual을 우선순위대로 제공한다. |
| Pricing | `free`, `paid`, `paid with a free trial/plan` 중 실제 상태를 고른다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product) · 확인 2026-08-02 | `Free` |
| Status | beta 또는 미출시 상태를 표시할 수 있지만, Product Hunt는 현재 사용 가능한 live 제품을 Featured 우선 대상으로 본다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product), [Featuring Guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines) · 확인 2026-08-02 | 다운로드·첫 실행·핵심 갱신이 검증된 `Available now` 상태에서만 출시한다. |
| Promo | 현재 제출 UI에서 실제 promotion 상태를 확인한다. | 할인이나 별도 프로모션이 없으므로 `None`을 선택한다. |
| Product X account | 제품 계정이 있으면 개인 계정이 아닌 제품 X handle을 넣는다. — [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | 전용 계정이 활성 운영 중일 때만 추가하고, 빈 계정을 만들지 않는다. |
| Makers | 실제 제작자만 개인 Product Hunt username으로 연결한다. — [Hunter vs Makers](https://help.producthunt.com/en/articles/10082986-hunter-vs-makers-and-how-to-change-them) · 확인 2026-08-02 | 기여하지 않은 사람을 노출 목적으로 추가하지 않는다. |
| Shoutouts | 현재 최대 3개 제품과 각각의 이유를 추가할 수 있다. — [Shoutout 추가](https://help.producthunt.com/en/articles/9097078-how-to-add-a-shoutout) · 확인 2026-08-02 | 실제 제작·검증에 중요했던 제품만 선택하고 이유를 Maker가 사실 확인한다. |
| Thumbnail | 정사각형 240×240을 권장한다. GIF는 3MB 미만이어야 하고 hover에서만 재생되므로 첫 frame이 중요하다. 과도한 번쩍임·빠른 전환·읽기 힘든 글자는 피한다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product) · 확인 2026-08-02 | 앱 아이콘을 사용한 정지 PNG. 작은 화면에서 읽히지 않는 문구는 넣지 않는다. |
| Gallery | 1270×760을 권장하며 2개 이상이어야 게시물에서 보인다. 순서를 바꿀 수 있다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product) · 확인 2026-08-02 | 실제 영어 UI 6장: 결과 → 문제 → 앱·iPhone 선택 → Refresh → Verified result → local/open-source trust boundary. |
| Video/demo | 영상은 공개 또는 unlisted YouTube의 전체 URL만 지원하며 private·단축 URL은 동작하지 않는다. 지원되는 interactive demo도 gallery에 추가할 수 있다. — [게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product) · 확인 2026-08-02 | 45–75초 실제 화면 녹화. 에이전트가 만든 Xcode project를 선택하고 한 번 갱신해 검증 결과가 표시되는 흐름을 보여준다. 검증되지 않은 원격 설치를 연출하지 않는다. |
| First comment | Maker가 제품, 대상, 제작 배경, 목표, 핵심 기능, 제안·가격을 소개하고 **upvote가 아닌 feedback**을 요청하도록 권장한다. — [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02 | 문제의 기원, 정확한 작동 범위, Apple 요구사항, 첫 릴리스 제한과 구체적인 피드백 질문을 사람이 직접 작성한다. |

### 시각 자산·상표 적용

- Apple 로고, Xcode 아이콘, Apple이 제공한 제품 사진·기기 bezel을 임의의
  제3자 홍보 합성물에 사용하지 않는다. 생성 이미지로 iPhone 외형을
  재현하지 않고, 실제 제품 증거는 SideRefresh 자체 UI로 보여준다. —
  [Apple 제3자 상표 지침](https://www.apple.com/legal/intellectual-property/guidelinesfor3rdparties.html),
  [Apple 상표 목록](https://www.apple.com/legal/intellectual-property/trademark/appletmlist.html)
  · 확인 2026-08-02
- `Apple, Mac, iPhone, macOS, Xcode`를 쓰는 랜딩·영상에는 Apple 상표 고지와
  독립·비제휴 문구를 넣는다. Apple의 후원이나 승인을 암시하지 않는다.
- Product Hunt 배지는 출시 전에 직접 만들지 않는다. 출시 후 Launch Page의
  공식 `Embed`에서 받은 원본을 사용한다. —
  [Product Hunt 배지](https://help.producthunt.com/en/articles/2731371-how-to-add-a-product-hunt-badge-to-your-website)
  · 확인 2026-08-02

Description 초안:

> SideRefresh is an open-source Mac app that rebuilds, signs, and reinstalls agent-built iOS apps before free Personal Team signing expires. Personal use needs no paid Apple Developer Program membership; Mac, Xcode, and an Apple Account are required.

피해야 할 표현:

- `No developer account required` — Apple Account도 필요 없다는 오해를 만든다.
- `Never expires` 또는 `permanent signing` — SideRefresh는 만료를 없애지 않고 정상 Xcode 흐름을 반복한다.
- `Install any IPA` — 첫 릴리스의 사용자 소유 Xcode project 범위와 다르다.
- `Remote refresh anywhere` — 현재 실증되지 않은 Tailscale/CoreDevice 범위를 과장한다.

## 4. 날짜와 시간 선택

### 공식 사실

- “가장 좋은 날”에 대한 보장 공식은 없으며 제품과 팀이 준비된 날이 우선이다. Product Hunt는 평일에 큰 회사와 solo maker가 함께 많이 출시하고, 주말은 작은 팀·side project·personal app에 적합할 수 있다고 설명한다. 공식 집계상 주말 제품은 평일보다 `Visit` 클릭이 15% 많았다. — [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02
- 별도 제약이 없으면 12:01 a.m. Pacific Time에 시작해 24시간을 모두 확보하는 것을 rule of thumb으로 제시한다. 다만 타깃 지역, 보도 시각, Maker가 답변 가능한 시간에 맞춰 다른 시각을 택할 수 있다고 명시한다. — [출시 준비](https://www.producthunt.com/launch/preparing-for-launch) · 확인 2026-08-02

### SideRefresh 적용(전략적 추론)

- 기본 후보는 **주말**이다. SideRefresh가 solo/side-project 성격의 personal app이고, 목표가 대기업과의 순위 경쟁보다 실제 다운로드·설치 피드백이라면 공식 주말 데이터와 잘 맞는다.
- 단, maintainer가 첫 12시간 동안 질문과 설치 문제에 대응할 수 있는 날을 최우선으로 한다. 주말 대응이 어렵다면 평일 출시가 낫다.
- 예약 UI에서 Pacific 날짜와 실제 게시 시각을 확인한 뒤 한국 캘린더에 별도 기록한다. 공식 문서의 PST/PT 혼용 때문에 수동 환산값만 믿지 않는다.

## 5. Featured와 순위: 알려진 공식 기준

Featured 여부와 leaderboard 순위는 같은 판단이 아니다.

### Featured 선정

- Product Hunt 팀은 digital이고 live인 제품을 검토하며 `Useful`, `Novel`, `High Craft`, `Creative`를 본다. 모든 항목에서 높을 필요는 없고 한두 가지가 강할 수 있다. — [Featuring Guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines) · 확인 2026-08-02
- waitlist-only, directory, template, boilerplate, report, service, off-topic 제품 등은 Featured 대상이 아니며, vaporware와 장기 가치보다 즉시 수익화만 앞세운 미분화 제품도 불리하다. — [Featuring Guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines) · 확인 2026-08-02
- engagement는 고려 요소지만 전부가 아니다. 팀이 제출 내용과 링크를 여러 차례 검토하고, 대부분의 결정은 최종적이다. 최초 제출에 없던 중대한 정보가 아니면 Featured 요청 연락을 반복하지 말라고 안내한다. — [Featuring Guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines) · 확인 2026-08-02
- Featured되지 않아도 게시물은 `All` feed에 남아 댓글과 upvote를 받을 수 있다. — [홈페이지 미노출 안내](https://help.producthunt.com/en/articles/484926-why-is-my-post-not-on-the-homepage) · 확인 2026-08-02

### 순위와 award

- 홈페이지 순위는 단순 upvote 수가 아니라 points로 정해진다. Product Hunt는 genuine engagement, upvote, comment와 기타 신호를 보며 정확한 공식은 조작 방지를 위해 공개하지 않는다. — [Points 설명](https://help.producthunt.com/en/articles/10275873-what-are-points), [홈페이지 순위](https://help.producthunt.com/en/articles/484938-how-is-the-homepage-ranked) · 확인 2026-08-02
- Product of the Day는 같은 날 제품 중 launch-day points가 가장 높은 제품, Week는 월–일 사이, Month는 해당 달에서 points가 가장 높은 제품이다. — [Product of the Day, Week & Month](https://help.producthunt.com/en/articles/11751186-product-of-the-day-week-month) · 확인 2026-08-02
- clear and thoughtful page, 진짜 feedback에 대한 관심, 실제 사용자의 자연스러운 참여가 권장되며 mass upvote campaign은 반대 효과를 낼 수 있다. — [Product of the Day, Week & Month](https://help.producthunt.com/en/articles/11751186-product-of-the-day-week-month) · 확인 2026-08-02

### SideRefresh의 Featured 증거 설계(전략적 추론)

| 공식 기준 | SideRefresh가 보여줄 증거 |
| --- | --- |
| Live | public 저장소, notarized Mac 다운로드, 깨끗한 Mac 설치 검증, 작동하는 지원 링크 |
| Useful | “개인용 agent-made app은 만들기 쉬워졌지만 Personal Team 갱신은 반복된다”는 한 문장 문제와 실제 refresh 완료 화면 |
| Novel | IPA store가 아니라 **사용자 자신의 source를 Apple 도구로 지속 갱신**하는 agent app maker 전용 workflow라는 차이 |
| High Craft | Simple workspace, 명확한 다음 행동, 영어·한국어, 이해 가능한 signing/connection 오류와 1분 데모 |
| Creative | “Your agent builds it. SideRefresh keeps it running.”의 일관된 시각 이야기와 Maker의 실제 제작 배경 |

오픈소스·무료라는 속성은 신뢰와 장기 가치의 증거로 활용하되, 그 자체가 Featured 조건이라고 주장하지 않는다.

## 6. 출시 전 전략

### 공식 권장 행동

- 출시 직전이 아니라 미리 개인 프로필을 완성하고 Product Hunt에서 진정성 있게 참여한다. 다른 제품에 실제 사용 기반의 feedback을 주고 관계를 만든다. — [Before launch](https://www.producthunt.com/launch/before-launch), [출시 공유](https://www.producthunt.com/launch/sharing-your-launch) · 확인 2026-08-02
- 제품 가치와 한 가지 사용 CTA에 집중한 landing page를 준비한다. — [출시 공유](https://www.producthunt.com/launch/sharing-your-launch) · 확인 2026-08-02
- Product of the Day만 목표로 보지 말고 comment, follower, traffic, user, feedback, brand reach처럼 측정 가능한 목표를 제품 목표와 연결한다. — [Before launch](https://www.producthunt.com/launch/before-launch) · 확인 2026-08-02
- launch link는 소셜 미디어에 자연스럽게 공유하고, 이미 활동 중인 관련 커뮤니티에서 이야기하는 것이 권장된다. — [게시물 공유](https://help.producthunt.com/en/articles/2690626-how-do-i-share-my-post) · 확인 2026-08-02

### SideRefresh 실행안(전략적 추론)

#### T-30 ~ T-15: 제품을 실제 공개 가능한 상태로 만든다

- 비공개 개발 저장소의 visibility를 직접 바꾸지 않고, 개인정보 검사를 통과한
  단일 커밋 소스 스냅샷만 공개한다.
- 제품명 `SideRefresh`를 앱, release, 다운로드 파일, README, 랜딩에
  일치시킨다. 비공개 전신의 SideRenew 릴리스는 공개 저장소로 복사하지 않는다.
- Developer ID 서명·공증·staple한 바이너리를 만들고 깨끗한 Mac 계정에서 다운로드부터 첫 실행까지 검증한다.
- 실제 agent app maker가 README만 보고 앱 1개와 iPhone 1대를 설정해 첫 Verified renewal까지 완료하는지 확인한다.

#### T-14 ~ T-8: 메시지와 자산을 검증한다

- 영어 랜딩 페이지의 첫 화면을 `문제 → 대상 → Download for Mac → 요구사항` 순서로 만든다.
- thumbnail, 1270×760 gallery 6장, 45–75초 demo, 짧은 FAQ를 실제 제품 화면으로 만든다.
- `No paid Apple Developer Program required for personal use`와 `Mac, Xcode, Apple Account required`를 같은 화면에서 보여 오해를 줄인다.
- 사용자에게 “upvote해 달라”가 아니라 설치 과정과 설명의 이해 여부를 물어 copy를 수정한다.

#### T-7 ~ T-1: Draft를 완성한다

- Maker 계정으로 self-hunt Draft를 만들고 모든 링크·이미지·영상을 실제 preview에서 확인한다.
- 첫 댓글은 maintainer가 직접 쓰고, 핵심 기능·대상·배경·제약·원하는 feedback 질문을 포함한다.
- X, LinkedIn, GitHub Discussions/Release, opt-in newsletter, 이미 활동 중인 커뮤니티별 공지 초안을 준비하되 문구에 `upvote` 요청을 넣지 않는다.
- 당일 설치 질문, signing 질문, bug report를 누가 답할지 정하고 지원 시간을 확보한다.

## 7. 출시 당일 전략

### 공식 권장 행동

- 당일 가장 중요한 일은 출시를 알리는 것과 comment에 실시간 또는 최대한 빠르게 답하는 것이다. — [출시 공유](https://www.producthunt.com/launch/sharing-your-launch) · 확인 2026-08-02
- Launch Day dashboard에서 position, upvote, comment, review를 확인하고 답글과 badge/embed를 관리할 수 있다. — [Launch Day duties](https://www.producthunt.com/launch/launch-day-duties) · 확인 2026-08-02
- 소셜, opt-in email/newsletter, LinkedIn, in-app notice, 이미 참여하던 커뮤니티와 website badge는 허용되는 홍보 채널이다. — [출시 공유](https://www.producthunt.com/launch/sharing-your-launch) · 확인 2026-08-02

### SideRefresh 실행안(전략적 추론)

1. 출시 직후 다운로드, checksum, README, English manual, issue template 링크를 다시 확인한다.
2. 다음처럼 **사용과 feedback**을 요청한다.

   > SideRefresh is live on Product Hunt. If you build personal iOS apps with coding agents, try the Mac app and tell us where the first setup becomes unclear.

3. 댓글에는 실제 요구사항과 범위를 짧고 정확하게 답한다. `Mac + Xcode + Apple Account Personal Team`, `one app + one iPhone`, `not an IPA store`, `does not remove expiration`을 숨기지 않는다.
4. 반복 질문은 같은 날 README와 FAQ에 반영하고 답글에서 변경 링크를 공유한다.
5. 점수보다 download 실패, setup 막힘, signing/connection 오류를 먼저 처리한다. Product Hunt의 가장 가치 있는 결과를 실제 사용자 피드백으로 본다.

## 8. 금지·주의 행동

### 절대 하지 말 것

- 친구·가족·사용자에게 직접 upvote를 요청하지 않는다. 링크를 알리고 토론에 참여하게 하는 것은 가능하지만 upvote 요청·압박·보상은 순위 하락이나 홈페이지 제거를 유발할 수 있다. — [Upvote 요청 정책](https://help.producthunt.com/en/articles/484935-can-i-ask-my-community-friends-family-to-upvote-a-product) · 확인 2026-08-02
- email·DM 등으로 대량 메시지를 보내 upvote를 요청하지 않는다. — [게시물 공유](https://help.producthunt.com/en/articles/2690626-how-do-i-share-my-post) · 확인 2026-08-02
- 할인, 무료 제공, giveaway, contest를 upvote와 교환하지 않는다. 조직적인 투표도 금지한다. — [게시물 공유](https://help.producthunt.com/en/articles/2690626-how-do-i-share-my-post), [출시 공유](https://www.producthunt.com/launch/sharing-your-launch) · 확인 2026-08-02
- bot, 구매 투표, vote ring, 유료 traffic promoter, 유료 Hunter를 사용하지 않는다. 이상 패턴은 자동 탐지와 수동 moderation 대상이며 무효 vote 삭제, 제품 삭제, 계정 제한으로 이어질 수 있다. — [공정 투표 정책](https://help.producthunt.com/en/articles/11869098-how-does-product-hunt-ensure-fair-voting-and-prevent-spam-or-vote-manipulation), [Community Guidelines](https://help.producthunt.com/en/articles/3615694-community-guidelines) · 확인 2026-08-02
- 다른 제품 댓글에서 SideRefresh를 홍보하지 않는다. comment self-promotion은 삭제 대상이다. — [Community Guidelines](https://help.producthunt.com/en/articles/3615694-community-guidelines) · 확인 2026-08-02
- LLM이나 확장 프로그램이 만든 댓글을 게시하지 않는다. Product Hunt는 사람 대 사람 대화를 요구하며 AI-generated comment를 명시적으로 금지한다. 일반적인 축하 문구를 대량으로 다는 것도 피한다. — [Commenting Guidelines](https://help.producthunt.com/en/articles/10030102-commenting-guidelines) · 확인 2026-08-02

### SideRefresh에 특히 중요한 운영 원칙(전략적 추론)

- 코딩 에이전트 제품이더라도 Product Hunt의 첫 댓글과 모든 답글은 maintainer가 직접 작성한다. 에이전트는 사실 확인용 초안을 도울 수 있어도 자동 게시·자동 답글은 사용하지 않는다.
- 공지 CTA에서 `Support us`보다 `Try it`, `Share your setup experience`, `Tell us what is unclear`를 쓴다.
- 동일 문구를 낯선 사람에게 복사·붙여넣기하지 않는다. 이미 관계가 있고 주제 적합성이 높은 채널에 맞춰 설명한다.

## 9. 출시 후 전략

### 공식 권장 행동

- 출시 후에도 새 comment를 확인하고 답하며, 사용자를 진정성 있게 follow-up하고 feedback을 제품 개선에 반영한다. — [Days after launch](https://www.producthunt.com/launch/days-after-launch) · 확인 2026-08-02
- Launch Page는 출시 후 약 2주 동안 계속 홍보할 수 있지만, 이후에는 제품의 launch history, review, award, news, maker를 모으는 Product Page를 장기 기준점으로 사용한다. — [Days after launch](https://www.producthunt.com/launch/days-after-launch) · 확인 2026-08-02
- Product Page는 출시 즉시 `Claim this page` 또는 `Request access to manage this page`로 관리 권한을 요청하는 것이 권장된다. — [Launch Day duties](https://www.producthunt.com/launch/launch-day-duties) · 확인 2026-08-02
- 동일 제품·동일 회사의 재출시는 원칙적으로 최소 6개월 간격과 significant update가 모두 필요하다. 새 UI나 가격 변경만으로는 부족하며, 6개월 전 재출시는 변경 내용을 제출해 별도 승인을 받아야 한다. 승인이 Featured를 보장하지 않는다. — [재출시 정책](https://help.producthunt.com/en/articles/484934-can-i-relaunch-my-product) · 확인 2026-08-02

### SideRefresh 실행안(전략적 추론)

- D+1: comment와 bug를 `설치`, `Apple signing`, `iPhone 연결`, `제품 범위`, `요청 기능`으로 분류한다.
- D+2~7: 치명적 설치 문제는 patch release와 문서 수정으로 해결하고, 답변한 사용자에게 변경 사실을 알린다.
- D+14: Launch Page 중심 공지를 줄이고 claimed Product Page와 GitHub repository/release로 유도한다.
- D+30: Product Hunt 숫자와 함께 실제 결과를 회고한다. 다음 재출시는 minor UI가 아니라 새로운 핵심 use case 또는 완전한 기능 확장이 생기고 6개월 요건을 충족할 때만 검토한다.

## 10. 성공 측정

Product Hunt는 1위만이 성공이 아니며 comment, follower, traffic, user, feedback, recognition 등 목적에 맞는 지표를 정하라고 안내한다. — [Before launch](https://www.producthunt.com/launch/before-launch) · 확인 2026-08-02

SideRefresh는 다음 순서로 본다(전략적 추론).

1. **제품 성과:** Product Hunt 유입 사용자가 실제 다운로드하고 첫 setup·Verified renewal을 완료했는가.
2. **학습 성과:** 어떤 요구사항·단계·오류 문구가 가장 많이 막혔고 개선 가능한 issue로 전환됐는가.
3. **오픈소스 성과:** release download, repository watcher/star, 유효한 bug report, 문서·코드 기여가 늘었는가.
4. **Product Hunt 성과:** 의미 있는 comment와 discussion, Product Page follower, visit, points와 award.

단순 upvote 수를 제품 성공의 최상위 지표로 두지 않는다. Product Hunt도 points가 raw upvote만으로 결정되지 않는다고 설명한다. — [Points 설명](https://help.producthunt.com/en/articles/10275873-what-are-points) · 확인 2026-08-02

## 11. 최종 Go / No-Go

아래를 모두 만족할 때만 Product Hunt 날짜를 예약한다.

- [ ] Maker 개인 프로필이 완성됐고 게시 권한이 있다.
- [ ] 제출 문구·첫 댓글·gallery·영상·답글 운영 언어가 영어다.
- [ ] GitHub 저장소가 public이고 repository description, homepage, release 이름이 `SideRefresh`로 일치한다.
- [ ] 다운로드 가능한 Developer ID 서명·공증 Mac 바이너리와 checksum이 있다.
- [ ] 깨끗한 Mac에서 Gatekeeper, 첫 실행, 앱 선택, iPhone 선택, 첫 Verified renewal을 검증했다.
- [ ] 랜딩 페이지에는 하나의 Download CTA와 Mac/Xcode/Apple Account 요구사항이 보인다.
- [ ] thumbnail 240×240, gallery 1270×760 2장 이상, 실제 demo URL이 준비됐다.
- [ ] Draft preview에서 모든 링크와 260자 이하 description을 확인했다.
- [ ] launch day에 maintainer가 장시간 실제 질문과 bug를 처리할 수 있다.
- [ ] 모든 홍보 문구가 사용·feedback을 요청하며 upvote를 요구하지 않는다.

하나라도 live product 체험과 관련해 실패하면 예약을 미룬다. Featured는 공식 기준을 충족해도 보장되지 않으므로, 출시 목적은 “순위 획득”보다 “agent app maker가 실제로 설치하고 갱신하는 첫 공개 검증”으로 둔다.

## 공식 원문 색인

모든 링크 확인일: 2026-08-02.

- [Product Hunt Launch Guide](https://www.producthunt.com/launch)
- [How Product Hunt works](https://www.producthunt.com/launch/how-product-hunt-works)
- [Before launch](https://www.producthunt.com/launch/before-launch)
- [Preparing for launch](https://www.producthunt.com/launch/preparing-for-launch)
- [Sharing your launch](https://www.producthunt.com/launch/sharing-your-launch)
- [Launch Day duties](https://www.producthunt.com/launch/launch-day-duties)
- [Days after launch](https://www.producthunt.com/launch/days-after-launch)
- [How to post a product](https://help.producthunt.com/en/articles/479557-how-to-post-a-product)
- [How can I get access to post?](https://help.producthunt.com/en/articles/481909-how-can-i-get-access-to-post)
- [Personal account vs company account](https://help.producthunt.com/en/articles/771527-personal-account-vs-company-account)
- [How to schedule a post](https://help.producthunt.com/en/articles/2724119-how-to-schedule-a-post)
- [Where did Launch Now go?](https://help.producthunt.com/en/articles/9823193-where-did-launch-now-go)
- [How to share a scheduled launch](https://help.producthunt.com/en/articles/15706445-how-to-share-a-scheduled-launch)
- [Product Hunt Featuring Guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines)
- [Community Guidelines](https://help.producthunt.com/en/articles/3615694-community-guidelines)
- [Commenting Guidelines](https://help.producthunt.com/en/articles/10030102-commenting-guidelines)
- [How do I share my post?](https://help.producthunt.com/en/articles/2690626-how-do-i-share-my-post)
- [Can I ask my community/friends/family to upvote a product?](https://help.producthunt.com/en/articles/484935-can-i-ask-my-community-friends-family-to-upvote-a-product)
- [How does Product Hunt ensure fair voting?](https://help.producthunt.com/en/articles/11869098-how-does-product-hunt-ensure-fair-voting-and-prevent-spam-or-vote-manipulation)
- [What are points?](https://help.producthunt.com/en/articles/10275873-what-are-points)
- [How is the homepage ranked?](https://help.producthunt.com/en/articles/484938-how-is-the-homepage-ranked)
- [Product of the Day, Week, & Month](https://help.producthunt.com/en/articles/11751186-product-of-the-day-week-month)
- [Can I submit an unreleased product?](https://help.producthunt.com/en/articles/484932-can-i-submit-an-unreleased-product)
- [Why was my comment or post removed?](https://help.producthunt.com/en/articles/3539992-why-was-my-comment-or-post-removed)
- [Why is my post not on the homepage?](https://help.producthunt.com/en/articles/484926-why-is-my-post-not-on-the-homepage)
- [Hunter vs Makers](https://help.producthunt.com/en/articles/10082986-hunter-vs-makers-and-how-to-change-them)
- [Can I relaunch my product?](https://help.producthunt.com/en/articles/484934-can-i-relaunch-my-product)
