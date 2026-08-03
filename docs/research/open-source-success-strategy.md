# SideRefresh 오픈소스 성공 전략

> 조사 기준일: 2026-07-30
>
> 근거 범위: SideRefresh 저장소, Apple 공식 문서, GitHub 공식 저장소·REST API·문서,
> 각 프로젝트의 공식 문서, Homebrew 공식 정책, OpenSSF 공식 기준만 사용했다.
>
> 표기 원칙: 링크로 확인할 수 있는 내용은 **근거**, SideRefresh에 적용한 판단은
> **추론**, 앞으로 달성할 수치는 **목표**로 구분한다.

## 1. 결론

SideRefresh의 성공 가능성은 “또 하나의 사이드로딩 앱”이 되는 데 있지 않다.
다음 한 가지 결과를 가장 안전하고 투명하게 제공하는 데 있다.

> **Keep your own Xcode-built iOS app running on your iPhone.**
>
> SideRefresh rebuilds, signs, and reinstalls your app before a Personal Team
> profile expires, without collecting your Apple password.

한국어로는 다음처럼 설명한다.

> **내 Xcode 앱을 내 iPhone에서 계속 실행하세요.**
>
> SideRefresh는 Personal Team 프로파일이 만료되기 전에 현재 소스를 다시 빌드,
> 서명, 설치하며 Apple 비밀번호를 수집하지 않습니다.

