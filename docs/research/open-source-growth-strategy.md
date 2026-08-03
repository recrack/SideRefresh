# SideRefresh 오픈소스 성장과 수요 검증

- 조사일: 2026-07-26
- 질문:
  - 무료 Personal Team 앱의 7일 만료와 재설치에 실제 불만이 있는가?
  - AI로 개인용 Apple 앱을 만드는 비개발자까지 SideRefresh의 사용자가 될 수 있는가?
  - SideRefresh는 오픈소스와 유료 제품 중 어느 방향이 적합한가?
- 주의: 커뮤니티 게시물은 수요의 존재와 언어를 보여주지만 전체 시장 규모를
  추정할 표본은 아니다.

## 결론

**문제 수요는 실제로 존재한다.** 2017년 Apple Developer Forums부터 2026년
Reddit까지, 무료 계정으로 자기 앱을 설치한 사용자가 7일 후 실행할 수 없게 되고
Xcode에서 다시 빌드·설치해야 하는 불편을 반복해서 보고한다. 2025~2026년에는
“완전한 개인용 앱이라 공개하고 싶지 않다”, “개인 앱 때문에 연 $99를 내기
어렵다”, “AI로 만든 개인용 앱이 배포 장벽 때문에 방치된다”는 사례도 확인된다.

다만 **강한 틈새 수요가 확인된 것과 큰 시장이 검증된 것은 다르다.** 현재 근거는
문제 강도와 반복성을 보여주지만, 다음 조건을 모두 감수할 사람의 수는 아직 모른다.

- Mac을 소유하고 Xcode를 설치할 수 있음
- 자기 소스 프로젝트를 보유함
- 최초 Apple 계정·Personal Team·기기 신뢰·페어링 설정은 수행함
- App Store 공개보다 개인 사용을 원함
- 매년 $99를 내는 대신 로컬 자동 재설치를 선택함

따라서 SideRefresh는 우선 **무료 MIT 오픈소스**로 공개하는 것이 적합하다. 이 도구는
프로젝트 소스, Xcode 서명, 기기 식별자, 백그라운드 실행을 다루므로 소스 공개가
신뢰와 기여의 기반이다. 핵심 갱신 기능을 유료화하면 “개인 앱 하나 때문에 $99를
내기 싫다”는 문제 정의와도 충돌한다. 수익화가 필요해지면 핵심 로컬 갱신이 아니라
후원, 우선 지원, 팀 운영, 다중 Mac worker 같은 별도 편의에서 검토한다.

## Apple이 만든 객관적인 문제 경계

Apple은 무료 계정의 Personal Team에서 다음 제한을 공식적으로 명시한다.

- App ID는 최대 10개이며 7일 후 만료
- 기기는 최대 3대이며 7일 후 만료
- 기기당 앱은 최대 3개
- 설치용 provisioning profile은 발급 후 7일 만료
- 만료 뒤 앱을 다시 빌드하고 기기에 다시 설치해야 함

[Apple — Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account)

