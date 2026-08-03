# iPhone 원격·셀룰러 사용을 위한 현실적인 대안 조사

조사일: 2026-07-24
전제: 본인만 쓰는 네이티브 iOS 앱, **같은 물리 Wi‑Fi 없이** 원격/셀룰러에서 사용·업데이트하고 싶고 Tailscale을 계속 사용함. TrollStore·탈옥·취약점·공유/폐기 인증서·인증서 판매 서비스는 제외했다.

## 결론 먼저

**미등록 무료 Personal Team으로는 맞는 해법이 없다.** Apple은 무료 Apple Account를 Xcode의 개인 기기 테스트로만 두며, 기기 설치용 프로파일은 7일 후 만료되고 재빌드·재설치가 필요하다. TestFlight·Ad Hoc·App Store 배포는 Apple Developer Program에 가입해야 한다. [Apple: 계정/Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account) · [Apple: 멤버십 비교](https://developer.apple.com/support/compare-memberships/)

요구를 하나만 완화했을 때의 실용적인 답은 다음 둘이다.

1. **네이티브가 반드시 필요하다** → 개인 Apple Developer Program(연 US$99)에 가입 후 **TestFlight**. 같은 Wi‑Fi, 개발자 모드, AltStore, SideStore가 필요 없고 셀룰러에서도 설치·업데이트한다. 단 테스트 빌드는 90일 후 만료한다.
2. **웹으로 가능한 앱이다** → **PWA를 Tailscale 뒤의 HTTPS 서버로 제공**. iOS 서명·7일 만료 자체가 없어지며, iPhone이 셀룰러에서 Tailscale에 연결되어 있으면 Home Screen 웹 앱도 원격 서버를 쓴다. 이 경우가 무료·Tailscale 상시·원격이라는 원래 조건을 실제로 모두 만족하는 유일한 저위험 방향이다.

장기적으로 네이티브 앱을 계속 쓸 계획이라면 App Store의 **등록되지 않은 앱(Unlisted App)**도 더 완결된 선택지다. App Store 심사는 필요하지만 직접 링크로만 발견되게 하고, App Store 자동 업데이트를 쓸 수 있다.

## 비교

| 경로 | Apple 등록/비용 | 같은 Wi‑Fi 없이 셀룰러 사용 | 7일 문제 | 자동성 | 이 경우의 평가 |
| --- | --- | --- | --- | --- | --- |
| 무료 Personal Team + Xcode/AltStore | 없음 | 원격 자동은 불가 | 남음 | USB 또는 같은 로컬 Wi‑Fi 의존 | 탈락 |
| **PWA + Tailscale** | 없음 | 가능 | 없음 | 서버 배포 후 다음 로드에 반영 | 네이티브 요구가 낮으면 최적 |
| **TestFlight** | Program 연 US$99 | 가능 | 7일은 없음, **빌드 90일** | 내부 그룹에 새 빌드 자동 배포 가능 | 네이티브 개인용 최우선 |
| **App Store / Unlisted App** | Program 연 US$99 | 가능 | 없음 | App Store 자동 업데이트 | 장기 운영 최우선 |
| **Ad Hoc + HTTPS OTA** | Program 연 US$99 | 가능 | Personal Team 7일은 없음 | 원격 설치는 가능하나 자동 갱신 경로는 아님 | 1대의 비공개 IPA에만 차선 |
| Apple Configurator | 없음 또는 유료 서명 필요 | 불가(케이블) | 서명 만료는 그대로 | 불가 | 설치 보조일 뿐 |
| MDM / Enterprise | 조직 비용·자격 | 가능 | 조직용 | 가능할 수 있음 | 1인 개인 사용에는 부적합 |
| Feather/KSign 등 서명기 | 도구별 상이 | 일부 설치는 가능 | **서명 자격 증명의 만료를 못 없앰** | 공식 자동 갱신 아님 | 배포 해법 아님 |

## 1. 유료 등록 후 TestFlight — 네이티브 앱의 가장 단순한 답

Apple Developer Program은 연 **US$99**이며, TestFlight·Ad Hoc·App Store 배포 권한을 포함한다. 개인 또는 1인 사업자로 가입할 수 있다. [Apple: Program](https://developer.apple.com/programs/) · [Apple: 멤버십 상세](https://developer.apple.com/programs/whats-included/)

TestFlight는 Apple이 앱 설치·서명·업데이트 전송을 맡는다. 내부 테스터는 App Store Connect 사용자 최대 100명이고, 새 빌드를 내부 그룹에 자동 배포하도록 설정할 수 있다. 외부 테스터는 최대 10,000명이며 첫 외부 테스트 빌드는 Beta App Review가 필요할 수 있다. [Apple: 내부 테스터/자동 배포](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers) · [Apple: TestFlight 개요](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview)

한계는 **빌드당 90일**이다. 즉 7일 갱신 대신 90일 전에 새 빌드를 업로드해야 한다. 본인만 쓸 때도 내부 테스터로 두면 되며, iPhone과 Mac이 같은 Wi‑Fi일 필요가 없다. App Store·TestFlight 설치에는 로컬 개발 IPA용 Developer Mode가 적용되지 않는다. [Apple: Developer Mode 적용 범위](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

Tailscale은 이 경로와 충돌하지 않는다. 배포 전송을 Tailscale로 우회할 필요도 없고, 앱 안에서만 Tailscale의 사설 서버에 연결하면 된다.

**판정:** 네이티브 기능을 유지하면서 귀찮음을 최소화하려면 가장 균형이 좋다. 다만 “영구 설치”가 아니라 베타 배포라는 점은 받아들여야 한다.

## 2. App Store 또는 Unlisted App — 장기적으로는 가장 깔끔함

정식 App Store 앱은 iPhone에서 기본적으로 자동 업데이트되도록 설정되어 있으며 사용자가 끌 수 있다. [Apple Support: App Store 자동 업데이트](https://support.apple.com/en-ie/102629) 버전 심사와 Program 가입은 필요하지만, 7일/90일 만료와 개발자 모드가 없다.

앱을 검색 결과에 보이게 하고 싶지 않다면 **Unlisted App**을 요청할 수 있다. 등록되지 않은 앱은 카테고리·추천·차트·검색에는 나타나지 않고 직접 링크로만 접근한다. 단, 최종 배포 가능한 앱을 App Review에 제출해야 하며 링크를 가진 사람은 설치할 수 있으므로 앱 자체 인증을 넣어야 한다. [Apple: Unlisted App](https://developer.apple.com/support/unlisted-app-distribution/)

**판정:** 앱이 심사 기준을 충족하고 장기간 본인만 안정적으로 쓸 생각이면 가장 완결적이다. “완전히 비공개”가 아니라 “검색 비노출”이라는 점은 구분해야 한다.

## 3. 유료 Ad Hoc + HTTPS OTA — 원격 IPA 설치는 되지만 자동 갱신은 아님

Ad Hoc은 유료 멤버가 기기의 UDID를 계정에 미리 등록한 뒤, App ID·배포 인증서·등록 기기가 포함된 프로파일로 IPA를 내보내는 방식이다. Apple은 기기 종류별 멤버십 연도당 최대 100대 등록을 허용한다. [Apple: Ad Hoc 프로파일](https://developer.apple.com/help/account/provisioning-profiles/create-an-ad-hoc-provisioning-profile/) · [Apple: 기기 한도](https://developer.apple.com/help/account/devices/devices-overview/)

Xcode의 Ad Hoc/Development 내보내기에는 **OTA 설치용 manifest 포함** 옵션이 있으며, HTTPS에서 manifest와 IPA를 제공해 원격으로 설치하도록 구성할 수 있다. [Apple: Xcode 배포 흐름](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) 이때는 Tailscale이 아니라 일반 HTTPS 호스트를 쓰는 편이 iOS 시스템 설치기의 호환성 면에서 예측 가능하다. 새 Program 멤버십의 development/ad-hoc 앱은 첫 실행 때 `ppq.apple.com` 인증 확인을 위해 인터넷 접근도 필요하다. [Apple: PPQ 확인](https://developer.apple.com/help/account/provisioning-profiles/provisioning-profile-updates)

그러나 Apple 문서는 등록 기기 배포를 Xcode/Apple Configurator 설치로 설명하고, OTA manifest는 설치 **전송 방식**일 뿐 자동 원격 업데이터를 제공하지 않는다. 프로파일/인증서가 바뀌거나 만료되면 새 IPA를 만들어 사용자가 다시 설치해야 한다. [Apple: 등록 기기 배포](https://developer.apple.com/documentation/Xcode/distributing-your-app-to-registered-devices)

**판정:** “내 한 대에만 비공개 IPA를 원격 설치”에는 가능하지만, 자동 갱신 목적이라면 TestFlight보다 관리량이 많다.

## 4. Apple Configurator·MDM·Enterprise가 답이 아닌 이유

Apple Configurator는 케이블로 연결한 기기에 IPA를 추가하는 도구다. Apple의 등록 기기 배포 절차도 Xcode/Configurator 설치 시 기기를 Mac에 연결하도록 한다. [Apple: 등록 기기 설치](https://developer.apple.com/documentation/Xcode/distributing-your-app-to-registered-devices) 따라서 원격·셀룰러 갱신 방법이 아니며, Developer Mode와 유효한 서명을 대체하지 않는다. [Apple: Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)

MDM은 원격 앱 설치와 셀룰러 다운로드 제어를 지원하지만, 관리 대상은 App Store 앱 또는 Enterprise 앱이다. Enterprise manifest도 Enterprise Program 앱만을 전제로 한다. [Apple: 관리형 앱 설치](https://developer.apple.com/documentation/devicemanagement/installing-managing-updating-and-removing-apps)

Enterprise Program은 법인·직원 100명 이상·Apple 검증·사내 직원 전용 배포를 요구하고 연 US$299이다. 개인 한 명의 앱에는 해당하지 않는다. [Apple: Enterprise Program 자격](https://developer.apple.com/programs/enterprise/)

**판정:** MDM은 이미 조직 배포 자격이 있을 때의 운영 도구이지, 개인 Personal Team의 7일 제한을 해결하는 방법이 아니다.

## 5. Feather·KSign류 개인 서명기는 왜 해결책이 아닌가

Feather는 공개 소스 온디바이스 서명/설치 도구지만, 유효한 `.p12`와 `.mobileprovision` 쌍을 입력으로 받는다. 즉 도구가 Apple의 배포 권한이나 프로파일 갱신 권한을 새로 만들지 않는다. [Feather README](https://github.com/claration/Feather#readme) Personal Team 인증서/프로파일을 쓰면 7일 제한도 그대로이며, LocalDevVPN pairing 방식은 Tailscale과 iOS 단일 VPN 자리를 경쟁한다. [Feather 동작 방식](https://github.com/claration/Feather/blob/main/HOW_IT_WORKS.md) · [Tailscale: iOS 단일 VPN 제한](https://tailscale.com/docs/reference/faq/other-vpns)

유료 Program의 **본인 소유** Ad Hoc 인증서·프로파일로 IPA를 다시 패키징하는 보조 도구로는 쓸 수 있다. 그러나 개인키와 계정 자격 증명은 민감한 자산이므로 외부 서명 서버·공유 인증서·출처 불명 DNS/프로파일에 넣는 방식은 이 요구의 저위험 해법이 아니다. Apple도 Apple Account와 배포 인증서를 공유하지 말라고 명시한다. [Apple: 인증서 보안](https://developer.apple.com/support/certificates)

KSign이라는 이름의 배포물은 검증 가능한 단일 공식 소스·재현 가능한 빌드 경로를 확인하지 못했다. 따라서 이 보고서에서는 추천하지 않는다. 어느 서명 앱이든 유효한 본인 인증서·프로파일이 없으면 iOS 설치 권한을 만들 수 없다는 점은 동일하다.

## 6. 원격 USB/IP와 Tailscale 포크

Tailscale은 IP 네트워크 연결을 제공한다. 물리 USB 장치를 전달하는 기능은 아니며, Apple이 문서화한 iPhone 개발/IPA 설치 경로는 케이블 연결 또는 같은 Wi‑Fi의 Apple 기기 동기화다. [Tailscale: 기기 연결](https://tailscale.com/docs/how-to/connect-to-devices) · [Apple: Wi‑Fi 동기화](https://support.apple.com/guide/mac-help/wi-fi-syncing-mchlada1d602/mac)

따라서 USB-over-IP, AltStore의 Tailscale 포크, 원격 데스크톱 조합은 Apple이 지원하는 기기 전송 경로가 아니다. 이미 보고한 것처럼 AltStore는 Bonjour 발견뿐 아니라 Mac이 Apple 기기 동기화로 iPhone을 볼 것을 요구한다. 이 경로는 개인용 안정 자동화로 권하지 않는다. [AltStore 소스: RequestHandler](https://github.com/altstoreio/AltStore/blob/develop/AltServer/Connections/RequestHandler.swift)

## 7. PWA + Tailscale — 등록 없이 조건을 가장 잘 맞추는 설계

네이티브 iOS 기능이 절대적이지 않다면, 앱을 웹 클라이언트로 만들고 Home Screen 웹 앱(PWA)으로 설치하는 것이 서명 문제를 없앤다. iOS는 manifest가 있는 웹 앱을 Home Screen에 추가해 독립 앱처럼 열 수 있고, iOS/iPadOS 16.4 이상에서는 Home Screen 웹 앱에 표준 Web Push도 지원한다. Apple Developer Program 가입은 Web Push에 필요 없다. [WebKit: Home Screen 웹 앱/Web Push](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/) · [Apple: Web Push](https://developer.apple.com/documentation/UserNotifications/sending-web-push-notifications-in-web-apps-and-browsers)

Tailscale을 이미 쓰고 있다면 Mac·홈 서버·VPS의 웹 서버를 tailnet에 두고 MagicDNS 이름으로 연결할 수 있다. 브라우저 기능과 service worker를 안정적으로 쓰려면 HTTPS가 필요하므로, Tailscale HTTPS와 `*.ts.net` 인증서를 쓰거나 일반 공개 HTTPS 도메인을 쓴다. [Tailscale: MagicDNS](https://tailscale.com/docs/features/magicdns) · [Tailscale: HTTPS](https://tailscale.com/docs/how-to/set-up-https-certificates)

이 방식의 장점은 서버에 새 웹 버전을 배포하면 iOS IPA를 재서명·재설치할 일이 없다는 것이다. 단, PWA는 네이티브 앱과 동일하지 않다. 백그라운드 실행, 일부 하드웨어/API, 파일 처리, 푸시/오프라인 동작은 기능별로 검증해야 한다.

### 기존 Kotlin Android 앱을 살리는 정도

- **Kotlin/JS + 웹 UI:** Kotlin 도메인·데이터 로직을 웹에 공유하기에 안정적인 경로다. [Kotlin: Web 개요](https://kotlinlang.org/docs/web-overview.html)
- **Kotlin/Wasm + Compose Multiplatform:** UI까지 공유할 수 있지만 Compose Multiplatform의 웹(Wasm) 타깃은 현재 Beta다. Android 전용 API·라이브러리는 그대로 공유되지 않는다. [Kotlin: KMP FAQ](https://kotlinlang.org/docs/multiplatform/faq.html) · [Android 전용 API 한계](https://kotlinlang.org/docs/multiplatform/compose-android-only-components.html)
- **Expo 웹/Flutter 웹:** 각각 React/TypeScript, Dart 기반이므로 기존 Kotlin Android UI를 그대로 가져오는 도구가 아니라 사실상 웹 클라이언트 재작성이다. Expo와 Flutter 모두 PWA/웹 배포는 지원한다. [Expo PWA](https://docs.expo.dev/guides/progressive-web-apps/) · [Flutter 웹 배포](https://docs.flutter.dev/deployment/web)

**판정:** 현재 Android 앱이 서버 API 중심이고 iOS 전용 네이티브 기능이 적다면, 작은 PWA를 먼저 만들어 Tailscale을 통해 쓰는 것이 비용·마찰이 가장 낮다. 반대로 카메라·Bluetooth·백그라운드 처리·시스템 통합이 핵심이면 PWA 포팅 비용이 커질 수 있으므로 TestFlight가 맞다.

## 권고 순서

1. **네이티브 기능이 꼭 필요한지** 먼저 판정한다.
2. 꼭 필요하면 **Developer Program + TestFlight**로 옮긴다. 90일 안에 새 빌드만 올리면 되고 Tailscale은 앱의 원격 API 접속용으로 유지한다.
3. 꼭 필요하지 않으면 **Tailscale HTTPS 뒤 PWA**를 별도 클라이언트로 만든다. 이것만이 미등록 무료 상태에서도 7일 서명 갱신을 완전히 없앤다.
4. App Store 심사가 가능한 완성 앱이면 **Unlisted App**으로 전환해 업데이트도 iOS 기본 경로에 맡긴다.
