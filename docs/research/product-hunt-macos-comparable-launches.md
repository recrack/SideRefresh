# Product Hunt 오픈소스 macOS 앱 비교 조사

> 조사일: 2026-08-02
>
> 목적: 실제 Product Hunt 출시 사례를 통해 Developer ID 서명·Apple 공증이
> Product Hunt의 등록 조건인지, 아니면 SideRefresh가 별도로 선택한 배포 품질
> 기준인지 구분한다.

## 결론

**Developer ID Application 인증서와 Apple 공증은 Product Hunt 등록 조건이
아니다.** Product Hunt의 공식 기준은 현재 사용할 수 있는 디지털 제품인지,
유용성·새로움·완성도·창의성이 있는지에 초점을 둔다. 실제로 서명되지 않았거나
공증되지 않은 macOS 앱도 Product Hunt에 출시되어 일간 순위를 기록했다.
[Product Hunt Featuring Guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines)

이는 Product Hunt가 `Developer ID 불필요`라는 문장을 별도로 선언했다는 뜻이
아니라, 공식 기준에 해당 요구가 없고 아래 실제 featured launch에 미서명·미공증
반례가 존재한다는 두 근거를 결합한 판단이다.

그러나 **Product Hunt에 올릴 수 있는가**와 **SideRefresh가 신뢰할 수 있는
안정판인가**는 다른 질문이다. SideRefresh는 Xcode 프로젝트, Apple Account
Personal Team, iPhone 연결, 서명과 설치를 다룬다. 여기에 Gatekeeper 우회까지
요구하면 사용자가 감수해야 할 신뢰 비용이 겹친다.

따라서 기존 출시 순서를 유지한다.

1. 공개 소스 전용 `v0.2.0-beta.1`로 설치·문서·제품 약속을 먼저 검증한다.
2. Developer ID로 서명하고 Apple에 공증한 `v0.2.0` 다운로드를 공개한다.
3. 공개 다운로드가 Gatekeeper 검증을 통과한 뒤 Product Hunt의 주 출시를 한다.

인증서가 아직 없더라도 Product Hunt 제출 자체는 가능하다. 다만 그 상태의
출시는 기술적 가능성일 뿐 SideRefresh의 권장 주 출시 전략은 아니다.

## 조사 방법

Product Hunt에 실제 등록된 macOS 오픈소스 또는 source-available 제품 중
SideRefresh와 배포 형태가 비슷한 10개를 표본으로 삼았다. 각 제품은 Product
Hunt 페이지, 공식 GitHub 저장소, 공식 설치 문서와 GitHub Release만 확인했다.

현재 공개 릴리스가 있는 9개 제품은 바이너리를 실행하지 않고 다음 명령으로
서명과 Gatekeeper 상태를 읽기 전용으로 확인했다.

```sh
codesign -dvvv Product.app
codesign --verify --deep --strict Product.app
spctl --assess --type execute -vv Product.app
xcrun stapler validate Product.app
```

검사 결과는 2026-08-02에 다운로드한 표의 정확한 릴리스에만 적용된다. 이후
업데이트의 상태를 보장하지 않는다. `spctl`의 `Notarized Developer ID` 승인을
공증 근거로 사용했고, 문서만 확인한 경우에는 그렇게 구분했다. DMG나 ZIP이
있다는 사실만으로 서명·공증을 추정하지 않았다.

또한 Sparkle의 EdDSA 업데이트 서명과 macOS Developer ID 코드 서명은 다른
보안 계층이다. 업데이트 파일이 Sparkle로 서명되어도 앱 자체가 Gatekeeper에서
승인된다는 뜻은 아니다.

## 실제 출시 앱 비교