Apple Developer Program은 연 $99이며 지역별 현지 통화 가격이 적용될 수 있다.
[Apple — Become a member](https://developer.apple.com/programs/enroll/)

SideRefresh는 이 제한을 제거하거나 우회하지 않는다. Xcode의 무료 Personal Team을
사용해 만료 전에 **정상적인 재프로비저닝·재빌드·재설치 작업을 반복**한다.

## 실제 불만 증거

### SideRefresh와 직접 일치하는 사례

| 시점 | 사용자 상황 | 불만 | SideRefresh 적합도 |
|---|---|---|---|
| 2025-10 | Xcode로 개인용 라디오 앱 제작 | 7일마다 Mac에서 재설치하는 것이 불편하고, 앱은 완전히 개인용이라 App Store에 공개하고 싶지 않음 | 매우 높음 |
| 2024-08 | iOS 개발 초보가 자기 앱을 자기 기기에 설치 | 개인용 앱에 연 $100을 내는 것은 받아들이기 어렵고, 무료 계정은 매주 Xcode 연결이 필요하다는 답을 받음 | 매우 높음 |
| 2026-02 | 개인용 앱의 $99 비용을 질문 | 무료 계정이면 매주 다시 설치해야 하며, 개인용 앱을 위해 계속 비용을 내는 것이 맞는지 고민 | 높음 |
| 2026-05 | 개인화한 Flutter 자동차 관리 앱 | 앱은 두 사람에게 유용하지만 $99도, 7일마다 재설치하는 일도 가치에 비해 과하다고 판단 | 높음 |
| 2022-07 | 개인용 Swift 앱 제작 | 무료 계정에서는 7일 뒤 Xcode로 다시 설치해야 한다는 점을 확인 | 높음 |

출처:

- [Reddit /r/Xcode — personal app running without reinstalling every 7 days](https://www.reddit.com/r/Xcode/comments/1o7fzkx/how_can_i_keep_my_personal_ios_app_running/)
- [Reddit /r/iOSProgramming — pay for my own app on my own device?](https://www.reddit.com/r/iOSProgramming/comments/1f2hfzp)
- [Reddit /r/iOSProgramming — $99 dev fee for a personal use app?](https://www.reddit.com/r/iOSProgramming/comments/1r3dm9k/99_dev_fee_for_a_personal_use_app/)
- [Reddit /r/iOSProgramming — move a personal Flutter app to Apple](https://www.reddit.com/r/iOSProgramming/comments/1teda7u/whats_needed_to_move_my_flutter_app_to_apple/)
- [Reddit /r/swift — install my own app permanently](https://www.reddit.com/r/swift/comments/w6a8yd)

### AI·비개발자 가설과 직접 연결되는 사례

2026년의 한 사용자는 개인적으로 매우 유용한 vibe-coded 앱 2~3개를 만들었지만,
무료 provisioning이 7일 후 만료되어 Xcode로 다시 설치해야 한다고 질문했다. 이는
SideRefresh의 가설과 거의 정확히 일치한다.
[Reddit /r/Solopreneur — vibe-coded personal apps and the $99 fee](https://www.reddit.com/r/Solopreneur/comments/1sqnskc/how_do_you_bypass_99_usdyear_apple_fee_to_run/)

다른 사용자는 가족을 위한 작은 개인 앱을 만들었으나 iOS의 연간 비용과 공개 배포
절차가 개인 앱에 맞지 않아 결국 브라우저 탭으로 남았다고 설명했다.
[Reddit /r/vibecoding — what happened after finishing a vibe-coded app?](https://www.reddit.com/r/vibecoding/comments/1rjj194/after_finishing_your_vibe_coded_app_what_actually/)

코딩 경험 없이 AI로 실제 iOS 앱을 만든 사례와 Apple 계정, Bundle ID, Xcode 과정에서
겪은 혼란도 존재한다.
[Reddit /r/vibecoding — first iOS app with zero coding experience](https://www.reddit.com/r/vibecoding/comments/1sximc6/i_vibe_coded_my_first_ios_app_with_zero_coding/)

이는 일시적 유행만으로 단정할 근거는 아니지만, Apple 자체도 Xcode에서 OpenAI·Anthropic
등의 모델과 coding agent를 공식 지원하고 있어 앱 생성 장벽이 낮아지는 방향은
명확하다.
[Apple — Xcode coding intelligence](https://developer.apple.com/xcode/)

### iPad와 Apple Watch 수요

iPad의 개인 앱도 같은 무료 provisioning 제한을 받는다. 2026년 Flutter 개인 앱
사례는 iPhone 외 기기 설치 기대를 보여준다.

Apple Watch에서는 Xcode로 설치한 튜토리얼 앱이 약 일주일 뒤 “App is no longer
available” 상태가 됐다는 장기 스레드가 있다. 댓글에도 자기 앱 하나를 위해 $99를
내고 싶지 않다는 불만이 반복된다.
[Reddit /r/swift — Apple Watch app is no longer available](https://www.reddit.com/r/swift/comments/i91j9o/)

그러나 이는 **제품 수요 근거**이지 현재 SideRefresh의 지원 근거가 아니다.

- 현재 구현은 물리 iPhone만 탐색한다.
- iPad는 CoreDevice 대상 모델을 일반화하면 비교적 가까운 확장이다.
- watchOS는 iPhone 페어링, companion/standalone target, 빌드 산출물과 설치 경로를
  별도로 검증해야 한다.

따라서 공개 메시지는 우선 iPhone으로 제한하고, iPad를 다음 플랫폼으로 검증하며,
Apple Watch는 연구·실험 단계로 표시해야 한다.

### 반복되는 불만 유형

1. **매주 하는 수동 작업**
   - Xcode를 열고 프로젝트와 기기를 다시 선택해 빌드·설치해야 함
2. **필요할 때 앱이 죽어 있음**
   - 여행 중이거나 다른 사람에게 보여주려 할 때 만료를 발견
3. **개인 앱과 공개 배포의 불일치**
   - App Store 공개·심사·마케팅이 필요 없는 개인 도구임
4. **연 $99의 가치 불일치**
   - 상업 앱이 아닌 작은 개인 도구 한두 개에는 비용이 과하다고 느낌
5. **Mac 의존**
   - 매주 Mac에 접근하거나 케이블을 연결하기 싫음
6. **상태와 데이터에 대한 불안**
   - 언제 만료되는지, 다시 설치하면 앱 데이터가 유지되는지 모름
7. **무료 계정의 추가 제한**
   - 앱 개수, App ID, 기기 수, 일부 entitlement가 막힘

SideRefresh는 1~6을 줄일 수 있지만 7은 해결하지 못한다. Mac이 꺼져 있거나 iPhone에
도달할 수 없는 상황도 해결하지 못하므로 이를 약속해서는 안 된다.

## 인접 시장 신호

2026-07-26 GitHub API 기준:

- AltStore: 약 14.1k stars, 1.3k forks
- SideStore: 약 6.0k stars, 400 forks

[AltStore 공식 저장소](https://github.com/altstoreio/AltStore)
[SideStore 공식 저장소](https://github.com/SideStore/SideStore)

두 프로젝트의 stars와 refresh 관련 이슈는 “7일 서명 갱신”이라는 인접 문제의
수요가 작지 않음을 보여준다. 그러나 둘은 IPA 재서명·사이드로딩 제품이고,
SideRefresh는 사용자가 소유한 Xcode 소스를 다시 빌드하는 제품이다. 이 숫자를
SideRefresh의 직접 시장 규모로 사용하면 안 된다.

### SideRefresh의 차별점

- Apple ID와 암호를 수집하지 않고 Xcode의 기존 로그인·서명을 사용
- 알 수 없는 IPA가 아니라 사용자가 소유한 현재 소스를 빌드
- Bundle ID, Team, 기기 UDID를 설치 전에 검증
- 실제 성공한 설치의 profile 만료일을 기록
- 앱이 항상 실행 중일 필요 없는 짧은 macOS background agent
- USB, 같은 LAN, Tailscale, 검증된 직접 IP 경로를 분리
- 실패 단계와 원문 로그를 로컬에서 확인

추천 포지셔닝:

> Keep the personal iPhone apps you build with AI running—using Apple’s free
> Personal Team, without the weekly Xcode reinstall.

한국어:

> AI로 만든 내 iPhone 앱, 7일마다 Xcode로 다시 설치하지 마세요.

바로 뒤에는 반드시 다음 경계를 붙인다.

> SideRefresh는 Apple 서명을 우회하지 않습니다. Mac의 Xcode와 무료 Personal Team을
> 사용해 사용자가 소유한 소스를 다시 빌드하고 자기 기기에 재설치합니다.

## 오픈소스인가, 유료인가

### 권장: 무료 MIT 오픈소스 core

이유:

1. 서명·설치·background agent를 다루므로 감사 가능한 소스가 채택 장벽을 낮춘다.
2. AI로 만든 개인 프로젝트를 직접 연결하는 도구는 공급망 신뢰가 중요하다.
3. 현재 저장소가 이미 MIT이며 독립 Swift 구현이다.
4. contributor가 iPad, watchOS, Flutter, Expo, 기기 fixture를 확장할 수 있다.
5. “$99를 피하려는 개인 사용자”에게 또 다른 핵심 구독료를 요구하면 메시지가 약해진다.

AltStore와 SideStore는 의존성 때문에 AGPLv3 계열이다. SideRefresh는 해당 코드를
복사하지 말고 독립 구현을 유지해야 한다.

### 나중에 가능한 수익

- GitHub Sponsors와 개인 후원
- 기업·교육기관용 우선 지원
- 다중 Mac worker와 팀 운영 도구
- 보안 검토·배포 설정 컨설팅
- 유지보수 계약

초기에는 공식 notarized binary도 무료가 권장된다. 비개발자에게 source build만
제공하면 가장 중요한 대상이 설치 단계에서 이탈한다.

## 조사 당시 공개 전 문제와 처리 결과

다음은 2026-07-26 비공개 개발 저장소의 역사적 스냅샷이며 현재 공개 소스
후보의 상태가 아니다.

- 저장소가 비공개였음
- 설명과 홈페이지가 비어 있음
- repository topics가 없음
- Discussions가 꺼져 있음
- 기본 브랜치는 `master`
- 현재 기능 브랜치는 기본 브랜치보다 11개 commit 앞섬
- binary release가 없음
- Developer ID 서명과 notarization이 아직 없음
- README 상단에 실제 앱 screenshot/GIF가 없음
- `CODE_OF_CONDUCT.md`, issue forms, PR template이 없었음

당시 강점:

- MIT LICENSE
- README, CONTRIBUTING, SECURITY, CHANGELOG
- macOS CI
- 122개 자동 테스트
- non-mutating sample validation
- sample iOS app
- 안전 경계와 실제 설치 검증 문서

GitHub의 community profile은 README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT,
issue template 등을 공개 프로젝트의 건강성 신호로 사용한다.
[GitHub — Community profiles](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)

2026-08-03 공개 후보에서는 비공개 개발 그래프 대신 검토한 트리만 새 단일
커밋으로 내보내고, community 파일과 전체 CI 검사를 추가했다. 아직 남은 공개
제품 게이트는 Developer ID 서명·공증 바이너리와 실제 릴리스 화면이다.

공개 전환 순서:

1. 전체 Git history, 모든 branch와 tag의 secret·UDID·Team ID·사용자 경로 감사
2. 현재 기능 브랜치를 검토해 기본 브랜치에 반영
3. 기본 브랜치와 보호 정책을 명시적으로 설정
4. 제품 설명, homepage, social preview, topics 설정
5. issue forms, PR template, Code of Conduct 추가
6. 공개 뒤 GitHub secret scanning과 code scanning 활성화

GitHub는 public repository에 secret scanning과 code scanning을 제공한다.
[GitHub — Secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)
[GitHub — Code scanning](https://docs.github.com/en/code-security/concepts/code-scanning/code-scanning)

추천 topics:

`ios`, `macos`, `swift`, `swiftui`, `xcode`, `personal-team`,
`ios-development`, `developer-tools`, `self-hosted`, `tailscale`

Topics는 GitHub 검색과 주제별 발견에 사용된다.
[GitHub — Repository topics](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics)

## “유명해지는” 공개 제품 경로

### 1. 10초 안에 문제와 결과를 보여준다

현재 README는 정확하지만 길고 개발 과정 중심이다. 상단을 다음 순서로 바꾼다.

1. 한 문장 문제 정의
2. 15~30초 GIF: 앱 선택 → iPhone 선택 → 만료일 확인 → 자동 갱신 켜기
3. “Apple ID를 받지 않음 / jailbreak 아님 / 소스를 직접 빌드” 3개 신뢰 badge
4. 3단계 설치
5. 지원 범위와 제한
6. 상세 아키텍처와 기여 문서

### 2. source-only preview와 일반 사용자 release를 구분한다

- **Developer preview:** source build, 기술 사용자 10명
- **Public beta:** Developer ID 서명·notarization된 ZIP, checksum, release notes
- **Stable:** updater, Homebrew tap, 호환성 표

GitHub Releases는 tag 기반 배포물과 release asset 다운로드를 제공한다.
[GitHub — About releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)

Homebrew Cask는 최신 macOS에서 동작해야 하고 Gatekeeper/SIP 우회를 요구해서는 안
되며, 검증 가능한 upstream binary가 필요하다. 따라서 ad-hoc app을 먼저 공식 Cask에
넣는 전략은 맞지 않는다.
[Homebrew — Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)

### 3. 기능이 아니라 “8일째에도 실행됨”을 데모한다

가장 설득력 있는 콘텐츠:

- Day 0: AI가 만든 개인 앱을 iPhone에 설치
- Day 6: SideRefresh가 만료일을 읽고 자동 갱신
- Day 8: 앱 데이터가 유지된 상태로 계속 실행
- 실패 예시: Mac offline 또는 iPhone unreachable이면 성공으로 속이지 않고 재시도

### 4. 초기 배포 채널

- Show HN: 공식 경계와 CoreDevice 기술 설명
- Reddit: `/r/iOSProgramming`, `/r/Swift`, `/r/macapps`,
  `/r/vibecoding`, `/r/selfhosted`
- GitHub Discussions: setup help, verified devices, feature ideas
- Tailscale community: VPN 홍보가 아니라 이미 연결된 사용자의 재설치 실험
- 한국어 개발·AI 제작 커뮤니티

각 커뮤니티 규칙을 확인하고 동일 홍보문을 반복하지 않는다. “무료 서명 우회”가 아니라
“공식 Xcode 재설치 자동화”라고 설명한다.

## 제품 UI에 미치는 영향

비개발자가 대상이면 현재 sidebar의 numbered setup을 영구 정보 구조로 사용하면 안 된다.

권장:

- `설치 흐름` → `갱신 현황`
- `1. 설치할 앱` → `내 앱`
- `2. 설치할 iPhone` → `iPhone` (iPad 지원 후 `내 기기`로 확장)
- `3. 자동 갱신` → `자동 갱신`

첫 실행에서만 별도 onboarding 순서를 사용한다.

1. 앱 선택
2. 기기 선택
3. 테스트 설치
4. 자동 갱신 켜기

설정이 끝난 뒤 홈 화면에는 다음만 먼저 보여준다.

- `내 앱 → 내 iPhone`
- 자동 갱신 켜짐/꺼짐
- profile 만료일
- 다음 갱신 시각
- `지금 갱신`
- 마지막 성공 또는 해결해야 할 한 가지 문제

`설치 흐름`은 일회 작업처럼 들리지만 제품의 핵심은 반복 갱신이다. “설치”는 진행
로그의 기술 단계로 두고, navigation에는 “홈/갱신 현황”을 쓰는 편이 적합하다.

## 시장 검증 실험

홍보보다 먼저 10명의 8일 실험을 한다.

대상:

- 최근 3개월 안에 AI로 iOS 프로젝트를 만든 비개발자 5명
- 무료 Personal Team으로 개인 앱을 쓰는 초급 개발자 5명

질문은 “쓰시겠어요?”가 아니라 실제 행동을 확인한다.

1. 마지막으로 만든 개인 앱을 보여 달라고 요청
2. 실제 기기에 설치했는지 확인
3. 7일 뒤 무슨 일이 있었는지 확인
4. SideRefresh로 첫 설치를 함께 수행
5. 8일째 앱 실행과 데이터 유지 확인

초기 통과 기준:

- 인터뷰 15명 중 8명 이상이 7일 만료 또는 $99를 실제 장애로 경험
- 10명 중 7명이 첫 설치 완료
- 10명 중 5명이 자동 갱신 등록 완료
- 8일째 5명 이상이 앱을 계속 실행
- 최소 3명이 다음 개인 앱도 등록하고 싶다고 실제 프로젝트로 시도

이 기준을 넘으면 수요를 “관심”이 아니라 반복 사용으로 볼 수 있다.

## 30/60/90일 제안

### 0~30일: clean-source preview

- 현재 브랜치를 기본 브랜치 후보로 정리
- secret/history audit
- README hero GIF와 3분 onboarding
- iPhone 한 대·앱 한 개 범위를 명확히 표시
- 10명 8일 실험
- 실패 로그 redaction과 support template 준비

### 31~60일: public beta

- Developer ID 등록, 서명, notarization
- `v0.2.0-beta.1` GitHub Release와 SHA-256
- iPad CoreDevice 지원 검증
- Discussions, issue forms, PR template, Code of Conduct
- 첫 실제 사용자 사례와 Day 8 데모 공개

### 61~90일: 성장 루프

- 다중 앱 지원 우선순위 결정
- Flutter/Expo/Swift/Swift Playground project fixture 확장
- Homebrew tap 제공; 공식 Cask는 notability와 안정성 이후
- watchOS 별도 기술 prototype
- contributor용 `good first issue`와 device compatibility matrix
- 다운로드보다 “첫 자동 갱신 성공”과 “8일째 실행”을 핵심 성공 기준으로 유지

## 최종 판단

SideRefresh가 노려야 할 시장은 “사이드로딩 전체”가 아니다.

> AI나 Xcode로 자기만의 Apple 앱을 만들었지만, 공개 배포도 연 $99도 원하지 않고,
> 7일마다 다시 설치하는 일만 없애고 싶은 사람

이 사람들의 불만은 실제로 존재하며, 2026년에는 AI 제작 사례와 직접 결합하기
시작했다. 따라서 **무료 오픈소스 iPhone-first beta**로 정확한 문제를 해결하고,
8일 실사용 유지율로 시장을 검증하는 것이 현재 가장 타당하다.
