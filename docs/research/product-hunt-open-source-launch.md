# SideRefresh 오픈소스 × Product Hunt 출시 조사

> 라이선스 정책 변경: 이 문서의 MIT 상태와 체크리스트는 조사 당시 기록이다.
> `v0.2.0-beta.2`부터 적용되는 Apache-2.0 및 브랜드 경계는
> [ADR 0001](../adr/0001-apache-2-license-and-brand-boundary.md)이 대체한다.

> 현재 제출 문구와 Go/No-Go 상태는
> [Product Hunt launch kit](../PRODUCT-HUNT.md)과
> [한국어 출시 자료](../PRODUCT-HUNT.ko.md)를 기준으로 합니다. 이 문서는
> 조사 근거와 출처를 보존합니다.

- 조사일: 2026-07-31
- 범위: Product Hunt, GitHub, Apple의 공식 문서와 조사 당시 저장소 상태
- 결론: **Product Hunt 출시는 적합하다. 다만 지금 바로 제출하지 말고, 공개 GitHub 저장소와 서명·공증된 macOS 실행 파일을 먼저 준비한 뒤 출시한다.**

## 판단

SideRefresh는 “AI 코딩 에이전트가 만든 개인용 iOS 앱을 내 iPhone에서 계속 사용한다”는 새롭고 설명 가능한 문제를 해결한다. Product Hunt가 공식적으로 설명하는 이용자층도 early adopter, maker, tech user에 가깝고, 제품을 출시하는 목적에 피드백·아이디어 검증·사용자 확보가 포함된다. 따라서 채널 적합성은 높다. [Product Hunt가 작동하는 방식](https://www.producthunt.com/launch/how-product-hunt-works)

그러나 Product Hunt는 현재 사용할 수 있는 **live product**를 우선하며, waitlist나 vaporware는 홈페이지 노출 대상에서 제외할 수 있다. 소스만 공개하고 사용자가 직접 빌드해야 하는 상태보다, 다운로드하여 실제로 실행할 수 있는 앱이 훨씬 강한 출시 조건이다. [2026 Product Hunt featuring 기준](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines), [미출시 제품 안내](https://help.producthunt.com/en/articles/484932-can-i-submit-an-unreleased-product)

따라서 출시 게이트는 다음 세 가지다.

1. 누구나 읽고 포크할 수 있는 공개 GitHub 저장소
2. Developer ID로 서명하고 Apple에 공증한 다운로드 가능한 SideRefresh macOS 앱
3. 새 사용자가 `Agent가 만든 앱 1개 → iPhone 1대 → 첫 설치 → 자동 갱신`을 완료할 수 있는 검증된 온보딩

## 2026-07-31 역사적 저장소 스냅샷

2026-07-31에 비공개 개발 저장소를 읽기 전용으로 확인했다. 아래 표는 현재
공개 소스 후보가 아니라 공개 방식을 결정한 역사적 입력이다.

| 항목 | 조사 당시 상태 | 공개 후보 처리 |
| --- | --- | --- |
| 저장소 | 비공개 개발 저장소 | 검토한 트리만 새 단일 커밋으로 공개하고 개발 그래프는 별도 보관 |
| 라이선스 | GitHub가 MIT로 인식, 루트 `LICENSE` 존재 | 유지 가능 |
| 커뮤니티 파일 | 일부만 존재 | Code of Conduct, Support, 이슈·PR 템플릿을 공개 후보에 추가 |
| 저장소 메타데이터 | 설명, 홈페이지, topics 없음 | 공개 전환 시 설명과 topics를 설정; 홈페이지는 안정 바이너리까지 보류 |
| 최신 릴리스 | 비공개 전신의 소스 전용 `v0.1.0` | 공개 저장소로 복사하지 않고 첫 공개 릴리스를 새로 생성 |
| 다운로드 | 소스 ZIP/TAR만 있고 `.app`, ZIP, DMG 자산 없음 | 서명·공증된 실행 파일과 체크섬 첨부 |
| CI | 기본 검증만 존재 | 공개 소스·Swift·샘플·Headless·자산·사이트 검증을 공개 후보에 포함 |

GitHub는 기존 저장소의 visibility를 바꾸면 코드와 Actions 이력·로그가 모두
공개되고 누구나 fork할 수 있다고 경고한다. SideRefresh는 그 위험을 피하기 위해
검토한 트리만 새 저장소에 게시한다. [저장소 공개 전환의 결과](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility)

## 권장 출시 순서

### 1. 제품 약속을 구현·검증한다

첫 공개 버전의 약속을 다음으로 고정한다.

> Agent가 만든 개인용 iOS 앱을 내 iPhone에 설치하고, Personal Team 프로파일이 만료되기 전에 다시 빌드·서명·설치한다.

첫 버전은 앱 1개와 iPhone 1대로 제한하고, Mac·Xcode·Apple Account 로그인이 필요하다는 조건을 숨기지 않는다. Apple 공식 문서에 따르면 프로그램 멤버십이 없는 Apple Account는 Xcode에서 Personal Team으로 표시되며, 프로비저닝 프로파일은 발급 7일 후 만료되고 다시 빌드·설치해야 한다. 기기당 앱은 최대 3개다. [Apple Personal Team 제한](https://developer.apple.com/help/account/basics/about-your-developer-account)

완료 기준:

- 처음 연결하는 Mac과 iPhone에서 설치 성공
- 7일 만료를 기다리지 않고도 동일한 재서명·재설치 경로를 테스트 가능
- 실패 원인과 복구 행동이 앱에서 명확함
- 새 Mac 사용자 기준 설치·권한·제거 문서가 있음

### 2. GitHub 공개 준비를 완료한다

GitHub는 README에 프로젝트가 하는 일, 유용한 이유, 시작 방법, 도움받는 곳, 유지관리자를 설명하도록 권장한다. 공개 저장소의 Community Profile은 README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, 이슈 템플릿 등을 점검한다. [README 공식 안내](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes), [Community Profile 공식 안내](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)

공개 전 체크리스트:

- [ ] Git 전체 이력과 Actions 로그에서 비밀정보·인증서·Apple Account·UDID 제거
- [ ] 제품명 `SideRefresh`로 앱, 실행 파일, README, 릴리스 제목 통일
- [ ] README 첫 화면에 문제, 3단계 사용법, 30–60초 데모, 요구사항, 다운로드 버튼 배치
- [ ] `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, Code of Conduct, 이슈 템플릿 정비
- [ ] 지원 버전과 보안 취약점의 비공개 신고 경로 명시
  [GitHub 보안 정책 안내](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/add-security-policy)
- [ ] 저장소 설명·홈페이지·topics 추가
  GitHub topics는 발견과 기여를 돕고 최대 20개까지 허용한다. [GitHub topics 안내](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics)
- [ ] 1280×640 소셜 미리보기 이미지 추가
  GitHub의 권장 최소 크기는 640×320, 최적 크기는 1280×640이고 파일은 1MB 미만이다. [GitHub 소셜 미리보기 안내](https://docs.github.com/en/enterprise-cloud@latest/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview)
- [ ] 저장소를 PUBLIC으로 변경한 뒤 Community Profile과 모든 링크 재확인

권장 topics 후보:

`ios`, `macos`, `swift`, `swiftui`, `xcode`, `personal-team`, `developer-tools`, `ai-coding`, `claude-code`, `codex`, `open-source`

### 3. 신뢰할 수 있는 macOS 릴리스를 배포한다

여기에는 중요한 구분이 있다.

- **SideRefresh 사용자:** 유료 Apple Developer Program 없이 Personal Team으로 자신의 iOS 앱을 설치·갱신할 수 있다.
- **SideRefresh 배포자:** 다운로드한 macOS 앱이 Gatekeeper를 정상 통과하도록 배포하려면 Developer ID가 필요하며, Developer ID는 Apple Developer Program 또는 Enterprise Program 멤버에게만 발급된다. [Apple Developer ID 자격](https://developer.apple.com/help/glossary/developer-id-certificate/), [Developer ID 배포 안내](https://developer.apple.com/support/developer-id/)

Apple은 Mac App Store 밖에서 배포하는 소프트웨어를 Developer ID로 서명하고 공증하도록 안내한다. macOS 10.15 이후에는 2019-06-01 이후 빌드된 Developer ID 소프트웨어에 공증이 필요하며, 현재 공증은 `notarytool` 또는 Xcode 14 이상을 사용해야 한다. [Apple macOS 공증 안내](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution), [직접 배포 안내](https://developer.apple.com/documentation/technologyoverviews/distribution)

릴리스 게이트:

- [ ] 프로젝트 배포자가 Apple Developer Program에 가입
- [ ] Developer ID Application 인증서로 앱과 포함 실행 파일 서명
- [ ] Hardened Runtime 적용
- [ ] ZIP 또는 DMG를 Apple 공증하고 ticket staple
- [ ] 깨끗한 Mac 계정에서 다운로드 → Gatekeeper → 첫 실행 검증
- [ ] 태그 기반 GitHub Release 초안을 만들고 앱, 체크섬, 설치·제거법, 알려진 제한 첨부

GitHub Release는 태그, 릴리스 노트와 바이너리 파일을 함께 제공할 수 있다. GitHub는 자산을 모두 붙인 뒤 게시할 수 있도록 draft release 사용을 안내한다. [GitHub Release 관리](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)

추가 권장 사항:

- GitHub Actions에서 빌드 provenance attestation을 생성한다. 공개 저장소에서는 모든 현재 GitHub 요금제에서 사용할 수 있으며, 사용자는 `gh attestation verify`로 출처를 확인할 수 있다. 다만 attestation은 안전성 자체를 보장하지 않고 빌드 출처와 절차를 증명한다. [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
- Product Hunt 제출 전 최소 5–10명의 실제 Agent app maker에게 서명·설치·갱신 흐름을 테스트하게 한다. 이는 공식 요구사항이 아니라, “즉시 사용 가능한 제품” 조건을 확인하기 위한 이 조사상의 권장 사항이다.

### 4. GitHub를 먼저 공개하고 짧게 소프트 런칭한다

권장 기간은 Product Hunt 제출 전 약 1–2주다. 이 기간에 다음 증거를 확보한다.

- README만 보고 설치에 성공하는가
- Claude Code, Codex 또는 Cursor로 만든 실제 Xcode 프로젝트를 연결할 수 있는가
- 어떤 문구에서 사용자가 “유료 개발자 등록이 필요 없다”를 잘못 이해하는가
- 첫 설치와 재갱신에서 가장 빈번한 실패는 무엇인가
- Product Hunt gallery에 쓸 실제 화면과 짧은 사용 영상

이 기간은 별도의 대형 홍보가 아니라 다운로드와 문서의 치명적인 문제를 잡기 위한 공개 베타다.

### 5. Product Hunt 제출물을 준비한다

2026년 공식 제출 조건과 권장값:

| 항목 | 현재 공식 안내 | SideRefresh 준비안 |
| --- | --- | --- |
| 계정 | 개인 계정이 필요하며 회사 계정은 게시할 수 없음. 새 계정은 onboarding을 완료해야 하고 기본 게시 권한은 계정 생성 1주 뒤 제공됨 | maker 본인의 실명·사진·소개가 있는 계정을 최소 1주 전에 준비 |
| Hunter | 별도 Hunter가 필요 없고 직접 제출 권장 | maker가 직접 제출 |
| 제품 URL | 제품/다운로드로 직접 연결. GitHub 저장소도 허용. 단축·추적 URL은 불가 | 가능하면 간결한 랜딩페이지를 기본 URL로, 공개 GitHub와 Release를 추가 링크로 제공 |
| 이름 | 설명이나 emoji 없이 제품명만 | `SideRefresh` |
| 언어 | 게시물은 영어여야 하며 비영어 게시물은 제거될 수 있음 | 제목·설명·gallery·첫 댓글을 영어로 준비 |
| Tagline | 최대 60자 | 아래 초안 사용 |
| 설명 | 공식 페이지끼리 260자와 500자 안내가 혼재 | 최신 게시 도움말의 보수적 제한인 260자 안으로 작성하고 실제 제출 UI에서 최종 확인 |
| 태그 | 강하게 관련된 launch tag를 최대 3개 | Open Source, Developer Tools, Artificial Intelligence 계열 중 실제 UI에서 정확한 명칭 선택 |
| Thumbnail | 필수 정사각형, 240×240 권장. GIF는 3MB 미만 | 앱 아이콘 기반 정지 PNG |
| Gallery | 1270×760 권장, 2개 이상이어야 표시 | 문제 → 설정 → 정상 갱신 흐름 4–5장 |
| 영상 | YouTube 전체 URL만 지원, private 영상 불가 | 45–75초 실제 데모 권장 |
| Makers | Product Hunt username으로 추가 | 기여자가 있으면 계정을 출시 전에 생성 |
| 가격 | free / paid / paid with free plan 중 선택 | `Free` |
| 첫 댓글 | maker의 첫 댓글을 강하게 권장 | 배경, 대상 사용자, 동작, 제한, 원하는 피드백 포함 |
| 예약 | `Launch Now`는 제거됐으며 draft 또는 현재 날짜로부터 30일 이내 예약을 사용 | 자산과 다운로드 검증 후 예약 |

출처: [Product Hunt 게시 방법](https://help.producthunt.com/en/articles/479557-how-to-post-a-product), [새 계정 게시 권한](https://help.producthunt.com/en/articles/481909-how-can-i-get-access-to-post), [게시물 제거 기준](https://help.producthunt.com/en/articles/3539992-why-was-my-comment-or-post-removed), [Product Hunt 출시 준비와 콘텐츠 체크리스트](https://www.producthunt.com/launch/preparing-for-launch), [2026 예약 방법](https://help.producthunt.com/en/articles/2724119-how-to-schedule-a-post), [Launch Now 제거 안내](https://help.producthunt.com/en/articles/9823193-where-did-launch-now-go)

#### 추천 제출 문구

Product name:

> SideRefresh

Tagline 초안:

> Keep agent-built iOS apps alive on your iPhone

Description 초안:

> SideRefresh is an open-source Mac app that installs iOS projects made with Claude Code, Codex, or Cursor using Xcode Personal Team, then rebuilds, signs, and reinstalls them before the 7-day profile expires. Mac, Xcode, and an Apple Account are required.

이 문구는 실제 첫 설치와 자동 갱신이 구현·검증된 뒤 사용한다. “No developer account required”는 Apple Account조차 필요 없다는 오해를 만들 수 있으므로 피하고, **“No paid Apple Developer Program required for your personal iOS app”**처럼 정확히 쓴다.

Gallery 권장 순서:

1. Hero — “Your agent builds it. SideRefresh keeps it running.”
2. 문제 — Personal Team 앱은 7일 후 재프로비저닝 필요
3. 흐름 — Xcode project → SideRefresh → iPhone
4. 단순 대시보드 — 현재 상태, 다음 갱신, 한 가지 주요 행동
5. Open source — GitHub, 로컬 실행, 데이터 처리와 권한 설명

첫 댓글 구성:

1. 왜 만들었는지: Agent가 개인용 앱을 만들 수 있지만 7일 갱신이 반복됨
2. 누구를 위한 것인지: Mac·Xcode가 있고 App Store 배포 없이 자기 앱을 쓰는 사람
3. 오늘 가능한 것: 첫 설치와 만료 전 자동 재빌드·서명·재설치
4. 정직한 제한: 앱 1개 × iPhone 1대, Personal Team, Mac/Xcode 필요
5. 묻고 싶은 것: 온보딩에서 막힌 지점과 다음에 지원할 Agent/작업 흐름

### 6. Launch day를 운영한다

Product Hunt는 준비에 특별한 제약이 없다면 **12:01 a.m. Pacific Time** 출시를 권장한다. 이는 24시간 노출을 확보하기 위한 권장값일 뿐, 공식 안내도 팀이 대응 가능한 시간과 목표가 더 중요하다고 설명한다. [출시 시간 공식 안내](https://www.producthunt.com/launch/preparing-for-launch)

출시 당일:

- 제품 다운로드, GitHub Release, README와 지원 채널을 실시간으로 확인
- 질문과 실제 버그에 빠르게 답변
- 소셜 미디어와 이미 활동하던 관련 커뮤니티에 링크를 자연스럽게 공유
- “방문해서 사용해보고 의견을 달라”고 요청
- FAQ와 README를 반복 질문에 맞춰 당일 수정

하지 말아야 할 것:

- upvote를 직접 요청
- 대량 DM·이메일 발송
- 할인·보상과 upvote 교환
- 조직적인 투표
- 봇·구매한 트래픽 사용

Product Hunt는 points가 단순 upvote 수가 아니라 댓글 등 진정성 있는 참여 신호를 포함한다고 설명하며, 위 행위는 순위 하락·홈페이지 제거·계정 제한을 유발할 수 있다. [공유 정책](https://help.producthunt.com/en/articles/2690626-how-do-i-share-my-post), [Community Guidelines](https://help.producthunt.com/en/articles/3615694-community-guidelines), [2025 points 설명](https://help.producthunt.com/en/articles/10275873-what-are-points)

## 주요 위험과 대응

| 위험 | 영향 | 대응 |
| --- | --- | --- |
| 소스 전용 출시 | 비개발 사용자가 제품을 체험하지 못해 live product·high craft 인상이 약해짐 | 공증된 실행 파일을 Product Hunt의 출시 게이트로 지정 |
| “개발자 등록 불필요” 과장 | Apple Account/Xcode 요구사항을 숨기고 정책 우회 도구처럼 보일 수 있음 | 무료 Personal Team과 유료 Developer Program을 정확히 구분 |
| Gatekeeper 경고 | 첫 실행 신뢰와 전환율 하락 | 프로젝트 배포자가 유료 멤버십으로 Developer ID 서명·Apple 공증 |
| 비공개 개발 이력 노출 | 코드, 전체 이력, Actions 로그와 실수가 공개됨 | 검토한 트리만 새 단일 커밋으로 공개하고 전신 저장소를 비공개로 보관 |
| 강한 시스템 권한 | Xcode 프로젝트, 서명, iPhone 설치를 다루므로 보안 우려가 큼 | 로컬 처리 범위, 명령, 저장 데이터, 진단 정보, 제거법을 문서화 |
| 공개 자료의 명칭 불일치 | 저장소·앱·릴리스가 다른 제품처럼 보임 | Product Hunt 전 모든 공개 자료를 SideRefresh로 통일 |
| Product Hunt 정책 위반 | 노출 제거 또는 계정 제한 | upvote 대신 사용·댓글·피드백만 요청 |
| 한 번의 출시 과대평가 | 홈페이지 노출이나 순위는 보장되지 않음 | 성공 기준을 다운로드, 설치 성공, GitHub star, 이슈 품질, 유지 사용자로 별도 정의 |
| 너무 이른 재출시 | 동일 제품 재출시는 일반적으로 6개월 간격과 유의미한 변경이 필요 | 첫 제출을 실제 실행 가능한 핵심 버전에 사용 |

Product Hunt는 기준을 충족하고 참여를 얻어도 홈페이지 노출을 보장하지 않는다. 같은 제품을 다시 출시하려면 일반적으로 최소 6개월과 의미 있는 기능 변화가 필요하다. [홈페이지 선정 안내](https://help.producthunt.com/en/articles/484923-how-do-things-end-up-on-the-homepage), [재출시 정책](https://help.producthunt.com/en/articles/484934-can-i-relaunch-my-product)

## 최종 Go / No-Go 체크리스트

다음이 모두 참이면 Product Hunt 날짜를 예약한다.

- [ ] GitHub 저장소가 PUBLIC이고 비밀정보 감사 완료
- [ ] README 첫 화면에서 10초 안에 문제·대상·다운로드를 이해 가능
- [ ] SideRefresh 명칭이 앱·저장소·릴리스·화면에서 일치
- [ ] MIT 라이선스와 기여·보안·행동강령 문서 준비
- [ ] Developer ID 서명·Apple 공증된 Mac 다운로드 제공
- [ ] 깨끗한 Mac에서 Gatekeeper와 설치 검증 완료
- [ ] Agent 앱 1개 × iPhone 1대의 첫 설치 및 갱신 성공
- [ ] Personal Team의 7일 만료와 Mac/Xcode/Apple Account 요구사항을 명시
- [ ] Product Hunt thumbnail, gallery 2장 이상, 설명, 첫 댓글 준비
- [ ] maker 개인 계정과 공동 maker 계정 준비
- [ ] launch day 질문·버그 대응 시간 확보

한 항목이라도 제품 체험이나 다운로드 신뢰와 관련해 실패하면 Product Hunt는 연기한다. GitHub 공개 자체는 그보다 먼저 진행해 초기 사용자의 실제 설치 문제를 수집하는 편이 좋다.

## 공식 출처 요약

### Product Hunt

- [Launch Guide](https://www.producthunt.com/launch)
- [How Product Hunt works](https://www.producthunt.com/launch/how-product-hunt-works)
- [Preparing for launch](https://www.producthunt.com/launch/preparing-for-launch)
- [How to post a product](https://help.producthunt.com/en/articles/479557-how-to-post-a-product)
- [Posting access](https://help.producthunt.com/en/articles/481909-how-can-i-get-access-to-post)
- [Featuring Guidelines, 2026-03-10](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines)
- [How to schedule a post, 2026-02-02](https://help.producthunt.com/en/articles/2724119-how-to-schedule-a-post)
- [Where did Launch Now go?](https://help.producthunt.com/en/articles/9823193-where-did-launch-now-go)
- [Community Guidelines](https://help.producthunt.com/en/articles/3615694-community-guidelines)

### GitHub

- [Licensing a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)
- [About README files](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes)
- [Community Profile](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)
- [Setting repository visibility](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility)
- [Managing releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
- [Artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)

### Apple

- [Personal Team 계정과 7일 제한](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Developer ID](https://developer.apple.com/support/developer-id/)
- [macOS software notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Direct distribution](https://developer.apple.com/documentation/technologyoverviews/distribution)
