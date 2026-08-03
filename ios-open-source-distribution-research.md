# iOS 무료 서명·오픈소스 설치 도구 조사

조사일: 2026-07-24 · 범위: **Apple Developer Program 미등록 상태**에서 본인 앱을 설치하거나 다른 사람에게 배포하려는 경우. 프로젝트의 공식 문서·소스 저장소와 Apple의 문서를 우선 확인했다.

## 결론

**오픈소스 도구만으로 `무료 + 일반 사용자 배포 + 신뢰/개발자 모드 없음 + 7일 만료 없음`을 동시에 만족시키는 정상 경로는 없다.** Apple은 무료 `Personal Team`을 *본인 기기에서의 테스트*로 한정한다. App ID 10개, 플랫폼별 기기 3대, 기기 설치 앱 3개이며, 설치용 프로비저닝 프로파일은 7일에 만료된다. 앱 배포와 App Store Connect는 Developer Program 멤버십 기능이다. [Apple: 계정/Personal Team 제한](https://developer.apple.com/help/account/basics/about-your-developer-account) · [Apple: 멤버십 비교](https://developer.apple.com/support/compare-memberships/)

따라서 다음처럼 판단한다.

- **내 iPhone 한두 대에서만 개발·테스트:** Xcode `Personal Team`이 가장 단순하다. 갱신 자동화가 필요하면 SideStore 또는 AltStore Classic을 검토할 수 있지만, 이는 *배포*가 아니라 개인 개발 서명 관리의 편의 도구다.
- **다른 사람에게 테스트/배포:** 등록 후 **TestFlight**가 권장 경로다. 테스터의 UDID·프로비저닝 프로파일을 관리할 필요가 없고 외부 테스터는 최대 10,000명까지 초대할 수 있다. [Apple: TestFlight](https://developer.apple.com/testflight/)
- **현재 한국에서 미등록 상태:** 아래의 EU·일본·브라질 대체 배포 제도도 적용 대상이 아니며, 어느 경우든 미등록 상태를 해결하지 않는다.

`신뢰하지 않는 개발자`와 개발자 모드는 로컬 개발 서명 앱의 보안 확인이다. Apple은 Xcode 실행·IPA 로컬 설치에 개발자 모드를 요구하며, App Store와 TestFlight에는 적용하지 않는다고 설명한다. [Apple: Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

## 비교

| 방법 | 소스/라이선스 확인 | 무료 Personal Team에서의 실제 동작 | 신뢰·개발자 모드 / 7일 만료 | 내 앱을 타인에게 일반 배포? | 판단 |
| --- | --- | --- | --- | --- | --- |
| **AltStore Classic + AltServer** | 공개 소스, AGPL-3.0. [공식 저장소](https://github.com/altstoreio/AltStore) | Apple ID의 개인 개발 인증서로 재서명하고, Mac의 AltServer가 Wi‑Fi 동기화로 설치·갱신한다. 같은 Wi‑Fi의 AltServer가 있어야 백그라운드 갱신을 시도한다. [프로젝트 README](https://github.com/altstoreio/AltStore#readme) | **남는다.** 호스트/앱은 무료 프로파일의 7일 한계를 따른다. 최초 로컬 설치의 신뢰·개발자 모드도 배제하지 못한다. | 아니오. 각 사용자가 각자 서명·설정해야 한다. | PC/Mac을 켜 둔 개인 테스트 용도라면 선택 가능. |
| **SideStore** | 공개 소스, AGPL-3.0. [공식 저장소](https://github.com/SideStore/SideStore) | 개인 개발 인증서로 재서명하며, 특수 VPN과 온디바이스 방식으로 AltServer 없이 갱신하는 것을 목표로 한다. [프로젝트 설명](https://github.com/SideStore/SideStore#readme) | **남는다.** 공식 설치 문서에도 개발자 신뢰, 개발자 모드, `7 DAYS` 갱신이 명시돼 있다. [SideStore 설치 문서](https://docs.sidestore.io/docs/installation/install) | 아니오. 사용자별 Apple 계정·기기 설정이 필요하다. | 무료 개인용 중에는 가장 실용적일 수 있으나, 네트워크·페어링 파일·갱신 상태를 감수해야 한다. |
| **LiveContainer** | 공개 소스. 저장소의 [`LICENSE`](https://github.com/LiveContainer/LiveContainer/blob/main/LICENSE)는 Apache-2.0을 명시하지만 GitHub 메타데이터는 AGPL-3.0으로 표시하므로, 재배포 전 라이선스를 별도 확인해야 한다. | 하나의 호스트 앱 안에서 여러 IPA를 실행하는 런처다. 프로젝트는 무료 계정의 3앱/10 App ID 제한을 호스트 하나로 줄일 수 있다고 설명한다. iOS 15+가 필요하며, 단독판은 AltStore 2.2.1+ 또는 SideStore 0.6.2+가 필요하다. [공식 설치 요구 사항](https://livecontainer.github.io/docs/installation) | **호스트의 신뢰·개발자 모드·7일 갱신은 남는다.** 게스트는 일반적으로 설치된 독립 앱도 아니다. | 아니오. 일반 사용자가 설치할 제품 배포 경로가 아니다. | 앱 확장·원격 푸시 등이 안 되고, 게스트 컨테이너 간 격리가 없으며 권한이 전역 적용된다. 민감한 자체 앱/타인 배포에 부적합하다. [프로젝트 한계](https://github.com/LiveContainer/LiveContainer#limitations) |
| **TrollStore** | 공개 소스, MIT(일부 파일 BSD 계열). [공식 저장소·라이선스](https://github.com/opa334/TrollStore) | 지원되는 취약 iOS에서 IPA를 영구 설치한다고 프로젝트가 설명한다. 지원 범위는 iOS 14.0 beta 2–16.6.1, 16.7 RC, 17.0으로 한정된다. [지원 범위/설명](https://github.com/opa334/TrollStore#readme) | 기술적으로는 7일 만료와 개발자 신뢰 문제를 피하지만, **보안 취약점에 의존**한다. | 아니오. 모든 수신자가 지원 OS·기기와 별도 환경을 갖춰야 한다. | 연구/개인 실험 외에는 권장하지 않는다. 설치·우회 절차는 이 문서에서 제공하지 않는다. |
| **탈옥 경로** | 예: Dopamine은 MIT 공개 소스이며 arm64e iOS 15.0–16.5.1, arm64 iOS 15.0–15.8.6/16.0–16.6.1만 표방한다. [Dopamine](https://github.com/opa334/Dopamine) · palera1n도 MIT 공개 소스지만 A8–A11 계열 등 하드웨어 제약이 있다. [palera1n](https://github.com/palera1n/palera1n) | 기기·OS·도구별로 가능 여부가 달라지는 보안 상태 변경이다. | 표준 신뢰/만료 모델 밖으로 갈 수 있으나, 정상 배포 UX가 아니다. | 아니오. 사용자가 개별적으로 기기 보안을 변경해야 한다. | 권장하지 않는다. Apple도 탈옥이 보안 취약점, 불안정성, 배터리 문제를 일으킬 수 있다고 경고한다. [Apple 경고](https://support.apple.com/guide/iphone/unauthorized-modification-of-ios-iph9385bb26a/ios) |
| **Sideloadly** | 공식 사이트에서 공개 소스 저장소나 라이선스 링크를 확인하지 못했다. 따라서 **오픈소스로 검증하지 않는다.** [공식 사이트](https://sideloadly.io/) | 무료 Apple ID로 설치·자동 재서명을 표방한다. | **남는다.** 자체 FAQ도 무료 계정 앱은 7일 유효라고 명시한다. [FAQ](https://sideloadly.io/faq) | 아니오. 사용자별 서명 도구일 뿐이다. | 기능상 AltStore 계열과 같은 개인 서명 관리 범주지만, 이 조사에서는 오픈소스 추천 대상에서 제외한다. |
| **ESign 및 제3자 인증서/서명 서비스** | `ESign`이라는 이름은 여러 비공식 배포물·미러가 섞여 있고, 검증 가능한 단일 공식 소스·라이선스를 확인하지 못했다. **오픈소스/공급망을 검증할 수 없는 범주**로 취급한다. | 본인 무료 자격 증명으로 서명한다면 Apple의 7일 제한은 동일하다. 제3자 인증서에 의존하면 인증서 소유자·폐기 여부에 앱 가용성이 종속된다. 즉 개발자가 서명 권한을 직접 관리하는 안정적 배포 구조가 아니다. Apple은 인증서·인증 정보를 공유하지 말고, 인증서는 임의 시점에 폐기될 수 있다고 안내한다. [Apple: 인증서 관리](https://developer.apple.com/support/certificates/) | 도구 자체가 제한을 제거하지 않는다. | 아니오. 개발자가 자신의 사용자에게 제공할 안정적·감사 가능한 배포 경로가 아니다. | 공유·폐기된 인증서, 불법 IPA 저장소, 우회 서비스는 사용·안내하지 않는다. |
| **iOS App Signer / ideviceinstaller** | 둘 다 공개 소스다: iOS App Signer는 GPL-3.0, ideviceinstaller는 GPL-2.0. [iOS App Signer](https://github.com/DanTheMan827/ios-app-signer) · [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller) | 전자는 IPA를 재서명하려면 프로비저닝 프로파일과 인증서가 필요하고, 후자는 연결 기기에 패키지를 설치하는 CLI다. [iOS App Signer 요구 사항](https://github.com/DanTheMan827/ios-app-signer#readme) · [ideviceinstaller 기능](https://github.com/libimobiledevice/ideviceinstaller#readme) | **남는다.** 서명 권한을 새로 만들거나 Apple 제한을 해제하지 않는다. | 아니오. | 서명/설치 보조 도구일 뿐, 배포 해결책은 아니다. |

### LiveContainer와 TrollStore를 “해결책”으로 보지 않는 이유

두 도구는 위의 앱 수·서명 제약을 기술적으로 줄이거나 회피할 수 있어 눈에 띈다. 그러나 LiveContainer는 앱을 호스트 내부에서 실행해 앱 확장, 푸시, 데이터 격리 등 iOS의 정상 앱 모델과 다르고, TrollStore/탈옥은 특정 취약 OS 또는 보안 변경을 요구한다. 즉 **내가 만든 앱을 일반 사용자의 최신 iPhone에 안정적으로 배포**하는 문제의 답이 아니다.

또한 iOS는 실행 코드에 Apple 발행 인증서 서명을 요구한다. 현재 App Store 밖의 공식 대체 배포도 EU·일본·브라질에서만 제공되고 공증 절차를 거친다. 오픈소스라는 사실은 소스 감사에는 도움이 되지만 이 플랫폼 제약이나 배포 권한을 부여하지 않는다. [Apple: 필수 코드 서명](https://support.apple.com/guide/security/app-code-signing-process-sec7c917bf14/web) · [Apple: 대체 배포 지역/공증](https://support.apple.com/en-us/117767)

## 공식 대체 배포의 지역 조건

현재 Apple이 명시한 iOS 대체 앱 배포 가능 지역은 **EU, 일본, 브라질**뿐이다. 사용자는 해당 지역에 실제로 있어야 하고 Apple Account의 국가/지역도 해당 지역이어야 한다. [Apple Support: 대체 배포 설치](https://support.apple.com/en-us/117767)

| 지역 | 현재 제도 | 미등록 상태를 해결하는가? | 한국 사용자에게의 의미 |
| --- | --- | --- | --- |
| **EU** | 대체 앱 마켓플레이스 및 웹 배포가 존재하지만, Apple의 대체 배포 약관·공증(notarization)·프로그램 요건을 따른다. 특히 직접 웹 배포는 개인·신규 개발자가 쓰기 어려운 조직/실적 요건이 있다. [EU 마켓플레이스](https://developer.apple.com/support/alternative-app-marketplace-in-the-eu/) · [EU 웹 배포](https://developer.apple.com/support/web-distribution-eu/) | 아니오. Apple Developer Program 및 해당 조건이 전제다. | 한국에서 이용할 수 없다. 물리적 위치와 계정 국가/지역 조건을 우회 대상으로 보아서는 안 된다. |
| **일본** | iOS 26.2+에서 공증된 앱의 대체 마켓플레이스 배포가 가능하다. 일반 앱의 직접 웹 배포가 아니라, 승인된 마켓플레이스를 통한 경로다. 마켓플레이스 운영자는 조직으로 Apple Developer Program에 가입하고 Apple 승인을 받아야 한다. [Apple: 일본 변화](https://developer.apple.com/support/app-distribution-in-japan) · [운영 요건](https://developer.apple.com/support/alternative-app-marketplace-jp/) | 아니오. 특히 마켓플레이스 운영은 고난도 조직 요건이며, 앱도 Program 회원의 공증된 앱이어야 한다. | 일본 소재·대상 조건이 있어 한국 내 배포 대안이 아니다. |
| **브라질** | iOS 26.5+에서 공증된 앱의 대체 마켓플레이스 배포/운영과 별도 결제 선택지가 있다. 일반 앱의 직접 웹 배포가 아니라, 승인된 마켓플레이스를 통한 경로다. [Apple: 브라질 변화](https://developer.apple.com/support/app-distribution-in-brazil) | 아니오. Program 약관 동의와 App Store Connect 도구가 필요하다. | 브라질 대상 제도이며 한국 배포 대안이 아니다. |
| **대한민국** | Apple이 한국에 명시한 것은 App Store에 이미 배포하는 앱의 제3자 인앱 결제 권한이다. [Apple: 한국 외부 결제](https://developer.apple.com/support/storekit-external-entitlement-kr/) | 아니오. 이는 앱 설치·대체 마켓플레이스 제도가 아니다. | 이 문제(미등록 상태의 IPA 설치/일반 배포)를 해결하지 못한다. |

## 실행 권고

1. **내 기기에서만 개발 중:** 프로젝트를 Xcode에서 Personal Team으로 실행하고, 매주 재빌드가 번거로울 때만 SideStore 또는 AltStore를 개인 편의 수단으로 검토한다. 신뢰·개발자 모드는 정상 보안 확인으로 받아들여야 한다.
2. **테스터나 지인에게 전달할 예정:** 가입 전에는 “한 번만 설치하면 계속 쓰는” 정상 배포를 약속하지 않는다. Developer Program 등록 후 TestFlight로 전환한다. Program은 연 US$99(지역 통화 제공 가능)이며, 비영리·공인 교육기관·정부 기관은 수수료 면제 대상일 수 있다. [가격/면제](https://developer.apple.com/help/account/membership/fee-waivers)
3. **정식 출시:** App Store(필요하면 Unlisted App)를 쓴다. 사내용 배포는 자격을 갖춘 조직의 Apple Business Manager/Enterprise 흐름을 별도로 검토한다. 무료 Personal Team을 다른 사용자용 배포 인증서처럼 쓰지 않는다.

이 문서는 인증서 공유·탈취, 폐기된 인증서 서비스, 불법 IPA/저작권 침해 앱, 취약점·탈옥 설치 절차를 다루지 않는다.
