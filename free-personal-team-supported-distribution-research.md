# 무료 Personal Team에서 지원되는 원격 배포 채널 검증

조사일: 2026-07-24
범위: **Apple 1차 문서만** 사용했다. 조건은 `유료 Apple Developer Program 미가입`, `Personal Team`, `자기 iPhone 1대`, `네이티브 iOS 앱`, `셀룰러를 통한 원격 설치·갱신`, `제품을 App Store 배포 모델로 바꾸지 않음`이다.

## 결론

이 조건을 동시에 충족하는 **Apple 지원 배포 채널은 없다.** 무료 계정의 Personal Team은 Xcode로 개인 기기에 개발·테스트 설치만 할 수 있으며, 설치용 provisioning profile은 발급 후 7일에 만료되고 앱을 다시 빌드·재설치해야 한다. 무료 계정에는 App Store Connect와 TestFlight 권한도 없다. [Apple: Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account)

따라서 MDM/APNs, `itms-services` OTA manifest, 웹 서버는 “앱을 원격으로 운반하거나 설치 명령을 보내는 수단”일 수는 있어도, **Personal Team 개발용 IPA를 Apple이 배포용 앱으로 받아들이게 만드는 우회책은 아니다.**

## 채널별 판정

| 채널 | 셀룰러 원격 설치/업데이트 능력 | 무료 Personal Team에서 가능한가 | 판정 |
| --- | --- | --- | --- |
| Xcode Personal Team | 개인 기기 개발·테스트 설치만. 원격 전송 자체는 이 티켓 범위 밖 | 가능하지만 profile이 7일 후 만료 | 기존 후보. 배포 채널은 아님 |
| App Store / 비공개·Unlisted·Custom App | 인터넷 설치·자동 업데이트 가능 | 불가. App Store Connect는 Program membership 리소스 | 제외 |
| TestFlight | 인터넷 설치 가능, beta 용도 | 불가. App Store Connect/TestFlight가 필요 | 제외 |
| Ad Hoc + OTA | 등록 기기 대상으로 원격 OTA가 가능한 **유료 Program** 경로 | 불가. distribution certificate와 Ad Hoc profile 필요 | 제외 |
| MDM + APNs | App Store 앱 또는 enterprise manifest 앱을 원격 설치·업데이트 | 불가. MDM이 Personal Team development IPA의 서명 권한을 승격하지 않음 | 제외 |
| Enterprise + `itms-services` manifest | 조직의 사내 앱을 HTTPS로 원격 설치 가능 | 불가. 별도 Enterprise Program, 조직·직원 요건 | 제외 |
| EU Web Distribution / 대체 마켓 | EU에서 웹으로 직접 설치 가능 | 불가. 유료 Program·조직·2년·실적·공증 요건 | 제외 |

### 1) Personal Team의 경계

Apple은 프로그램 멤버십과 연결되지 않은 계정을 Xcode에서 Personal Team으로 표시한다고 명시한다. 이때 설치 가능한 프로파일은 7일 만료이며, 만료 후 앱을 다시 빌드하고 기기에 재설치해야 한다. 표에서도 무료 등록 계정에는 `Certificates, Identifiers & Profiles`, `App Store Connect`, `TestFlight`가 제공되지 않는다고 명시한다. [Apple: Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account)

### 2) App Store·TestFlight·Custom/Unlisted는 “무료 계정” 경로가 아니다

