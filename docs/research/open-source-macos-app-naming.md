# 오픈소스 macOS 앱 이름 조사

조사일: 2026-07-25

## 결론

**추천 제품명은 `SideRefresh`**, GitHub 저장소명은 **`side-refresh`**다.

권장 표기:

- 앱: **SideRefresh**
- 저장소: **`side-refresh`**
- 한국어 설명: **개인용 iOS 앱 자동 갱신 도구**
- 영문 설명: **Automatic iOS app refresh from your own Xcode source**
- 한국어 태그라인: **Personal Team 앱을 만료 전에 다시 설치하세요.**

`SideRefresh`는 sideload한 개인 개발 앱을 갱신한다는 핵심을 가장 빨리 전달한다. App
Store나 탈옥, 특정 VPN, AltStore를 이름에 직접 넣지 않으며 Swift뿐 아니라
Flutter·Expo·Kotlin처럼 최종적으로 Xcode 프로젝트를 빌드하는 흐름에도 어울린다.
`사이드리프레시`로 읽기 쉽고 메뉴 막대 유틸리티 이름으로도 짧다.

단, 아래 조사는 상표·법률 검토가 아니며 Apple의 이름 사용 승인을 보장하지 않는다.

## Top 3

| 순위 | 이름 | 저장소 | 장점 | 주의점 |
|---|---|---|---|---|
| 1 | **SideRefresh** | `side-refresh` | sideload + refresh로 페인포인트와 실제 사용자 용어가 바로 보인다. | SideStore Shortcut이나 파생 제품으로 오해하지 않도록 “refresh from your own Xcode source” 설명이 필요하다. |
| 2 | **DevRenew** | `devrenew` | 개인 개발 빌드의 갱신이라는 범위를 정확히 잡는다. 제품과 저장소 양쪽에 무난하다. | 처음 보는 사람에게 무엇을 갱신하는지는 덜 명확하다. |
| 3 | **KeepSigned** | `keepsigned` | 사용자가 얻는 결과가 보이고 특정 전송 방식에 종속되지 않는다. | “로그인 상태 유지”나 기존 `StaySigned`와 연상될 수 있다. |