**근거:** Apple은 무료 Personal Team의 프로비저닝 프로파일이 발급 후 7일에
만료되며 앱을 다시 빌드하고 설치해야 한다고 명시한다.
[Apple 개발자 계정 안내](https://developer.apple.com/help/account/basics/about-your-developer-account)

**추론:** SideRefresh의 방어 가능한 범주는 **Personal Team용 자기 소스 갱신
오케스트레이터**다. AltStore·SideStore의 IPA 카탈로그와 계정 기반 재서명,
fastlane의 범용 배포 자동화와 직접 경쟁하지 않는다.

성공 전략은 세 축으로 압축된다.

1. **신뢰:** 소스 공개, 비밀번호 비수집, dry-run, 정확한 성공 증거를 보여준다.
2. **활성화:** 소스 빌드가 아닌 Developer ID 서명·공증 앱으로 첫 성공 시간을
   줄인다.
3. **반복 성공:** 별보다 “같은 사용자가 8일 뒤 두 번째 갱신에 성공했는가”를
   핵심 지표로 삼는다.

## 2. 조사 당시 출발점과 공개 후보 처리

### 2026-07-30 감사 스냅샷

- 비공개 전신 저장소에는 공개 별·포크·이슈가 없었다.
- 전신 저장소의 `v0.1.0`은 소스 전용이었고 설치 가능한 바이너리가 없었다.
- README, MIT 라이선스, CONTRIBUTING, SECURITY는 있었지만 Code of Conduct,
  issue form, PR template은 없었다.
  [GitHub community profile 기준](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)
- 현재 배포는 소스 빌드와 ad-hoc 서명이며 Developer ID 릴리스는 계획 상태다.
  [SideRefresh 배포 문서](../DISTRIBUTION.md)
- USB 실기기 갱신은 검증됐지만 순수 셀룰러 Tailnet 경로는 검증되지 않았다.
  한 설정당 iOS 앱 대상 하나를 지원한다.
  [SideRefresh 구현 상태](../STATUS.md)

### 2026-08-03 공개 후보 업데이트

- 공개 후보는 비공개 개발 이력·태그·Actions 로그를 복사하지 않는 새 단일
  커밋으로 구성한다.
- Code of Conduct, Support, 이슈 양식, PR 템플릿, 의존성 업데이트 설정과
  공개 소스 검사를 포함한다.
- 설치 가능한 Developer ID 서명·공증 바이너리는 여전히 출시 게이트다.

### 전략적 진단

**추론:** 현재 제품은 “공개할 코드”는 갖췄지만 “처음 보는 사람이 설치하고,
8일 동안 신뢰할 제품”은 아직 아니다. 공개 전환 자체보다 설치 가능한 신뢰
자산과 실제 8일 사용 증거가 우선이다.

**추론:** MCP·CLI는 개발자와 AI 사용자의 확장 채널로 강점이 있지만 첫 방문자의
핵심 진입점이 되어서는 안 된다. 첫 화면과 README는 macOS 앱의 사용자 결과를
먼저 설명하고, CLI·MCP는 두 번째 경로로 둔다.

## 3. 검색 의도와 발견 전략

검색어는 중요하다. SideRefresh가 쓰는 제품 언어와 사용자가 문제를 설명하는
언어가 다르기 때문이다.

### 관찰 가능한 실제 표현

**근거:** 공식 GitHub Search API에서 각 저장소의 issue 제목을 조사하면
`renewal`보다 `refresh`가 압도적으로 많이 쓰인다.

| 저장소 issue 제목 | `refresh` | `renewal` |
| --- | ---: | ---: |
| AltStore | [50](https://api.github.com/search/issues?q=repo%3Aaltstoreio%2FAltStore+refresh+in%3Atitle+is%3Aissue) | [2](https://api.github.com/search/issues?q=repo%3Aaltstoreio%2FAltStore+renewal+in%3Atitle+is%3Aissue) |
| SideStore | [120](https://api.github.com/search/issues?q=repo%3ASideStore%2FSideStore+refresh+in%3Atitle+is%3Aissue) | [0](https://api.github.com/search/issues?q=repo%3ASideStore%2FSideStore+renewal+in%3Atitle+is%3Aissue) |

이 수치는 2026-07-29 스냅샷이며 새 issue가 생기면 바뀐다. 제목에 단어가
있다는 뜻이지, 그 단어의 검색량을 뜻하지 않는다.

**근거:** GitHub 공개 저장소 검색도 같은 방향을 보인다.

| 저장소 검색 문구 | 일치 저장소 |
| --- | ---: |
| `ios app refresh` | [118](https://api.github.com/search/repositories?q=ios%20app%20refresh) |
| `ios app renewal` | [13](https://api.github.com/search/repositories?q=ios%20app%20renewal) |
| `personal team xcode` | [1](https://api.github.com/search/repositories?q=personal%20team%20xcode) |
| `ios sideload` | [128](https://api.github.com/search/repositories?q=ios%20sideload) |
| `xcode mcp` | [186](https://api.github.com/search/repositories?q=xcode%20mcp) |

**근거:** GitHub의 `code-signing` topic에는 66개 공개 저장소가 있지만 Swift는
2개뿐이다. GitHub는 topic이 특정 분야의 저장소와 해결책을 발견하고 기여하는
데 사용된다고 설명한다.
[GitHub code-signing topic](https://github.com/topics/code-signing)
[GitHub topic 안내](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics)

**근거:** Apple Developer Forums의 `Provisioning Profiles` tag에는 87개 글이
있다. “Renew iOS Apple Provisioning Profile” 글은 18,000회, “free developer
account” 글은 69,000회 조회됐다. 후자의 대화도 `active for 7 days`,
`re-sign`, `re-sideload`라는 표현을 쓴다.
[Apple Provisioning Profiles forum](https://developer.apple.com/forums/tags/provisioning-profiles)
[프로파일 갱신 질문](https://developer.apple.com/forums/thread/725102)
[무료 계정 7일 질문](https://developer.apple.com/forums/thread/71283)

**근거:** Apple의 공식 표현은 `Personal Team`, `expire after 7 days`,
`rebuild and reinstall`이다.
[Apple 개발자 계정 안내](https://developer.apple.com/help/account/basics/about-your-developer-account)

### 의도별 권장 키워드

#### 1. 문제 인지 검색

사용자는 제품 범주를 모르고 증상을 그대로 검색한다.

- `iOS app expires after 7 days`
- `Xcode Personal Team app expires`
- `free developer account 7 days`
- `provisioning profile expired iPhone app`
- `keep personal iOS app running`
- `reinstall iOS app every 7 days`
- 한국어 지원 문구: `아이폰 개발자 앱 7일 만료`, `Xcode Personal Team 만료`,
  `iOS 앱 매주 재설치`

**추론:** 가장 가치가 높은 초기 유입은 `sideloading`보다 이 문제 검색이다.
자기 소스를 가진 사용자를 더 정확히 걸러내고 SideRefresh의 신뢰 경계와 맞는다.

#### 2. 해결책·범주 검색

- `refresh iOS app`
- `automatic iOS app refresh`
- `Xcode app auto reinstall`
- `Personal Team app renewal`
- `provisioning profile renewal macOS`
- `xcodebuild devicectl install`
- `iOS source build automation`

**추론:** 제품 안에서는 `renewal`을 계속 써도 된다. 다만 제목, 설명, 가이드에는
사용자가 더 많이 쓰는 `refresh`, Apple이 쓰는 `expire`, `rebuild`,
`reinstall`을 함께 사용해야 한다.

`iOS sideloading`은 인접 범주 발견에는 유용하지만 IPA 도구를 찾는 사용자가
많이 섞인다. 홈페이지에서는 “not an IPA sideloader”를 바로 밝혀 잘못된
기대를 줄인다.

#### 3. 브랜드·경쟁 제품 검색

- `SideRefresh`
- `SideRefresh Personal Team`
- `SideRefresh vs AltStore`
- `SideRefresh vs SideStore`
- `AltStore alternative for my own Xcode project`
- `SideStore source rebuild alternative`

**추론:** 경쟁 브랜드를 저장소 topic이나 제품명에 억지로 넣지 않는다. 대신
사실 기반 비교 문서 한 장에서 입력, 계정 처리, Mac 필요 여부, 자동화 방식,
대상 사용자를 공정하게 설명한다.

SideRefresh라는 브랜드 검색은 공개 전에는 거의 존재하지 않는 것이 정상이다.
비브랜드 문제 검색으로 발견된 사용자가 성공한 뒤에야 브랜드 검색이 따라온다.

### 키워드와 콘텐츠 매핑

| 사용자 의도 | 페이지 | 제안 제목 |
| --- | --- | --- |
| 7일 뒤 앱 만료 | 핵심 가이드 | `Why Xcode Personal Team apps expire after 7 days` |
| 계속 실행하고 싶음 | 홈페이지 | `Keep your own Xcode-built iOS app running` |
| refresh 방법 탐색 | 사용 가이드 | `Refresh an iOS app from its Xcode source` |
| 서명 오류 | 문제 해결 | `Provisioning profile expired: verify, rebuild, reinstall` |
| 대안 비교 | 비교 문서 | `SideRefresh vs AltStore and SideStore` |
| 자동화 통합 | 기술 문서 | `Automate xcodebuild and devicectl with SideRefresh CLI/MCP` |
| 브랜드 탐색 | README·릴리스 | `SideRefresh — renewal companion for apps built for iOS` |

저장소 About 설명은 다음처럼 문제와 결과를 함께 쓴다.

> Refresh your own Xcode-built iOS apps before Personal Team profiles expire.

권장 GitHub topics는 `ios`, `macos`, `swift`, `xcode`, `xcodebuild`,
`personal-team`, `provisioning-profile`, `code-signing`, `developer-tools`,
`ios-development`, `app-refresh`, `mcp`다.

`ipa`, `app-store`, `jailbreak`는 실제 범위가 아니므로 발견을 위해 추가하지
않는다.

### 검색량을 정확히 안다고 말할 수 없는 이유

GitHub Search API의 `total_count`는 GitHub에 색인된 공개 issue·저장소의
일치 개수다. 사람들이 그 문구를 몇 번 검색했는지는 알려주지 않는다.

Apple Forums의 글 수와 조회 수도 문제 언어와 관심의 방향을 보여줄 뿐, 월간
검색량이나 고유 사용자를 제공하지 않는다.

Google Keyword Planner의 예측은 과거 검색 데이터와 계정·지역·예산 조건을
사용한 추정치다.
[Google Keyword Planner](https://support.google.com/google-ads/answer/3022575)

공개 사이트 출시 후에는 Google Search Console에서 실제로 SideRefresh 페이지가
노출된 query별 impression, click, CTR과 위치를 확인한다.
[Search Console Performance](https://support.google.com/webmasters/answer/7576553)

Search Console도 개인정보 보호를 위해 일부 query를 익명 처리하고 중요 행만
보여주므로 전체 시장 검색량은 아니다.
[Search Console query 한계](https://support.google.com/webmasters/answer/17011259)

따라서 실행 순서는 다음과 같다.

1. 출시 전 Keyword Planner와 Google Trends에서 미국·한국을 분리해 후보를
   재검증한다.
2. 영문 문제 가이드를 우선 색인하고 한국어 문서는 같은 정보 구조로 제공한다.
3. 출시 후 Search Console에서 비브랜드·브랜드 query의 impression과 CTR을
   매주 확인한다.
4. 100회 이상 impression이 쌓인 문구부터 제목과 설명을 실험한다.
5. 유입이 아니라 Configuration Test와 8일 재갱신까지 연결되는 키워드를
   유지한다.

**추론:** 현재 공개 개발자 자료는 영어 표현과 표본이 훨씬 선명하고 한국어
검색 결과는 범용 사이드로딩 정보와 섞이기 쉽다. 초기 획득 콘텐츠는
English-first로 운영하고 한국어 문서는 온보딩·지원 품질에 사용한다.

## 4. 인접 프로젝트의 현재 신호

아래 수치는 조사 시점 GitHub REST API 스냅샷이다. `open_issues_count`는 열린
issue와 pull request를 합친 값이다. 기여자 수는 anonymous를 포함한
contributors endpoint의 페이지 수로 계산했다.

별과 포크는 인지도·생태계 활동의 참고치일 뿐 실제 활성 사용자 수가 아니다.

| 프로젝트 | 별 | 포크 | 열린 issue+PR | 기여자 | 최근 12개월 릴리스 | 최신 릴리스 |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| [AltStore](https://api.github.com/repos/altstoreio/AltStore) | 14,105 | 1,365 | 671 | 12 | 0 | GitHub Release 없음 |
| [SideStore](https://api.github.com/repos/SideStore/SideStore) | 5,961 | 406 | 80 | 50 | 1 | [0.6.3, 2026-05-05](https://github.com/SideStore/SideStore/releases/tag/0.6.3) |
| [RebuildMe](https://api.github.com/repos/AryanRogye/RebuildMe) | 0 | 0 | 0 | 1 | 0 | 없음 |
| [fastlane](https://api.github.com/repos/fastlane/fastlane) | 41,903 | 6,022 | 700 | 1,682 | 15 | [2.237.0, 2026-07-05](https://github.com/fastlane/fastlane/releases/tag/2.237.0) |
| [XcodeBuildMCP](https://api.github.com/repos/getsentry/XcodeBuildMCP) | 6,165 | 302 | 7 | 48 | 38 | [v2.7.0, 2026-07-23](https://github.com/getsentry/XcodeBuildMCP/releases/tag/v2.7.0) |
| [libimobiledevice](https://api.github.com/repos/libimobiledevice/libimobiledevice) | 8,064 | 1,522 | 837 | 87 | 1 | [1.4.0, 2025-10-10](https://github.com/libimobiledevice/libimobiledevice/releases/tag/1.4.0) |

릴리스 수는 각 저장소의 공식
[GitHub Releases API](https://docs.github.com/en/rest/releases/releases)에서
2025-07-29 이후 공개 릴리스를 계산했다. 다운로드 수는 재설치와 자동화 요청을
포함할 수 있으므로 고유 사용자 수로 해석하면 안 된다.

### AltStore: 결과가 보이는 제품

**근거:** AltStore는 “비탈옥 iOS 대체 앱스토어”라는 한 문장, 설치 앱의 남은
기간, `Refresh All`, 백그라운드 갱신을 사용자 화면에 연결한다.
[AltStore README](https://github.com/altstoreio/AltStore#readme)
[AltStore 시작 안내](https://faq.altstore.io/altstore-classic/your-altstore)

**근거:** 설치 문서는 다운로드, `/Applications` 복사, 메뉴 막대 실행, 기기
선택, 신뢰, Developer Mode를 순서대로 안내한다.
[AltStore macOS 설치](https://faq.altstore.io/altstore-classic/how-to-install-altstore-macos)

**근거:** 공식 문서는 오류 로그 복사, 오류 코드 검색, 상세 오류와 해결 제안을
제품 기능으로 다룬다. 공식 press kit은 아이콘, 프레임 스크린샷과 홍보 이미지를
제공한다.
[AltStore 릴리스 노트](https://faq.altstore.io/release-notes/altstore)
[AltStore press kit](https://faq.altstore.io/about-us/press-kit)

**추론:** SideRefresh도 “예약 횟수가 증가했다”가 아니라 iPhone의 설치 버전,
프로파일 만료일, 마지막 실제 설치 성공을 한 화면에서 증명해야 한다. 90초
데모와 복사 가능한 오류 증거는 코드 설명보다 먼저 준비할 가치가 있다.

### SideStore: 커뮤니티와 설치 자산이 연결된 사례

**근거:** SideStore는 스스로를 community-driven이라고 정의하고 GitHub
Discussions, Discord, 문서, 버그 보고, 기능 제안, 지원 등 비개발 기여 경로를
명시한다.
[SideStore README](https://github.com/SideStore/SideStore#readme)
[SideStore CONTRIBUTING](https://github.com/SideStore/SideStore/blob/develop/CONTRIBUTING.md)

**근거:** 최신 릴리스는 설치 가능한 `SideStore.ipa`를 제공하고 조사 시점
GitHub API 다운로드 수는 425,965회였다. 릴리스 노트는 변경 PR과 신규 기여자를
직접 표시한다.
[SideStore 0.6.3 API](https://api.github.com/repos/SideStore/SideStore/releases/latest)
[SideStore 0.6.3](https://github.com/SideStore/SideStore/releases/tag/0.6.3)

**근거:** 공식 설치 문서는 컴퓨터 단계와 기기 단계를 분리하고 남은 `7 DAYS`
표시를 탭해 첫 갱신을 완료하게 한다.
[SideStore 설치](https://docs.sidestore.io/docs/installation/install)

**추론:** SideRefresh는 SideStore의 계정·VPN·IPA 모델을 따라갈 필요가 없다.
배워야 할 부분은 설치 가능한 릴리스, 첫 갱신 확인, 공개 Q&A, 릴리스마다
기여자를 인정하는 운영 방식이다.

### fastlane: 진단 가능한 개발자 도구

**근거:** fastlane은 Homebrew와 Bundler 설치를 제공하고 `fastlane init`에서
프로젝트를 자동 감지해 누락 정보를 묻는다.
[fastlane 설치·설정](https://docs.fastlane.tools/#installing-fastlane)

**근거:** 지원 요청 전에 문서와 기존 이슈를 검색하고, 이슈에는 `fastlane env`
출력을 첨부하도록 한다. 회귀는 제목에 `[Regression]`을 붙여 빠르게 식별한다.
[fastlane 지원 절차](https://github.com/fastlane/fastlane#need-help)

**근거:** fastlane은 실행 수, 설치 방식, 버전, OS·Xcode 버전 등을 익명
측정하고 opt-out을 제공한다.
[fastlane metrics](https://docs.fastlane.tools/#metrics)

**추론:** SideRefresh에는 계정·UDID·Team ID·경로를 기본 수집하는 원격
텔레메트리보다, 사용자가 검토하고 첨부하는 redacted diagnostic bundle이 먼저
적합하다. 제품-시장 적합성 이후에도 측정은 명시적 동의와 opt-out이 필요하다.

### XcodeBuildMCP: 빠른 배포와 인터페이스 일관성

**근거:** XcodeBuildMCP는 같은 패키지에서 CLI와 MCP를 제공하고 Homebrew,
npm, 설치 없는 `npx` 경로와 클라이언트별 설정 문서를 제공한다.
[XcodeBuildMCP 설치](https://github.com/getsentry/XcodeBuildMCP#installation)

**근거:** 설치 확인, 도구 목록, 업그레이드 확인 명령과 설치·설정·도구·문제
해결·개인정보·기여 문서를 분리한다.
[XcodeBuildMCP README](https://github.com/getsentry/XcodeBuildMCP#readme)

**근거:** 최신 릴리스는 arm64, x64, universal 자산과 SHA-256 파일을 제공한다.
조사 시점 최신 arm64 자산은 1,122회 다운로드됐다.
[XcodeBuildMCP v2.7.0 API](https://api.github.com/repos/getsentry/XcodeBuildMCP/releases/latest)

**추론:** SideRefresh도 UI·CLI·MCP가 같은 갱신 엔진과 상태 의미를 유지해야 한다.
다만 90일 안에는 인터페이스 수보다 서명·공증 앱과 호환성 릴리스 속도를
우선한다.

### libimobiledevice: 기반 기술과 사용자 제품은 다르다

**근거:** libimobiledevice는 2007년부터 개발된 크로스플랫폼 프로토콜
라이브러리이며 앱 관리와 프로비저닝 도구를 제공한다.
[libimobiledevice README](https://github.com/libimobiledevice/libimobiledevice#readme)

**근거:** 공식 README는 응용 프로그램 사용 문서가 아직 없고 구현된 유틸리티를
보라고 안내한다.
[libimobiledevice 사용 안내](https://github.com/libimobiledevice/libimobiledevice#usage)

**추론:** 오래 유지되는 저수준 기반은 높은 기술 가치를 가질 수 있지만,
SideRefresh의 사용자 성공 모델은 될 수 없다. 선택적 검사 기반으로 존중하되
사용자에게 설치를 강제하지 않는 현재 경계를 유지한다.

### RebuildMe: 아이디어 유사성만으로는 채택되지 않는다

**근거:** RebuildMe는 iOS 대시보드에서 SSH로 Mac의 소스 빌드와 설치를
요청하는 직접 인접 프로젝트다. 그러나 저장소는 한 커밋, 0별, 0포크,
0릴리스이며 설명·홈페이지·topic이 없다.
[RebuildMe 저장소](https://github.com/AryanRogye/RebuildMe)
[RebuildMe API](https://api.github.com/repos/AryanRogye/RebuildMe)

**추론:** 이것은 인과관계의 증명이 아니다. 다만 문제와 코드가 있다는 사실만으로
발견·신뢰·설치·반복 사용이 생기지 않는다는 강한 경고다.

## 5. SideRefresh가 차지할 위치

### 핵심 사용자

**추론:** 초기 사용자는 다음 세 집단으로 제한한다.

- 본인 앱을 무료 Personal Team으로 실기기에서 장기간 테스트하는 개인 개발자
- 수업·학습·프로토타입 앱을 매주 다시 설치하는 학생과 메이커
- Apple 비밀번호나 p12 파일을 별도 사이드로딩 도구에 넘기고 싶지 않은 사용자

“모든 iPhone 사용자”나 “원하는 IPA를 설치하려는 사용자”는 초기 대상이 아니다.

### 비교 문장

| 대안 | 사용자가 기대하는 일 | SideRefresh의 답 |
| --- | --- | --- |
| AltStore·SideStore | IPA를 찾아 재서명·설치 | IPA를 받지 않고 현재 Xcode 소스를 다시 빌드 |
| fastlane | 범용 빌드·배포 자동화 | Personal Team 만료·기기 설치·예약 상태에 집중 |
| XcodeBuildMCP | AI가 Xcode 작업 실행 | 사용자 UI와 예약 Agent까지 포함한 갱신 제품 |
| 수동 Xcode | 사용자가 매주 직접 빌드·실행 | 같은 공식 도구를 일정·검증·영수증으로 자동화 |

### 반드시 지킬 비목표

- IPA 카탈로그, Anisette, Apple 계정 대리 로그인
- 인증서·비밀번호 수집 또는 클라우드 Xcode 빌드 서비스
- Apple 서명, Developer Mode, 기기 신뢰나 페어링 우회
- 자동 Git pull 또는 검토하지 않은 소스 실행
- 검증되지 않은 순수 셀룰러 경로를 지원 기능으로 홍보

**추론:** 이 경계를 넓히면 SideRefresh의 가장 강한 차별점인 “자기 소스,
자기 Xcode, 비밀번호 비수집”이 사라지고 지원·보안·라이선스 위험이 동시에
커진다.

## 6. 채택 경로

### 1단계: 신뢰할 수 있는 공개 소스

소스 공개 전에 이력·비밀·개인정보·라이선스·브랜드·Bundle ID를 감사한다.
Code of Conduct, issue form, PR template을 추가하고 private vulnerability
reporting을 활성화한다.

GitHub는 issue·PR template이 고품질 보고를 유도한다고 설명하며, private
vulnerability reporting은 공개 이슈 없이 구조화된 보안 제보를 받게 한다.
[GitHub template 안내](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
[GitHub 비공개 취약점 제보](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configuring-private-vulnerability-reporting-for-a-repository)

기본 브랜치에는 직접 push와 삭제를 막고 PR, 필수 CI, 대화 해결을 요구한다.
외부 GitHub Action은 전체 commit SHA로 고정하고 최소 권한의 토큰만 사용한다.
공개 후에는 OpenSSF Scorecard를 자동 실행해 branch protection, code review,
dangerous workflow, pinned dependency, token permission 같은 위험의 회귀를
확인한다.
[GitHub protected branch 안내](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
[GitHub Actions 보안 사용 안내](https://docs.github.com/en/actions/reference/security/secure-use)
[OpenSSF Scorecard](https://openssf.org/projects/scorecard/)

### 2단계: 설치 가능한 신뢰 자산

일반 사용자 릴리스는 universal `.app` ZIP, SHA-256, 변경 사항, 지원 Xcode와
macOS 범위, 알려진 제한을 포함한다. Developer ID로 서명하고 공증 티켓을
staple한 후 깨끗한 macOS 계정에서 검증한다.

Apple은 Mac App Store 밖 배포에 Developer ID를 사용하며, 공증은 악성 코드와
서명 문제를 검사해 Gatekeeper가 확인할 티켓을 만든다고 설명한다.
[Developer ID](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/)
[Apple 공증](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

GitHub Release는 실행 가능한 소프트웨어, 릴리스 노트와 바이너리 자산을 함께
배포하고 asset 다운로드 수를 API로 측정할 수 있다.
[GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)

릴리스는 draft에서 모든 자산과 체크섬을 먼저 첨부한 뒤 한 번에 발행한다.
GitHub immutable release를 활성화해 발행 후 tag 이동과 asset 교체를 막고,
사용자가 받은 바이너리가 처음 공개된 릴리스와 같은지 검증할 수 있게 한다.
[GitHub immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases)

### 3단계: 자체 Homebrew tap

서명·공증된 안정 자산이 나온 뒤 자체 tap에 Cask를 제공한다. 공식
`homebrew/cask` 제출은 채택 증거가 생긴 뒤 검토한다.

Homebrew는 macOS 앱에 Cask를 사용하며 최신 macOS와 선언한 아키텍처에서
동작하고 Gatekeeper 우회를 요구하지 않아야 한다.
[Homebrew 패키지 선택](https://docs.brew.sh/Adding-Software-to-Homebrew)
[Cask 정책](https://docs.brew.sh/Acceptable-Casks)

공식 tap에 저장소 소유자가 직접 제출할 때 일반적인 인지도 기준은 225별,
90포크 또는 90watcher이며, 30일 미만 저장소는 통상 대상이 아니다.
[Homebrew package acceptance policy](https://docs.brew.sh/Package-Acceptance-Policy)

**추론:** 이 수치를 성장 목표로 조작하지 않는다. 기준 전에는 자체 tap이 더
빠르고 정직하며, 공식 Cask는 사용자가 이미 찾는 제품이 된 뒤의 결과다.

### 4단계: 반복 성공과 기여 루프

```text
검색·소개
  → 90초 안에 문제와 경계 이해
  → 서명·공증 앱 설치
  → Configuration Test
  → 첫 실제 갱신과 만료 증거 확인
  → 8일 뒤 두 번째 갱신
  → redacted 진단·호환성 보고
  → 문서·fixture·코드 기여
```

GitHub Discussions는 Q&A, 공지, 방향 논의와 답변 표시를 저장소 안에서
운영할 수 있다.
[GitHub Discussions](https://docs.github.com/en/discussions/collaborating-with-your-community-using-discussions/about-discussions)

**추론:** 사용법 질문과 아이디어는 Discussions, 재현 가능한 버그와 확정 작업은
Issues, 민감한 결함은 private vulnerability report로 분리한다.

## 7. 90일 실행 계획

### 0–14일: P0 공개 준비와 신뢰

우선순위는 **공개해도 안전한 저장소**다.

- 전체 Git 이력, branch, tag, Actions 로그의 secret·개인정보 감사
- 브랜드 자산·코드·문서의 라이선스와 GPL/AGPL 경계 감사
- 최종 app Bundle ID와 LaunchAgent ID 확정
- README 첫 화면에 포지셔닝, 비목표, 90초 데모 또는 실제 화면 추가
- Code of Conduct, 버그·호환성 issue form, PR template 추가
- Discussions와 private vulnerability reporting 활성화
- CI에 Swift 테스트, sample, headless 검증 포함
- 기본 브랜치에 PR·필수 CI·대화 해결 규칙 적용
- 외부 GitHub Action을 전체 commit SHA로 고정하고 토큰 권한 최소화
- OpenSSF Scorecard를 실행해 공개 시점의 공급망 기준선 기록
- `preview` 지원 범위와 실기기 검증 표 게시

**출구 목표:**

- community profile 100%
- 공개 이력에서 유효한 secret 0건
- 기본 branch의 비기기 CI 100% 통과
- 기본 branch의 직접 push·삭제가 차단되고 필수 CI가 강제됨
- 모든 성공 상태가 Bundle ID·기기·설치·만료 근거를 포함

### 15–30일: 초대형 개발자 프리뷰

우선순위는 **8일 사용 증거**다.

- 서로 다른 Xcode·macOS·iOS 조합의 10명에게 source preview 초대
- 첫 실행을 프로젝트 → 기기 → Configuration Test → 실제 갱신으로 단순화
- 실패 화면에 다음 행동, 복사 가능한 오류 코드, redacted 진단 내보내기 제공
- 사용자가 검토해 제출하는 renewal receipt 형식 고정
- README에 90초 설치·첫 갱신 데모와 지원 표 추가
- `good first issue`는 parser fixture, 문서, UI 상태, 테스트부터 개방

**출구 목표:**

- 초대 사용자 10명 중 Configuration Test 성공 8명 이상
- 첫 실제 설치 성공 7명 이상
- 8일 뒤 자동 또는 수동 재갱신 성공 6명 이상
- 첫 성공까지 중앙값 15분 이하
- 공개 이슈에 UDID·Team ID·개인 경로 원문 노출 0건

### 31–60일: 서명·공증 바이너리 베타

우선순위는 **개발 환경 없는 설치**다. Xcode와 기기 설정은 여전히 필요하지만,
SideRefresh 자체를 빌드하게 해서는 안 된다.

- universal 또는 명확히 구분된 arm64·x64 앱 자산 생성
- Developer ID 서명, hardened runtime, secure timestamp, 공증, stapling 자동화
- GitHub Release에 ZIP, SHA-256, 지원 표, 알려진 문제, 업그레이드 설명 게시
- draft에서 자산을 검증한 뒤 immutable release로 한 번에 발행
- 깨끗한 macOS 현재 버전과 직전 지원 버전에서 다운로드·실행 검증
- `preview`와 `stable` 채널을 분리하고 2주 단위 호환성 릴리스 운영
- 자체 Homebrew tap Cask 제공
- 위협 모델과 redaction 정책 공개

**출구 목표:**

- Gatekeeper 우회 안내 없이 깨끗한 Mac 설치 성공 100%
- 지원 매트릭스에서 실제 갱신 시도 50회 이상, 성공률 90% 이상
- GitHub 베타 자산 다운로드 100회 이상
- opt-in으로 확인된 8일 재갱신 사용자 15명 이상
- 알려진 회귀의 48시간 내 triage 90% 이상

### 61–90일: 공개 출시와 기여자 루프

우선순위는 **지원 가능한 성장**이다.

- 안정 릴리스와 재현 가능한 demo/sample을 함께 공개
- GitHub Discussions에 설치 Q&A, 호환성, 아이디어, 공지 카테고리 운영
- 릴리스 노트에 외부 기여자와 첫 기여자 표시
- 최근·직전 Xcode 호환성 이슈에 빠른 fixture와 preview release 제공
- 독립 사용자 성공 사례 3개를 동의받아 문서화
- 외부 기여자가 맡을 수 있는 `good first issue` 5개 이상 유지
- 공식 Homebrew 기준 충족 여부를 확인하되 미충족이면 자체 tap 유지

**출구 목표:**

- opt-in 8일 재갱신 사용자 누적 25명 이상
- 지원 매트릭스 실제 갱신 성공률 95% 이상
- 외부 기여자 3명 이상, 외부 PR 3개 이상 병합
- 새 버그 이슈 첫 응답 중앙값 2영업일 이하
- 설치·갱신 Q&A의 80% 이상에 확인된 답변 표시

## 8. KPI

### 핵심 지표

| 지표 | 정의 | 90일 목표 |
| --- | --- | ---: |
| 8일 재갱신 사용자 | 첫 성공 후 7일 이상 지나 두 번째 실제 설치 성공 | 25명 |
| 지원 경로 성공률 | 지원 매트릭스의 실제 설치 성공 / 전체 실제 시도 | 95% |
| Configuration Test 전환 | 설치 사용자 중 테스트 완료 비율 | 80% |
| 첫 실제 갱신 전환 | 테스트 성공 사용자 중 실제 설치 성공 비율 | 85% |
| 첫 성공 시간 | 앱 첫 실행부터 첫 설치 영수증까지 중앙값 | 15분 이하 |
| 증거 완결성 | 성공 기록 중 설치·Bundle ID·기기·만료 근거 포함 비율 | 100% |

### 생태계 지표

| 지표 | 정의 | 90일 목표 |
| --- | --- | ---: |
| 외부 기여자 | maintainer가 아닌 merged contributor | 3명 |
| 외부 PR 병합 | 문서·fixture·테스트·코드 포함 | 3개 |
| 이슈 첫 응답 | 새 버그 이슈의 중앙 첫 응답 시간 | 2영업일 이하 |
| 회귀 triage | `[Regression]` 보고 중 48시간 내 분류 | 90% |
| Q&A 해결 | Discussions 질문 중 확인된 답변 비율 | 80% |
| 민감정보 노출 | 공개 issue·log의 원문 UDID·Team ID·개인 경로 | 0건 |

### 보조 지표

- GitHub release asset 다운로드와 Homebrew 설치는 유입을 본다.
- 별·포크·watcher는 인지도를 본다.
- README 방문 대비 다운로드, 다운로드 대비 Configuration Test 성공을 함께 본다.
- 다운로드 수는 고유 사용자가 아니므로 핵심 사용자 지표로 사용하지 않는다.

**추론:** 기본 원격 텔레메트리는 90일 성공의 전제조건이 아니다. 초기에는
사용자가 검토한 익명 receipt와 GitHub 자산 통계로 충분하다. 텔레메트리를
추가한다면 수집 항목 공개, 명시적 동의, opt-out, 식별자 hash와 보존 기간이
먼저다.

## 9. 커뮤니티 운영 원칙

### Issue form에 받을 정보

- SideRefresh 버전과 설치 방식
- macOS, Xcode, iOS 버전
- USB, 로컬 Wi-Fi, Tailnet 등 정확한 연결 경로
- 프로젝트 또는 workspace 여부와 실패 단계
- dry-run, Configuration Test, execute 구분
- 자동 redaction된 오류 코드와 로그
- 회귀 여부와 마지막 성공 버전

UDID, Team ID, Apple 계정, 개인 경로, 프로비저닝 원문은 입력하지 말라는 경고를
필드 바로 앞에 둔다.

### 기여자가 시작하기 좋은 경계

- Xcode·CoreDevice 출력 parser fixture
- 버전 정책과 만료 계산 테스트
- 지원 매트릭스와 번역
- 오류 메시지와 다음 행동
- CLI·MCP JSON schema fixture
- sample app과 dry-run 재현

실기기·서명 자산이 필요한 작업만 열어두면 외부 기여자가 시작하기 어렵다.
장비 없이 검증 가능한 경계를 유지한다.

### 유지관리 약속

- 지원 질문: Discussions로 이동하고 답변을 지식으로 남김
- 재현 가능한 버그: 2영업일 내 첫 분류
- 보안 보고: 48시간 내 접수 확인
- Xcode 회귀: 영향과 임시 회피책을 공개하고 preview에서 먼저 수정
- 릴리스: 지원 범위, 알려진 문제, breaking change, 기여자 명시

## 10. 하지 말아야 할 일

1. **SideStore 대체재로 홍보하지 않는다.** 입력, 신뢰, 사용자가 다르다.
2. **IPA·Apple 로그인·Anisette를 추가하지 않는다.** 포지셔닝과 보안 경계가
   무너진다.
3. **ad-hoc 앱을 일반 사용자 릴리스로 올리지 않는다.** Gatekeeper 우회 안내도
   하지 않는다.
4. **순수 셀룰러 Tailnet 경로를 검증 전에 약속하지 않는다.**
5. **다중 앱·다중 기기·원격 빌드를 첫 90일 핵심으로 삼지 않는다.**
6. **MCP 도구 수를 사용자 성공으로 착각하지 않는다.**
7. **별을 얻기 위한 기능 투표로 제품 경계를 흔들지 않는다.**
8. **GPL·AGPL 프로젝트 코드를 MIT core에 복사하거나 번들하지 않는다.**
9. **민감한 기기·서명 정보를 기본 텔레메트리로 수집하지 않는다.**
10. **Homebrew 공식 tap을 너무 일찍 목표로 삼지 않는다.** 서명·공증 자산과
    독립적인 사용 수요가 먼저다.

## 11. 30·60·90일 의사결정 기준

### 30일

- 6명 이상이 8일 재갱신에 성공하면 바이너리 베타로 진행한다.
- 첫 성공률이 낮으면 기능을 늘리지 말고 onboarding과 오류 복구를 고친다.
- 실패 원인이 Apple/Xcode 제약인지 SideRefresh 결함인지 분류되지 않으면 진단
  모델부터 고친다.

### 60일

- 서명·공증 앱이 Gatekeeper 우회 없이 설치되고 성공률 90% 이상이면 공개
  베타로 진행한다.
- 실패가 특정 Xcode·iOS 조합에 집중되면 지원 매트릭스를 좁히고 명시한다.
- 8일 유지 사용자가 15명 미만이면 홍보보다 사용자 인터뷰와 설치 흐름을
  우선한다.

### 90일

- 25명 이상의 8일 재갱신, 95% 성공률, 외부 기여자 3명이면 현재 범주를
  확장할 근거가 생긴다.
- 반복 사용은 있으나 기여가 없으면 fixture·문서·issue 크기를 더 작게 나눈다.
- 반복 사용이 없으면 다중 앱이나 원격 기능을 추가하기 전에 핵심 가설을
  재검토한다.

## 최종 권고

**추론:** SideRefresh가 오픈소스로 성공하는 가장 현실적인 길은 좁고 신뢰도 높은
개발자 도구로 시작하는 것이다.

공개 소스 → 10명·8일 검증 → Developer ID 서명·공증 GitHub Release → 자체
Homebrew tap → 반복 성공과 외부 기여 → 필요할 때만 공식 Cask와 범위 확장
순서를 지킨다.

가장 중요한 숫자는 별이 아니다. **Apple 비밀번호를 받지 않고 사용자의 현재
소스가 8일 뒤에도 실제 iPhone에서 다시 실행되는 비율**이다.