Apple은 App Store Connect를 **Apple Developer Program membership**과 연결된 Account Holder가 사용하는 서비스라고 설명한다. TestFlight 역시 App Store Connect에 beta build를 올리는 흐름이다. 즉 원격 설치 자체는 가능해도 Personal Team의 7일 개발 프로파일 문제를 해결하는 무료 경로가 아니다. [Apple: App Store Connect workflow](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-workflow) · [Apple: Programs overview](https://developer.apple.com/help/account/membership/programs-overview) · [Apple: TestFlight](https://developer.apple.com/testflight/)

참고로 교육기관·비영리·정부기관은 심사를 거쳐 Program 회비 면제를 요청할 수 있다. 이는 **무료 Personal Team의 기능**이 아니라, 자격 있는 조직이 받는 **Apple Developer Program membership**이므로 이 사용자의 현재 조건과는 다르다. [Apple: Program fee waivers](https://developer.apple.com/help/account/membership/fee-waivers/)

### 3) Ad Hoc과 OTA manifest

Ad Hoc은 App ID, distribution certificate, 등록 기기를 포함한 provisioning profile로 만드는 배포 방식이다. Apple은 이 프로파일을 만드는 역할을 Program의 Account Holder/Admin으로 제한한다. Apple의 Xcode 문서도 등록 기기 배포를 Ad Hoc 또는 development profile로 구분하고, TestFlight는 **Apple Developer Program members**가 쓰는 대안이라고 명시한다. [Apple: Create an ad hoc provisioning profile](https://developer.apple.com/help/account/provisioning-profiles/create-an-ad-hoc-provisioning-profile) · [Apple: Distribute to registered devices](https://help.apple.com/xcode/mac/current/en.lproj/dev7ccaf4d3c.html)

그러므로 HTTPS의 `itms-services://?action=download-manifest...` 링크를 직접 호스팅하더라도, 무료 Personal Team development profile을 Ad Hoc distribution profile로 바꾸지 못한다. OTA는 서명·권한 문제의 대체물이 아니라 그 뒤의 전송 수단이다.

### 4) MDM/APNs는 해법이 아닌 이유

Apple MDM의 `InstallApplication`은 `iTunesStoreID`, `Identifier`, `ManifestURL` 중 하나만 받는다. Apple이 제공하는 `ManifestURL` 예시는 **enterprise app** 설치이며, 공식 관리 앱 문서는 iOS의 manifest 원본을 “enterprise app”으로 정의한다. 즉 MDM 서버를 오픈소스로 직접 운영해도, 서버가 허용된 앱 서명 유형을 확장할 수는 없다. [Apple: Install Application command](https://developer.apple.com/documentation/devicemanagement/install-application-command) · [Apple: Installing, managing, updating, and removing apps](https://developer.apple.com/documentation/devicemanagement/installing-managing-updating-and-removing-apps)

MDM이 App Store/enterprise 앱을 원격 업데이트할 수 있다는 사실은 맞다. Apple도 설치 명령으로 설치된 앱은 MDM이 Store 또는 manifest의 새 버전을 확인해 업데이트 명령을 보낸다고 설명한다. 그러나 이는 App Store 앱 또는 enterprise 앱에 대한 기능이지, 무료 개발 서명의 7일 제한을 연장하는 기능이 아니다. [Apple: Distribute managed apps](https://support.apple.com/guide/deployment/distribute-managed-apps-dep575bfed86/1/web/1.0)

### 5) Enterprise·자체 웹 OTA는 개인 1명용이 아니다

Apple은 웹/MDM 기반 무선 설치를 Apple Developer **Enterprise** Program의 proprietary in-house app 배포로 문서화한다. `.ipa`, XML manifest, HTTPS, in-house provisioning profile, 신뢰된 certificate가 필요하다. [Apple: Distribute proprietary in-house apps](https://support.apple.com/en-ie/guide/deployment/depce7cefc4d/web)

Enterprise Program은 직원 100명 이상인 법인, 내부 직원 전용 배포 체계, Apple의 검증을 요구하며 연 299 USD이다. 따라서 1인 개인 앱에 쓸 수 없고 “유료 등록 없이” 조건에도 맞지 않는다. [Apple: Apple Developer Enterprise Program](https://developer.apple.com/programs/enterprise/)

### 6) EU 대체 배포도 예외가 아니다

EU Web Distribution은 웹 설치를 지원하지만, EU 소재 법인/해당 법인, **Apple Developer Program 2년 연속 가입**, 전년도 EU 연간 첫 설치 100만 이상인 앱, Apple 공증, App Store Connect를 요구한다. iOS 17.5+ EU 사용자만 대상이다. 개인 무료 Personal Team의 자기 기기 1대에는 적용될 수 없다. [Apple: Getting started with Web Distribution in the EU](https://developer.apple.com/support/web-distribution-eu/) · [Apple: Configuring apps for web distribution](https://developer.apple.com/documentation/appstoreconnectapi/configuring-apps-for-web-distribution)

## 이 조사로 확정되는 설계 경계

1. **MDM·APNs·OTA manifest를 추가해도** 무료 Personal Team 앱을 순수 셀룰러에서 Apple 지원 방식으로 자동 연장·배포할 수는 없다.
2. 무료 조건을 유지하면 남는 것은 개발 설치를 만료 전 재빌드·재설치하는 자동화이며, 그때 Tailscale은 **전송/개발 연결 경로** 후보일 뿐 Apple의 별도 배포 권한을 생성하지 않는다.
3. Apple 지원 “원격·셀룰러·장기 자동 업데이트”가 필요하다면 최소한 Program membership(Ad Hoc/TestFlight/App Store) 또는 자격 있는 조직의 Enterprise/MDM 모델 중 하나로 조건을 바꿔야 한다. 이 사용자의 요구에서는 이 티켓의 답이 아니다.