| 제품 | Product Hunt와 배포 | 확인한 서명·공증 상태 | SideRefresh가 배울 점 |
| --- | --- | --- | --- |
| [CodexBar Lite](https://www.producthunt.com/products/codexbar-lite) | [v0.2.4](https://github.com/wei-b0/codexbar-lite/releases/tag/v0.2.4)의 DMG·ZIP, Sparkle 자동 업데이트 | 앱은 ad-hoc 서명이고 `spctl` 거부, stapled ticket 없음. [README](https://github.com/wei-b0/codexbar-lite/blob/617d2e4c9d880fd97f71c0b3848b26feaf42d832/README.md)는 Sparkle release signing을 설명한다. | Agent 도구 이용자에게 가까운 최신 사례다. 직접 다운로드와 업데이트는 강점이지만 Sparkle 서명만으로 Gatekeeper 신뢰를 대신할 수 없다. |
| [GitSync for macOS](https://www.producthunt.com/products/gitsync-for-macos) | [V.1.0](https://github.com/KeepCoolCH/GitSync/releases/tag/V.1.0)의 DMG·ZIP | `Apple Development` 인증서로 서명되어 있으나 외부 배포용 Developer ID가 아니어서 `spctl` 거부, ticket 없음. [README](https://github.com/KeepCoolCH/GitSync/blob/9ba488de6330e291f0517c7fad8263c5195c3413/README.md#installation)는 `Open Anyway`를 안내한다. | Product Hunt가 Developer ID를 검사하지 않는 직접 사례다. 하지만 일반 사용자가 개발 인증서와 외부 배포 인증서의 차이까지 감당하게 된다. |
| [Open Caffeine](https://www.producthunt.com/products/open-caffeine) | [v1.0.2](https://github.com/sapsaldog/open-caffeine/releases/tag/v1.0.2)의 ZIP, Sparkle 자동 업데이트 | 앱은 ad-hoc 서명이고 `spctl` 거부, ticket 없음. [README](https://github.com/sapsaldog/open-caffeine/blob/a01b506961c82138b700296e26a7ee08e7276e13/README.md)는 `No code signing — local builds only`라고 명시한다. | 코드 서명 없이도 Product Hunt에서 2026년 일간 10위를 기록했다. 등록 가능성을 증명하지만 설치 신뢰성의 기준은 아니다. |
| [MacMonitor](https://www.producthunt.com/products/macmonitor) | Homebrew, 설치 스크립트, GitHub DMG | 바이너리는 별도 검사하지 않았다. 공식 [README](https://github.com/ryyansafar/MacMonitor/blob/7c94c613ff2cd77bec5dc3b34152254af7deee9c/README.md#installation)가 공증되지 않았다고 밝히고 quarantine 제거·`Open Anyway` 절차를 제공한다. | 공증이 Product Hunt 조건이 아니라는 가장 명시적인 반례다. quarantine 제거를 정상 설치법으로 만드는 전략은 SideRefresh가 복제하지 않는다. |
| [Tock](https://www.producthunt.com/products/tock-3) | [v0.1.27](https://github.com/edelstone/tock/releases/tag/v0.1.27)의 DMG와 Mac App Store | GitHub DMG의 앱은 Developer ID 서명, secure timestamp, 유효한 stapled ticket을 갖고 `spctl` 승인. 공식 [release guide](https://github.com/edelstone/tock/blob/0d3013df2aa31b2f58f17329029c8106ee615440/RELEASING.md#signed--notarized-dmg)도 서명·공증·stapling 절차를 분리해 설명한다. | 직접 다운로드와 App Store를 동시에 제공하고 비 App Store DMG도 정상 Gatekeeper 경로로 배포한다. SideRefresh의 직접 배포 모델에 가장 가까운 품질 기준이다. |
| [Ice](https://www.producthunt.com/products/ice-2) | [0.11.12](https://github.com/jordanbaird/Ice/releases/tag/0.11.12)의 ZIP과 Homebrew | 앱은 Developer ID 서명, secure timestamp, 유효한 stapled ticket을 갖고 `spctl` 승인. | `한 문장 가치 제안 → Download → Homebrew`의 단순한 설치 구조가 강하다. 첫 릴리스에서 Homebrew는 제외하더라도 다운로드 버튼의 명확성은 적용한다. |
| [Hidden Bar](https://www.producthunt.com/products/hidden-bar) | [v1.10](https://github.com/dwarvesf/hidden/releases/tag/v1.10)의 ZIP, Homebrew, Mac App Store | 앱은 Developer ID 서명과 유효한 stapled ticket으로 `spctl` 승인. 공식 [README](https://github.com/dwarvesf/hidden/blob/0dde4b6882144309263ac465375971a5c39b492d/README.md#others)도 App Store 밖 배포본을 공증한다고 명시한다. | 오픈소스, App Store, 직접 배포를 함께 제공하되 각 설치 경로의 신뢰 상태를 분명히 한다. |
| [Pearcleaner](https://www.producthunt.com/products/pearcleaner) | [5.4.3](https://github.com/alienator88/Pearcleaner/releases/tag/5.4.3)의 DMG·ZIP과 Homebrew | 확인한 arm64 앱은 Developer ID 서명이며 `spctl`이 `Notarized Developer ID`로 승인했다. 앱 자체의 stapled ticket은 없어서 온라인 공증 조회에 의존할 수 있다. | 여러 설치 경로와 즉시 실행 가능한 바이너리는 좋다. 다만 현재 [라이선스](https://github.com/alienator88/Pearcleaner/blob/7724df7111bff82ae243301cf701992ef05ecf19/LICENSE.md)는 Apache-2.0에 Commons Clause를 더한 source-available 형태이므로 Product Hunt 설명처럼 정확한 라이선스 용어가 중요하다. |
| [Sol](https://www.producthunt.com/products/sol-2) | [2.1.348](https://github.com/ospfranco/sol/releases/tag/2.1.348)의 ZIP과 Homebrew | 앱은 Developer ID 서명, secure timestamp, 유효한 stapled ticket을 갖고 `spctl` 승인. | 개발자 도구도 소스 빌드 대신 즉시 설치 가능한 안정판을 전면에 둔다. |
| [Ollamac](https://www.producthunt.com/products/ollamac?launch=ollamac) | [v3.0.3](https://github.com/kevinhermawan/Ollamac/releases/tag/v3.0.3)의 DMG와 Homebrew | 앱은 Developer ID 서명, secure timestamp, 유효한 stapled ticket을 갖고 `spctl` 승인. | AI·개발자 이용자 대상 오픈소스 앱도 일반 사용자가 바로 받을 수 있는 공증 DMG를 제공한다. SideRefresh가 겨냥하는 Agent app maker에게 가까운 배포 기대치다. |

표의 Product Hunt 순위와 points는 서명 품질의 인과관계를 뜻하지 않는다. 예를
들어 unsigned 앱이 순위에 올랐다는 사실은 “등록 가능”을 증명할 뿐, 서명이
전환율에 불필요하다는 것을 증명하지 않는다.

## 일간 Top 10에 든 비교 제품 10개

여기서 `Top 10`은 변동하는 Product Hunt 전체·역대 순위가 아니라, SideRefresh와
관련성이 높은 실제 launch 중 **각 출시일의 Day Rank가 1–10위였던 사례 10개**를
뜻한다. 순위는 Product Hunt 공식 launch 또는 awards 페이지에서 확인했다.

서명 열은 출시 당시 상태가 아니라 2026-08-02 현재 공식 배포 상태다. 오래된
제품은 출시 후 서명·공증을 추가했을 수 있으므로, 아래 결과로 서명과 당시 순위의
인과관계를 주장하지 않는다.

| Day Rank | 제품과 출시 | 현재 사용 경로 | 현재 배포 신뢰 상태 | 상위권에서 보이는 포인트 |
| --- | --- | --- | --- | --- |
| #1 | [AltStore](https://www.producthunt.com/products/altstore-io), 2019 | 공식 사이트에서 AltServer ZIP 다운로드 후 단계별 iPhone 설정 | 2026-08-02 공식 AltServer를 직접 검사한 결과 Developer ID 서명, `spctl` 승인, 유효한 stapled ticket | `Sideloading for Everyone`이라는 큰 결과부터 말한다. SideRefresh와 기능적으로 가장 가까운 사례다. |
| #1 | [Maccy](https://www.producthunt.com/products/maccy?launch=maccy), 2019 | [GitHub Release](https://github.com/p0deje/Maccy/releases/tag/2.7.0), Homebrew, Mac App Store | 현재 `2.7.0` 앱은 Developer ID 서명, `spctl` 승인, 유효한 stapled ticket | `Lightweight. Open source. No fluff.`처럼 제품 성격을 세 구절로 끝내고 다운로드를 바로 제공한다. |
| #1 | [Kilo Code for VS Code](https://www.producthunt.com/products/kilocode), 2026 | VS Code·JetBrains marketplace, npm·curl·Homebrew CLI | IDE extension/CLI이므로 macOS Developer ID 비교 대상이 아님. 공식 [README](https://github.com/Kilo-Org/kilocode/blob/c554409080a59422066f93df90155e448ec9b250/README.md#installation)에서 실행 환경별 설치를 바로 선택 | Agent 시대의 언어, 기존 사용자 규모, 여러 실행 환경과 바로 설치 가능한 버튼을 한 화면에 결합한다. |
| #2 | [Sol](https://www.producthunt.com/products/sol-2), 2022 | [GitHub Release](https://github.com/ospfranco/sol/releases/tag/2.1.348), Homebrew | 현재 `2.1.348` 앱은 Developer ID 서명, `spctl` 승인, 유효한 stapled ticket | Maker가 기능이 아직 제한적이라고 정직하게 밝히면서도 `open source macOS command palette`라는 비교 가능한 범주를 즉시 제시했다. |
| #2 | [Zed 1.0](https://www.producthunt.com/products/zed), 2026 | 공식 architecture별 DMG, Homebrew, 자동 업데이트 | 현재 [v1.13.1](https://github.com/zed-industries/zed/releases/tag/v1.13.1) Apple Silicon DMG를 검사한 결과 Developer ID 서명, `spctl` 승인, DMG의 유효한 stapled ticket. 공식 [release workflow](https://github.com/zed-industries/zed/blob/90d024b88abc91264d9a0ad260eb4f365fa695c3/.github/workflows/release.yml)도 인증서와 공증 자격증명을 사용 | `high-performance, open source, multiplayer code editor`처럼 성능·공개성·핵심 차이를 한 문장에 결합하고 다운로드와 소스를 분리한다. |
| #2 | [Osaurus](https://www.producthunt.com/products/osaurus), 2026 | [DMG](https://github.com/osaurus-ai/osaurus/releases/tag/0.22.14), Homebrew | 현재 `0.22.14` 앱은 Developer ID 서명과 `spctl` 승인을 통과하고 DMG에 유효한 ticket이 있다. [release workflow](https://github.com/osaurus-ai/osaurus/blob/757807f981686de08a56448a414b7649dc730383/.github/workflows/build-and-release.yml)는 signing 검증과 공증을 별도 gate로 둔다. | `Open source agents that run 100% locally on your Mac`으로 대상·동작·privacy를 한 번에 말하고, stars·downloads와 `no account`를 신뢰 증거로 사용한다. |
| #4 | [Ollamac](https://www.producthunt.com/products/ollamac/awards), 2023 | [DMG](https://github.com/kevinhermawan/Ollamac/releases/tag/v3.0.3), Homebrew | 현재 `v3.0.3` 앱은 Developer ID 서명, `spctl` 승인, 유효한 stapled ticket | 복잡한 로컬 모델 기술보다 `a macOS app for interacting with Ollama models`라는 사용 목적을 먼저 보여준다. |
| #6 | [Mirror](https://www.producthunt.com/products/mirror-14), 2025 | 공식 GitHub에서 Xcode로 직접 빌드 | GitHub Release가 없고, [README](https://github.com/ajagatobby/mirrow/blob/0b6a48c72104547edf40bc62f29c6da0c87a9b7e/README.md#-installation)는 local signing·ad-hoc·unsigned 개발 빌드를 설명 | source-build-only도 Top 10에 들 수 있다는 반례다. `Detect hidden apps on macOS`처럼 문제와 결과가 매우 즉각적이다. |
| #7 | [Hacker News for macOS](https://www.producthunt.com/products/hacker-news-for-macos), 2026 | [DMG](https://github.com/IronsideXXVI/Hacker-News/releases/tag/v1.8.5), Sparkle 자동 업데이트 | 현재 `v1.8.5` 앱은 Developer ID 서명, `spctl` 승인, 유효한 stapled ticket. [workflow](https://github.com/IronsideXXVI/Hacker-News/blob/eae9490309a34d7dbc56f1c649aa2f887e7f7e6b/.github/workflows/release.yml)는 앱과 DMG의 signing·notarization·stapling을 모두 검증 | README가 `DMG를 받고 Applications에 드래그하면 끝`이라고 명확히 약속하며 native·open source·no tracking을 보조 신뢰 신호로 둔다. |
| #10 | [Open Caffeine](https://www.producthunt.com/products/open-caffeine), 2026 | [v1.0.2 ZIP](https://github.com/sapsaldog/open-caffeine/releases/tag/v1.0.2) | 앱은 ad-hoc 서명, `spctl` 거부, ticket 없음. 공식 [README](https://github.com/sapsaldog/open-caffeine/blob/a01b506961c82138b700296e26a7ee08e7276e13/README.md)는 code signing이 없다고 명시 | 미서명 앱도 Top 10이 가능하다는 최신 반례다. 다만 `Keep your Mac awake`처럼 누구나 즉시 이해하는 단일 기능이다. |

### Top 10 표본에서 확인되는 것

- 10개 모두 tagline 한 줄에서 제품의 범주나 사용 결과를 이해할 수 있고, 내부
  구현 세부사항을 앞세우지 않는다.
- 독립 실행형 Mac 바이너리를 현재 직접 제공하는 8개 중 7개는 조사 시점에
  `Notarized Developer ID`로 Gatekeeper 승인을 받았다.
- 나머지는 marketplace·CLI 중심인 Kilo Code, source-build-only인 Mirror,
  ad-hoc 배포인 Open Caffeine이다.
- 따라서 서명·공증은 Top 10의 필요조건은 아니지만, **정상적인 직접 다운로드를
  계속 운영하는 상위권 제품의 지배적인 현재 패턴**이다.
- source-only Mirror와 unsigned Open Caffeine의 존재 때문에 `서명해야 Top 10에
  든다`고 말할 수는 없다. 반대로 이 두 사례만으로 SideRefresh처럼 Apple
  Account와 iPhone을 다루는 앱의 신뢰 비용을 무시할 수도 없다.

### SideRefresh에 적용할 상위권 패턴

SideRefresh는 AltStore의 문제 영역과 Kilo Code·Osaurus의 Agent 이용자 언어가
겹치는 위치에 있다. 제품의 첫 문장은 내부 메커니즘이 아니라 이미 정한 결과를
유지한다.

> Keep agent-built iOS apps alive on your iPhone.

그 다음 계층에서 `Mac + Xcode + Apple Account Personal Team`, 7일 갱신 이유와
첫 USB 연결을 정확히 설명한다. Product Hunt gallery는 다음 순서가 적합하다.

1. 결과: Agent가 만든 앱을 iPhone에서 계속 사용
2. 3단계 흐름: Xcode project → SideRefresh → iPhone
3. 실제 Simple workspace: Renewal condition과 Next action
4. 요구사항과 정직한 제한: 앱 1개 × iPhone 1대
5. 신뢰: open source, local processing, signed and notarized Mac download

Top 10 사례는 Product Hunt를 당장 제출해야 한다는 근거가 아니라, 주 출시에서
무엇을 가장 먼저 보여줘야 하는지에 대한 근거다. source-only beta는 GitHub에서
먼저 검증하되 Product Hunt의 주 launch는 AltStore·Maccy·Osaurus와 같은 정상
다운로드 상태의 `v0.2.0`에 사용한다.

## 가장 가까운 제품: AltStore

[AltStore의 Product Hunt 출시](https://www.producthunt.com/products/altstore-io)는
2019년 일간 1위를 기록했다. AltStore 역시 Mac의 helper, Apple ID, iPhone 연결과
신뢰, Wi-Fi 동기화, Developer Mode 등 Apple이 정한 여러 단계를 설명해야 하는
제품이다. [AltStore 공식 GitHub](https://github.com/altstoreio/AltStore)

그 Product Hunt 댓글에서는 제품의 효용보다 먼저 특수 installer, 개인정보,
Apple ID와 암호를 왜 요구하는지가 질문으로 나왔다. 이는 SideRefresh에도 그대로
적용될 가능성이 높다. Product Hunt gallery와 README는 기능 목록보다 먼저 다음을
설명해야 한다.

- SideRefresh가 Apple Account 암호를 수집하지 않는다는 점
- Xcode의 Personal Team이 무엇이며 왜 7일 뒤 다시 설치해야 하는지
- Mac, Xcode, Apple Account, 첫 USB 연결이 필요한 이유
- 어떤 소스·기기·서명 정보를 읽고 어디에 저장하는지
- SideRefresh의 Developer ID는 Mac 앱 배포자의 인증서이며, 사용자의 개인 iOS
  앱에 유료 Apple Developer Program 가입을 요구하는 것이 아니라는 점

AltStore는 타인의 IPA와 대체 앱스토어까지 다루므로 SideRefresh와 제품 범위는
다르다. SideRefresh는 **Agent-made personal app 1개 × iPhone 1대**라는 더 작은
약속을 유지해야 한다.

## 관찰된 출시 패턴

### Product Hunt 등록 가능성과 Gatekeeper 품질은 독립적이다

Product Hunt에 실제 출시된 표본에는 다음 세 형태가 모두 존재했다.

1. ad-hoc 또는 개발 인증서 배포와 Gatekeeper 복구 안내
2. 소스와 바이너리는 제공하지만 공증하지 않은 배포
3. Developer ID 서명·공증된 ZIP/DMG와 선택적 Homebrew·App Store 배포

그러므로 `Product Hunt에 등록하려면 Developer ID가 필요하다`는 설명은 틀리다.
정확한 설명은 `SideRefresh 안정판을 사용자가 정상적으로 신뢰하고 실행하게 하기
위해 Developer ID를 출시 게이트로 선택했다`이다.

### 소스 공개와 즉시 사용 가능한 제품은 별개의 자산이다

오픈소스라는 사실만으로 사용자가 앱을 체험할 수 있는 것은 아니다. 비교 제품은
대체로 README 첫 화면에서 다운로드를 바로 제공하고, 그 다음에 소스 빌드나
기여 방법을 둔다. SideRefresh도 다음 두 진입점을 분리해야 한다.

- **Use SideRefresh:** 서명·공증된 안정판 다운로드
- **Build or contribute:** 공개 소스, 개발 환경과 빌드 절차

소스 전용 beta는 기여자와 초기 검증 사용자에게는 유효하지만, 큰 Product Hunt
출시의 기본 경로로 쓰지 않는다.

### `Open Anyway`는 지원 비용으로 돌아온다

GitSync와 MacMonitor는 설치 가능하지만 정상적인 Gatekeeper 승인 대신 시스템
설정이나 quarantine 제거를 안내한다. SideRefresh에서 같은 방식을 택하면 다음
질문이 제품의 핵심 가치보다 먼저 나온다.

- 이 앱 자체를 믿어도 되는가?
- 왜 보안 경고를 우회해야 하는가?
- iPhone과 Apple Account를 다루는 앱이 왜 공증되지 않았는가?
- 업데이트 파일도 같은 제작자가 만든 것인지 어떻게 확인하는가?

이 비용은 무료 Personal Team, 기기 신뢰, Developer Mode와 background item
승인 설명 위에 추가된다. SideRefresh의 단순한 Setup flow와 정면으로 충돌한다.

### 서명 용어를 정확히 구분해야 한다

- `codesign --verify`가 성공해도 ad-hoc 서명일 수 있다.
- `Apple Development` 서명은 개발·기기 테스트용이며 외부 Mac 배포용 Developer
  ID가 아니다.
- Sparkle EdDSA 서명은 업데이트 무결성을 보호하지만 Gatekeeper 신뢰를 만들지
  않는다.
- 안정판의 기대 상태는 `Developer ID Application + hardened runtime + secure
  timestamp + Apple notarization + stapled ticket + Gatekeeper acceptance`이다.

## SideRefresh 출시 판단

### 지금 할 수 있는 것

- 공개 저장소와 source-only prerelease 준비
- 영문·한국어 README, 요구사항, 3단계 Setup flow, 보안·개인정보 설명 준비
- Product Hunt draft, thumbnail, gallery, maker comment와 데모 준비
- Developer ID가 없어도 소규모 사용자에게 소스 beta를 공개해 제품 약속 검증

### Developer ID 이후 할 것

- exact release archive의 nested executable과 outer app을 Developer ID로 서명
- hardened runtime과 secure timestamp 확인
- Apple 공증, ticket stapling, `spctl` 검증
- 깨끗한 Mac 계정에서 다운로드부터 첫 실행까지 검증
- checksum과 provenance를 포함한 immutable `v0.2.0` 공개
- 공개 자산을 다시 다운로드해 같은 검증을 통과한 뒤 Product Hunt 날짜 확정

### 권장하지 않는 fallback

MacMonitor처럼 quarantine을 지우거나 `Open Anyway`를 정상 설치 경로로 문서화하면
Product Hunt에는 제출할 수 있다. 그러나 이는 SideRefresh의 첫 안정판 계약과
현재 명세의 `Gatekeeper를 우회하거나 quarantine을 제거하도록 안내하지 않는다`는
결정에 어긋난다. 인증서 준비가 늦어지면 큰 Product Hunt 출시를 앞당기지 말고
source-only beta 기간을 늘리는 편이 일관된다.

## 최종 답

- **Product Hunt 조건인가?** 아니다.
- **Developer ID 없이 등록된 실제 앱이 있는가?** 있다. Open Caffeine,
  MacMonitor, CodexBar Lite와 GitSync가 직접적인 사례다.
- **Developer ID를 준비할 이유가 사라졌는가?** 아니다. 이는 Product Hunt 심사를
  위한 서류가 아니라 SideRefresh 다운로드의 신뢰·전환·지원 비용을 위한 것이다.
- **SideRefresh는 언제 Product Hunt에 올리는가?** 소스 beta는 먼저 공개할 수
  있지만, 주 출시는 서명·공증된 `v0.2.0`의 공개 다운로드 재검증 뒤에 한다.