2026-07-25 기준 GitHub 저장소명 검색에서
[`SideRefresh`](https://github.com/search?q=SideRefresh+in%3Aname&type=repositories),
[`DevRenew`](https://github.com/search?q=DevRenew+in%3Aname&type=repositories),
[`KeepSigned`](https://github.com/search?q=KeepSigned+in%3Aname&type=repositories)은
정확히 같은 이름의 저장소가 발견되지 않았다. 공개 App Store 웹 검색에서도 이 세
이름의 정확한 앱 결과는 찾지 못했다
([SideRefresh](https://itunes.apple.com/search?term=SideRefresh&entity=software&country=us&limit=50),
[DevRenew](https://itunes.apple.com/search?term=DevRenew&entity=software&country=us&limit=50),
[KeepSigned](https://itunes.apple.com/search?term=KeepSigned&entity=software&country=us&limit=50)).
이는 미국 스토어 공개 검색의 관찰일 뿐, 이름 확보나 법률적 사용 가능성을 뜻하지
않는다.

## 후보 비교

평가는 5점 만점의 상대평가다. “충돌”은 공식 사이트, App Store, GitHub 저장소 이름을
중심으로 본 실무적 신호이며 상표 검색은 아니다.

| 후보 | 설명력 | Mac 앱 느낌 | 한국어 발음 | 충돌/오해 위험 | 판단 |
|---|---:|---:|---:|---:|---|
| **SideRefresh** | 5 | 4 | 5 | 중간 | **최종 추천** |
| **DevRenew** | 4 | 4 | 5 | 낮음 | 좋은 대안 |
| **KeepSigned** | 4 | 4 | 4 | 중간 | 좋은 브랜드형 대안 |
| **ProvisionLoop** | 5 | 3 | 3 | 낮음 | 개발자 지향 대안 |
| **RenewRelay** | 3 | 4 | 4 | 낮음 | 네트워크 중계 도구처럼 들리고 실제 핵심인 빌드·서명이 흐려진다. |
| **AppLifeline** | 3 | 4 | 4 | 낮음 | 친근하지만 iOS 개발 도구라는 단서가 없다. |
| **SignAgain** | 4 | 3 | 5 | 중간 | 수동 단발성 재서명 도구처럼 들린다. |
| **WeekSign** | 4 | 3 | 4 | 중간 | 7일 제한은 드러나지만 GitHub에 동명 저장소가 있고 출석/전자서명으로도 읽힌다. |
| **SignLoop** | 5 | 4 | 4 | 중간 | 의미는 좋지만 [GitHub에 여러 동명 저장소](https://github.com/search?q=SignLoop+in%3Aname&type=repositories)가 있다. |
| **ios-auto-renewal** | 5 | 1 | 3 | 중간 | 저장소의 기능 설명에는 좋지만 제품명보다는 패키지/스크립트명 같고 플랫폼명을 브랜드 전면에 둔다. |

### 제외하는 이름

- **ReProvision**: 이미 “무료 인증서의 7일 만료를 피하기 위한 자동
  re-provisioning”을 표방한 [동명 오픈소스 프로젝트](https://github.com/Matchstic/ReProvision)가
  있다. 기능 영역까지 거의 같다.
- **ReSign / Resign**: 일반 용어에 가깝고, 이미
  [macOS IPA 재서명 유틸리티](https://github.com/LigeiaRowena/Resign)를 비롯한 동명
  저장소가 매우 많다.
- **StaySigned**: 이름의 메시지는 가장 좋지만
  [기존 채용 소프트웨어 회사와 제품](https://www.staysigned.com/about/)이 정확한
  이름을 사용한다.
- **RenewDock**: GitHub 저장소 충돌은 적지만
  [동명의 공개 App Store 앱](https://apps.apple.com/us/app/renewdock/id6782606919)이
  이미 있다.

## `SideRefresh`가 담아야 할 경계

AltStore는 스스로를 비탈옥 iOS용 대체 앱 스토어라고 설명하며, 개인 개발 인증서로
앱을 재서명하고 같은 Wi‑Fi의 AltServer를 통해 주기적으로 갱신한다
([AltStore 공식 저장소](https://github.com/altstoreio/AltStore)). SideStore 역시
AltStore의 포크이자 “alternative app store”이며 VPN 기반 앱 설치·백그라운드 갱신을
핵심으로 내세운다
([SideStore 공식 저장소](https://github.com/SideStore/SideStore)).

현재 제품은 앱 스토어나 IPA 카탈로그가 아니라 **사용자가 소유한 Xcode 소스
프로젝트를 다시 빌드하고 설치하는 Mac 자동화 도구**다. `SideRefresh`는 이 페인포인트를
가장 짧게 전달하지만 SideStore의 파생 제품이나 일반 IPA 사이드로더로 오해될 여지가
있다. README, 앱 첫 화면, 저장소 설명에 “Builds your own Xcode projects; not an app
store”를 명시해야 한다. Wi‑Fi, USB, Tailscale은 수단일 뿐 이름이나 로고의 중심으로
두지 않는다.

## “이 이름으로 macOS 앱 등록”의 두 가지 의미

먼저 이름을 쓰는 것과 Apple 배포 등록은 분리해야 한다.

| 대상 | 지금 가능한가 | Apple 이름 예약인가 |
|---|---|---|
| 로컬 `.app` 표시 이름 | 가능. 빌드 설정/번들 메타데이터에 쓰면 된다. | 아니오 |
| GitHub 저장소 `side-refresh` | 해당 저장소명이 비어 있으면 가능 | 아니오 |
| App Store Connect의 `SideRefresh` | 유료 Apple Developer Program 가입 후 앱 레코드를 생성해야 확인 가능 | 예, 현지화별 이름을 앱 레코드가 점유 |
| Developer ID 서명·notarization | 유료 프로그램 가입 후 가능 | App Store 이름 예약과 무관 |

### 1. App Store Connect 이름 등록

Apple의 현재 규칙은 다음과 같다.

- 앱 이름은 2자 이상 30자 이하여야 하고 현지화할 수 있다
  ([App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)).
- Apple은 단순하고 기억하기 쉬우며 기능을 암시하는 고유한 이름을 권장하고, 기존 앱과
  지나치게 비슷한 이름을 피하라고 한다
  ([Creating Your Product Page](https://developer.apple.com/app-store/product-page/)).
- 이름은 **현지화별로 한 앱만** 사용할 수 있다. 다른 개발자가 사용 중이면 상표권
  주장을 제외하고 그 이름을 바로 가져올 수 없다
  ([Add a new app](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)).
- 앱 레코드를 삭제하면 이름 소유권을 잃고, 다른 개발자가 가져가면 복원도 불가능하다
  ([Remove an app](https://developer.apple.com/help/app-store-connect/create-an-app-record/remove-an-app/)).

따라서 공개 App Store와 GitHub 검색만으로는 `SideRefresh`의 사용 가능성을 확정할 수
없다. 미출시 App Store Connect 레코드도 이름을 점유할 수 있기 때문이다. Apple의 공식
절차상 최종 확인은 유료 프로그램 계정에서 macOS 플랫폼의 새 앱 레코드를 만들며
`Create` 결과를 확인하는 것이다. **레코드를 실제 생성하지 않고 이름을 확정적으로
예약하거나 판정하는 별도 공개 조회 도구는 공식 문서에서 확인되지 않았다.**

### 2. 현재 구조를 Mac App Store에 배포

**현재 구조 그대로는 Mac App Store보다 Developer ID + notarization 외부 배포가
현실적이다.**

Mac App Store 앱은 App Sandbox가 필수다
([Protecting user data with App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox)).
사용자가 `NSOpenPanel`로 고른 프로젝트 폴더는 보안 범위 북마크로 지속 접근할 수
있으므로 “수동 프로젝트 선택” 자체는 샌드박스 안에서도 설계 가능하다. 반면 Apple은
샌드박스 앱이 사용자 선택 파일 권한만으로 앱 번들·컨테이너·앱 그룹 바깥의 프로그램을
실행할 수 없다고 명시한다
([Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)).

이 제품의 핵심은 외부의 `xcodebuild`, `devicectl`, 선택적으로 `tailscale`을 실행하고,
사용자 홈의 프로젝트를 발견하며, 사용자 프로젝트의 빌드 스크립트까지 구동하는 것이다.
이는 현재 샌드박스 모델과 직접 충돌한다. App Review 지침도 Mac App Store 앱에
샌드박스, 자기완결적 앱 번들, 공유 위치에 코드 설치 금지, 외부 앱·코드 설치 금지를
요구한다
([App Review Guidelines 2.4.5, 2.5.2](https://developer.apple.com/app-store/review/guidelines/)).

`SMAppService` 자체는 macOS 13부터 번들 내부 Login Item·LaunchAgent 등록을 지원하고
사용자 승인을 전제로 한다
([SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)).
하지만 LaunchAgent를 쓸 수 있다는 사실이 외부 CLI 실행과 광범위한 홈 디렉터리 접근을
허용하지는 않는다. 즉 백그라운드 자동화의 등록 방법은 공식적이어도, 핵심 작업 권한은
별도 문제다.

권장 배포 순서는 다음과 같다.

1. 지금은 **`SideRefresh` 이름으로 공개 GitHub 저장소와 소스 빌드**를 제공한다.
2. 사용자 테스트로 제품과 이름을 검증한다.
3. 배포 준비 시 Apple Developer Program에 가입한다.
4. 앱을 Developer ID로 서명하고 hardened runtime을 적용한 뒤 notarization하여 GitHub
   Releases 또는 공식 사이트로 배포한다.

Apple은 Mac App Store 밖의 소프트웨어에 Developer ID 서명과 notarization을 제공하며,
notarization은 악성 코드와 서명 문제를 자동 검사한다
([Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)).

현재처럼 유료 Apple Developer 등록이 없다면 로컬 개발과 개인 기기 테스트는 가능하지만,
App Store Connect 배포 및 Developer ID/notarization은 사용할 수 없다. Apple의 비교표는
App 배포, App Store Connect, Developer ID와 notarization을 유료 Apple Developer
Program 혜택으로 구분하며, 연회비를 99 USD로 안내한다
([Choosing a Membership](https://developer.apple.com/support/compare-memberships/)).
따라서 당장은 오픈소스 소스 배포가 가능하고, 일반 사용자가 경고 없이 설치할 서명된
바이너리 배포는 가입 이후 단계다.

## 최종 결정

**제품명은 `SideRefresh`로 통일한다.**

제품 소개 문구는 `Assets/Brand/README.md`의 Product copy를 기준으로 한다.

> 개인용 iOS 앱 자동 갱신 도구
>
> Automatic iOS app refresh from your own Xcode source
>
> Personal Team 앱을 만료 전에 다시 설치하세요.

공개 배포 범위를 넓히기 전 다음 세 가지를 한 번 더 확인한다.

1. GitHub 조직 또는 저장소 `side-refresh` 생성 가능 여부
2. 도메인과 주요 소셜 핸들 사용 가능 여부
3. 유료 개발자 등록 후 App Store Connect의 실제 앱 레코드 생성 결과 및 별도의 상표 검토
