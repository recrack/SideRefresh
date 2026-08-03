# iOS 무료 Personal Team 원격 설치·갱신 딥 리서치

조사일: 2026-07-24
대상 조건: 본인 iPhone 한 대, Apple Developer Program 미가입(Personal Team), 탈옥·TrollStore·취약점·공유/탈취 인증서 제외, Tailscale은 iPhone에서 계속 사용, 네이티브 iOS 바이너리의 원격 설치/7일 갱신.

## 결론

이전의 “방법이 없다”는 결론은 너무 넓었다. **iPhone과 Mac이 같은 물리 Wi‑Fi일 필요는 없게 만드는, 정상 API만 쓰는 실험적 후보가 하나 확인됐다.** macOS에서 CoreDevice의 Bonjour 발견과 실제 CoreDevice 트래픽을 분리해, 발견은 Mac의 로컬 인터페이스에서 만족시키고 실제 트래픽은 Tailscale로 iPhone에 전달하는 **CoreDevice/Tailnet bridge**다. 독립 재현자는 무료 Personal Team과 `xcrun devicectl`로 다른 Wi‑Fi에 있는 iPhone에 앱 설치를 확인했다. [재현 보고·설계·설치 로그](https://dev.to/kvnpt/how-to-remotely-iterate-deploy-your-sideloaded-ios-apps-over-tailnet-jak)

그러나 이것은 Apple이 지원하는 원격 배포 기능이 아니라 최근의 독립 재현이다. 또 **iPhone이 어떤 Wi‑Fi SSID에도 연결되지 않은 순수 셀룰러 상태**에서는 해당 보고의 CoreDevice listener가 열리지 않아 동작하지 않았다. 따라서 아래 두 요구는 구분해야 한다.

| 요구 | 조사 결론 |
| --- | --- |
| Mac과 iPhone이 서로 다른 Wi‑Fi/서로 다른 장소 | **조건부 가능 후보 존재**: CoreDevice/Tailnet bridge. Tailscale이 실제 전송을 담당한다. |
| iPhone이 Wi‑Fi 연결 자체 없이 셀룰러만 사용 | **검증된 비탈옥·무료 방법을 찾지 못함**. CoreDevice bridge도 제외된다. |

## 1순위 후보 — CoreDevice/Tailnet bridge

### 무엇을 해결하는가

iOS 17+ 개발 기기 서비스는 Bonjour의 `_remotepairing._tcp` 발견 후 CoreDevice/RemoteXPC 연결을 연다. 기본적으로 이 발견은 로컬 링크에 묶여 있어 Tailscale의 L3 경로만으로는 Mac의 `devicectl`이 iPhone을 설치 가능한 기기로 보지 못한다. 재현 사례는 다음 두 역할을 분리했다.

```text
Mac의 로컬 Wi‑Fi 인터페이스(en0)
  ├─ dns-sd proxy advertisement: iPhone이 로컬에 있는 것처럼 Bonjour 등록
  └─ TCP/UDP relay ─────────────────── Tailscale ─────────────────── iPhone
                                                          CoreDevice 개발 서비스
```

`dns-sd -P`는 다른 장비의 서비스를 위한 proxy advertisement를 만들며, 로컬 네트워크 밖 서비스에도 쓸 수 있다고 macOS 자체 매뉴얼이 명시한다. 실제 앱 설치는 Apple의 CoreDevice CLI인 `xcrun devicectl device install app`이 수행한다. 이 환경에서도 `devicectl`은 기기 식별자와 `.app` 번들을 인자로 받는 표준 도구다.

검증 근거와 한계는 다음과 같다.

- 독립 재현 보고는 iOS 26 기기, Personal Team, Tailscale, 서로 다른 SSID에서 `devicectl` 설치 로그(`Acquired tunnel connection to device`, `App installed`)를 제시한다. [보고의 환경·검증 로그](https://dev.to/kvnpt/how-to-remotely-iterate-deploy-your-sideloaded-ios-apps-over-tailnet-jak#the-setup)
- 같은 보고는 Mac에서 Bonjour proxy registration과 TCP/UDP byte relay를 사용한다. TLS/CoreDevice 인증을 중간에서 해독하거나 Apple 바이너리를 변경하지 않는다. [구조와 스크립트](https://dev.to/kvnpt/how-to-remotely-iterate-deploy-your-sideloaded-ios-apps-over-tailnet-jak#the-actual-working-architecture)
- `devicectl` 경로는 Apple의 개발 기기 설치 경로이므로, Personal Team의 7일 프로파일로 빌드한 본인 앱을 주기적으로 새 빌드로 교체하는 목적에 맞는다. Apple은 Personal Team 프로파일이 7일 후 만료되고 재빌드·재설치가 필요하다고 명시한다. [Apple 멤버십 비교](https://developer.apple.com/support/compare-memberships/)
- 이 방식은 **배포 인증서나 설치 권한을 새로 만들지 않는다**. Mac의 Xcode가 정상적으로 새 Personal Team 빌드를 만들고, 기존 개발기기 설치 경로를 Tailscale로 운반할 뿐이다.

### 재현 전제조건

1. iOS 17 이상 iPhone, 최신 Xcode와 `xcrun devicectl`가 있는 상시 켜진 Mac, 그리고 둘의 Tailscale 연결.
2. 최초에는 USB 신뢰/페어링과 실제 Bonjour TXT 정보 캡처가 필요하다. 기기 재부팅 후 개인화된 Developer Disk Image 재단계가 USB를 다시 요구할 수 있다는 것이 재현자의 관찰이다. [초기 USB·재부팅 한계](https://dev.to/kvnpt/how-to-remotely-iterate-deploy-your-sideloaded-ios-apps-over-tailnet-jak#known-fragilities)
3. iPhone은 Mac과 **같은 Wi‑Fi일 필요가 없지만**, 인터넷이 없어도 되는 임의의 Wi‑Fi SSID에는 연결돼 있어야 한다. Tailscale이 실전송을 담당하므로 그 Wi‑Fi는 Mac을 볼 필요도 없다. 다만 Wi‑Fi off/미연결에서는 CoreDevice 포트가 거부됐다는 재현 결과가 있다. [순수 셀룰러 불가 관찰](https://dev.to/kvnpt/how-to-remotely-iterate-deploy-your-sideloaded-ios-apps-over-tailnet-jak#known-fragilities)
4. Mac의 로컬 discovery 인터페이스와 DHCP 변경, iPhone의 Bonjour TXT rotation, 동적 trusted-tunnel 포트 범위는 유지보수 대상이다. 따라서 첫 목적은 7일 자동화가 아니라 **원격 `devicectl` 1회 설치 PoC**로 잡는 것이 타당하다.

### 자동 갱신 가능 범위

PoC가 통과하면 Mac에서 `xcodebuild`/프로젝트 빌드 → `devicectl` 설치를 만료 전(예: 6일째) 실행하도록 LaunchAgent나 CI를 구성할 수 있다. 이는 새 IPA를 Safari로 내려받아 설치하는 것이 아니라 Mac이 CoreDevice 개발 설치를 수행하는 구조다. iOS의 백그라운드 앱 스케줄링에 의존하지 않는다.

다만 iPhone 재부팅, Wi‑Fi 미연결, Mac LAN IP 변경, Apple의 CoreDevice 변경에는 실패할 수 있다. **“자동 갱신 보장”이 아니라, 매주 물리적으로 같은 Wi‑Fi/USB를 요구하던 작업을 원격 Mac 작업으로 옮기는 실험적 자동화**다.

## 기존 도구와 왜 다른가

### AltStore Classic / AltServer / AltServer-Linux

AltStore 공식 README는 AltServer가 서명 후 iTunes Wi‑Fi sync로 다시 설치하며, 백그라운드 refresh는 AltServer와 같은 Wi‑Fi일 때 수행한다고 명시한다. [AltStore README](https://github.com/altstoreio/AltStore)

소스도 `NetServiceBrowser`로 Bonjour 서비스를 찾고, 찾은 서비스에 `NWConnection(to: .service(...))`로 연결한다. 즉 Tailscale/MagicDNS 주소를 직접 지정해 원격 AltServer로 연결하는 기능이 없다. [Bonjour 탐색](https://github.com/altstoreio/AltStore/blob/56854e66fef2eac32dad88dcbad1dc131d430e60/AltStore/Server/ServerManager.swift#L32-L54) · [서비스 연결](https://github.com/altstoreio/AltStore/blob/56854e66fef2eac32dad88dcbad1dc131d430e60/AltStore/Server/ServerManager.swift#L112-L118)

따라서 AltServer-Linux/`netmuxd`로 Mac을 Linux·Raspberry Pi로 바꾸어도 **같은 링크의 iTunes Wi‑Fi sync**라는 제약은 그대로다. 이것은 CoreDevice bridge의 대체가 아니다.

### SideStore와 AltStore Classic 2.3의 on-device route

SideStore는 Mac을 없애기 위해 pairing file과 LocalDevVPN의 loopback 경로를 사용한다. 공식 소스는 LocalDevVPN이 만든 터널과 iOS sandbox 안에서 `usbmuxd`를 흉내 내는 minimuxer가 핵심이라고 설명한다. [SideStore README](https://github.com/SideStore/SideStore)

현 소스는 앱 설치/refresh 전에 loopback VPN이 필요하다고 주석으로 명시하고, 연결 오류도 Wi‑Fi 또는 유선 네트워크 연결과 LocalDevVPN을 요구한다. [refresh 경로 주석](https://github.com/SideStore/SideStore/blob/main/AltStore/My%20Apps/MyAppsViewController.swift#L1163-L1174) · [연결 오류 구현](https://github.com/SideStore/SideStore/blob/main/SideStore/MinimuxerWrapper.swift#L243-L247)

AltStore Classic 2.3 beta의 on-device 구현도 pairing file + minimuxer + local VPN을 요구하며 오류 문구가 Wi‑Fi와 local VPN 연결을 명시한다. [beta source](https://github.com/altstoreio/AltStore/tree/classic_v2.3b1)

결정적으로 iOS는 활성 VPN을 하나만 허용한다. Tailscale도 iOS/Android에서는 다른 VPN과 동시 활성화할 수 없다고 문서화한다. 따라서 Tailscale을 계속 켜는 조건에서는 SideStore/이 AltStore on-device route는 맞지 않는다. [Tailscale 공식 FAQ](https://tailscale.com/docs/reference/faq/other-vpns)

### Feather / KSign / MapleSign의 `itms-services` server route

이 계열은 서명한 IPA를 iPhone 안의 HTTPS loopback server에서 제공하고 `itms-services://`를 호출하는 다른 컨셉이다. Feather 소스는 server route의 동작을 공개한다. [Feather HOW_IT_WORKS](https://github.com/khcrysalis/Feather/blob/main/HOW_IT_WORKS.md)

그러나 **무료 Personal Team의 정식 원격 배포 해법으로 판정할 수 없다.** Apple의 OTA/manifest 문서는 이 경로에 in-house provisioning profile을 요구한다. MDM `InstallApplication`의 manifest 예도 enterprise app이다. [Apple OTA in-house 요건](https://support.apple.com/guide/deployment/distribute-proprietary-in-house-apps-depce7cefc4d/web) · [Apple Install Application](https://developer.apple.com/documentation/devicemanagement/install-application-command)

또한 MapleSign 스스로 Apple Developer Program 인증서를 전제로 하며, 무료 Personal Team을 production sideloading 용도로 보지 않는다고 명시한다. [MapleSign 요구사항](https://maplesign.net/)

즉 loopback HTTPS는 **전송**을 해결할 수 있지만, 무료 Personal Team 개발 프로파일을 Apple이 문서화한 OTA 배포 자격으로 바꾸지는 않는다. 이 경로를 Personal Team의 안정적·정상적 자동 갱신 방법으로 추천할 근거는 찾지 못했다.

## 검토했지만 조건을 충족하지 않는 대안

| 대안 | 판정 | 이유 |
| --- | --- | --- |
| self-hosted NanoMDM/MicroMDM + APNs + `ManifestURL` | 불가 | MDM은 명령·관리 채널일 뿐 서명 자격을 승격하지 않는다. Apple manifest install 예와 OTA 문서가 enterprise/in-house provisioning을 전제한다. NanoMDM도 APNs push certificate를 필요로 한다. [NanoMDM 운영 문서](https://github.com/micromdm/nanomdm/blob/main/docs/operations-guide.md) |
| `itms-services` + 무료 개발 IPA | 정식/검증 불가 | Apple의 지원 문서는 wireless manifest install을 in-house 프로파일로 한정한다. 무료 Personal Team은 on-device testing용이며 7일 재프로비저닝이 요구된다. [Apple Personal Team 제한](https://developer.apple.com/support/compare-memberships/) |
| USB-over-IP / `usbfluxd` + Tailscale | 정확한 조건에는 불가 | `usbfluxd`는 원격에 **물리 USB로 연결된** iPhone을 로컬처럼 보이게 할 수 있다. iPhone을 원격 gateway에 계속 꽂아 둘 수 있다면 보조책이지만 “USB 연결 없음”을 만족하지 않는다. [usbfluxd 개요](https://github.com/corellium/usbfluxd) · [usbmuxd가 USB multiplexer임](https://github.com/libimobiledevice/usbmuxd) |
| `usbmuxd2`로 Wi‑Fi/Tailscale 직접 설치 | 불가 | Wi‑Fi device의 legacy connection proxying이 아직 구현되지 않았다고 소스가 명시한다. [미구현 코드](https://github.com/tihmstar/usbmuxd2/blob/744c46fc7faf61ed87b38bc97b1ac793d50e163d/usbmuxd2/Devices/WIFIDevice.cpp#L88-L110) |
| LiveContainer | 부분적 우회일 뿐 | 앱을 host app 안에서 실행해 업데이트할 수 있어도 host app 자신은 Personal Team 7일 서명·재설치 문제를 계속 가진다. “네이티브 앱 자체의 원격 설치/renewal”을 해결하지 않는다. |
| PWA/WebClip | 조건은 충족하지만 다른 제품 | 설치 서명과 7일 만료를 없애지만 네이티브 IPA를 설치·업데이트하는 방식이 아니다. Flutter/Expo/Swift/Kotlin 네이티브 바이너리 요구를 충족하지 않는다. |
| TestFlight/Ad Hoc/Enterprise/대체 마켓 | 기술적으로 가능하지만 조건 밖 | Developer Program 가입·배포 자격 또는 지역/entitlement가 필요하다. |

## 최종 판정

1. **서로 다른 Wi‑Fi여도 된다**가 핵심이면: CoreDevice/Tailnet bridge를 우선 PoC한다. 현재 조사에서 조건에 가장 가깝고, Tailscale을 유지하며 무료 Personal Team의 재설치를 원격화하는 유일한 검증 후보다.
2. **Wi‑Fi를 완전히 꺼도 셀룰러만으로 자동 갱신돼야 한다**면: 탈옥/취약점/유료 배포 자격을 제외한 검증된 방법은 이번 딥 리서치에서 찾지 못했다. 이 결론은 AltStore/SideStore/Feather 계열 소스, Apple MDM/OTA 문서, usbmuxd relay 경로까지 대조한 결과다.
3. CoreDevice bridge가 성공해도 Apple 지원 기능은 아니므로, 우선 본인 기기에서 1회 원격 설치를 검증한 뒤에만 6일 주기 자동 빌드·설치를 붙여야 한다.
