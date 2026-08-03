# 물리 Wi‑Fi 밖에서 무료 iOS 개인 서명을 갱신할 수 있는가

조사일: 2026-07-24
범위: **Apple Developer Program 미등록(Personal Team)**, 본인 iPhone 한 대, 앱의 7일 서명을 갱신해야 함, iPhone에서 **Tailscale을 계속 활성화**하고 집 밖/셀룰러에서도 갱신하고 싶은 경우. Apple·AltStore·SideStore·Tailscale·Feather의 공식 문서와 공개 소스를 우선 확인했다. 인증서 공유, 폐기 인증서, 탈옥/취약점 경로는 다루지 않는다.

## 결론

**이 조건을 모두 충족하는 지원되는 무료 경로는 없다.**

`Personal Team + Tailscale 상시 + 집 밖/셀룰러 + 자동 갱신` 조합에서, 현재 확인 가능한 안전한 오픈소스 도구는 없다. 무료 Personal Team의 기기 설치 프로비저닝 프로파일은 7일 만료이며, 그 사실을 AltStore나 SideStore가 없애지는 않는다. [Apple: Personal Team 제한](https://developer.apple.com/help/account/basics/about-your-developer-account)

핵심은 **Apple 계정 인증**과 **재설치 전송**을 분리해서 보는 것이다.

1. 서명 도구가 Apple 서버에 로그인해 프로파일을 만드는 통신은 인터넷 연결로 가능하다.
2. 그러나 재서명한 앱·프로파일을 iPhone에 설치하려면, AltStore Classic은 Mac의 Apple/iTunes Wi‑Fi 동기화 경로 또는 USB를 요구한다. Tailscale은 이 기기 전송 경로를 제공하지 않는다.
3. SideStore 계열은 Mac 전송 대신 iPhone 내부의 loopback VPN을 쓴다. iOS는 Tailscale과 이 VPN을 동시에 활성화할 수 없다.

따라서 **Tailscale을 항상 켠 채로 외부 셀룰러에서 자동 갱신**은 하지 못한다. 현 구성에서 Wi‑Fi를 쓰지 않는 검증된 비유료 방법은 **Mac에 USB로 연결해 수동 갱신/재설치**뿐이다.

## 확인한 경로

| 경로 | 집 밖/셀룰러에서 가능? | Tailscale 상시와 양립? | 자동 갱신? | 판단 |
| --- | --- | --- | --- | --- |
| Xcode / Finder의 기기 동기화 | **USB면 가능** | 가능 | 아니오 | Wi‑Fi를 쓰지 않는 공식 경로지만 매번 연결·실행해야 한다. |
| AltStore Classic | 아니오 | Tailscale 자체와 충돌은 없음 | 같은 로컬 Wi‑Fi일 때만 *시도* | 현 조건의 원격 갱신 답이 아니다. |
| SideStore | 문서상 Wi‑Fi + LocalDevVPN 필요 | **아니오** | 조건이 맞을 때 *시도* | iOS 단일 VPN 제약으로 제외. |
| Feather | 설치 보조 도구일 뿐 | pairing 방식은 아니오 | Personal Team 자동 갱신 기능 확인 불가 | 현재 문제의 해결책이 아니다. |
| AltStore를 Tailscale용으로 포크 | 이론상 일부 통신만 가능 | 가능할 수 있음 | 보장 불가 | 발견(Bonjour)뿐 아니라 Mac↔iPhone 설치 전송도 새로 구현해야 한다. 개인용으로 권하지 않는다. |

### 1. Xcode / Apple Wi‑Fi 동기화

Apple의 Wi‑Fi 동기화 문서는 iPhone과 Mac이 **같은 Wi‑Fi**에 있어야 기기가 다시 나타난다고 명시한다. 초기 USB 연결 후 설정하는 기능이며, 이 조건 밖에서 문서화된 대체 경로는 USB다. [Apple: Wi‑Fi 동기화](https://support.apple.com/guide/mac-help/wi-fi-syncing-mchlada1d602/mac) Xcode의 무선 기기 페어링도 같은 네트워크에서 기기를 발견해야 하며, 이후 Wi‑Fi를 통해 실행한다고 설명한다. [Apple: Device Hub 페어링](https://developer.apple.com/documentation/xcode/pairing-your-devices-with-your-mac)

즉 **USB는 Wi‑Fi 없이 가능한 공식 대안**이지만, iPhone이 Mac에 물리적으로 연결되어 있어야 하므로 원격·자동 갱신은 아니다.

### 2. AltStore Classic: Tailscale/MagicDNS가 대체하지 못하는 이유

AltStore의 공식 FAQ는 AltStore가 AltServer와 **같은 Wi‑Fi**이거나 USB로 연결되어 있어야 sideload·refresh를 수행한다고 명시한다. 자동 갱신도 일주일 동안 시도할 뿐이다. [AltStore: AltServer](https://faq.altstore.io/altstore-classic/altserver) 문제 해결 문서도 AltServer 탐색 실패 시 동일 Wi‑Fi 또는 USB, 그리고 Wi‑Fi sync 활성화를 요구한다. [AltStore: troubleshooting](https://faq.altstore.io/altstore-classic/troubleshooting-guide)

공개 소스도 이 제한과 일치한다.

- README는 재서명한 앱을 AltServer로 보내고, AltServer가 **iTunes Wi‑Fi sync**로 기기에 설치한다고 설명한다. 백그라운드 갱신도 "same WiFi"일 때만 표방한다. [AltStore README](https://github.com/altstoreio/AltStore#readme)
- iOS 앱은 `NetServiceBrowser`로 `_altserver._tcp` Bonjour 서비스를 찾고, 찾은 서비스에 `NWConnection(to: .service(...))`로 접속한다. 사용자가 MagicDNS 호스트명/IP를 입력하는 설정은 이 코드에 없다. [ServerManager.swift](https://github.com/altstoreio/AltStore/blob/develop/AltStore/Server/ServerManager.swift)
- 더 근본적으로 Mac의 요청 처리기는 앱 설치 전 해당 UDID가 `availableDevices`에 있어야 하며, 없으면 `deviceNotFound`로 실패한다. 다시 말해 iPhone→AltServer 발견만 Tailscale 호스트명으로 바꿔도, Mac이 Apple의 기기 동기화 경로에서 iPhone을 볼 수 있어야 한다. [AltServer RequestHandler.swift](https://github.com/altstoreio/AltStore/blob/develop/AltServer/Connections/RequestHandler.swift)

Tailscale의 MagicDNS는 tailnet 기기에 안정적인 DNS 이름을 부여하는 기능이다. [Tailscale: MagicDNS](https://tailscale.com/docs/features/magicdns) 반면 AltStore의 현재 코드는 그 이름을 입력·해석하는 경로가 아니라 Bonjour 서비스 탐색 경로만 사용한다. 따라서 **stock AltStore에서 MagicDNS를 켠다고 AltServer가 발견되지는 않는다**. 이는 두 공식 소스를 결합한 구현상 판단이다.

따라서 "AltServer의 Tailscale IP나 `*.ts.net` 이름을 입력하게 포크"하는 것은 **발견 단계 일부**만 바꾼다. Mac↔iPhone의 Apple 기기 가시성·설치 전송을 계속 해결해야 하므로, 작은 설정 변경이나 신뢰할 만한 개인 자동화가 아니다.

**원격 USB도 답이 아니다.** Tailscale은 기기 사이 IP 연결을 제공하며 대상 기기에서 별도 서비스를 실행해야 한다고 설명할 뿐, 물리 USB를 전달하는 기능은 제공하지 않는다. [Tailscale: 기기 연결](https://tailscale.com/docs/how-to/connect-to-devices) 일반 USB-over-IP 제품을 끼우는 방식은 Apple이 문서화한 Finder/Xcode 페어링 경로가 아니므로, 무료 개인 서명의 안정적인 원격 갱신 해법으로 권하지 않는다.

### 3. SideStore: 원격 Mac은 없지만 Tailscale과 충돌

SideStore는 특별한 VPN으로 iOS 내부 loopback 설치 경로를 만들고, Personal Team 앱의 7일 주기를 갱신하는 구조다. [SideStore README](https://github.com/SideStore/SideStore#readme) 공식 요구 사항은 설치·갱신에 **Wi‑Fi와 LocalDevVPN**을 모두 요구하며, 오류 문서도 둘 중 하나가 없으면 갱신할 수 없다고 한다. [SideStore prerequisites](https://docs.sidestore.io/docs/installation/prerequisites) · [SideStore error 1414](https://docs.sidestore.io/docs/troubleshooting/error-codes)

Tailscale은 iOS에서 동시에 다른 VPN과 활성화될 수 없다. Tailscale의 공식 FAQ는 iOS/Android가 한 번에 하나의 VPN만 허용한다고 명시한다. [Tailscale: 다른 VPN과 함께 사용](https://tailscale.com/docs/reference/faq/other-vpns) LocalDevVPN, StosVPN, WireGuard 대안도 모두 이 단일 VPN 자리를 사용하므로 해결책이 아니다.

즉 SideStore는 "Mac이 없어도 되는" 선택지이지만, **Tailscale을 계속 켜야 한다**는 이 경우에는 맞지 않는다. 셀룰러만으로 갱신할 수 있다는 공식 지원 경로도 확인하지 못했다.

### 4. Feather: 갱신 자동화 도구가 아니다

Feather는 GPL-3.0 공개 소스의 온디바이스 서명/설치 관리 도구다. 다만 프로젝트가 설명하는 시작점은 유효한 `.p12` + `.mobileprovision` 쌍으로 IPA를 서명하는 것이다. [Feather README](https://github.com/claration/Feather#readme) 이 쌍 자체가 Personal Team에서 7일 만료되는 프로파일을 자동으로 새로 발급해 주지는 않는다.

프로젝트의 pairing 설치 방식도 pairing 파일과 LocalDevVPN을 요구하며, 현재 구조상 컴퓨터 초기 설정이 필요하다고 명시한다. [Feather HOW_IT_WORKS](https://github.com/claration/Feather/blob/main/HOW_IT_WORKS.md) 따라서 이 방식도 Tailscale과 동시에 쓸 수 없다. 서버 설치 방식은 이미 서명된 IPA를 설치하는 보조 방식일 뿐, Personal Team의 프로파일 만료를 자동 해결하는 원격 서명 서비스가 아니다.

인증서 개인키(`.p12`)와 프로비저닝 파일을 휴대폰·외부 서버에 보관하는 구조는 키 관리 부담도 늘린다. 이 목적만을 위해 Feather로 전환할 근거는 없다.

## 자동 갱신이라는 표현의 한계

AltStore와 SideStore가 말하는 백그라운드 갱신은 iOS가 실행 시간을 줄 때 수행하는 **best effort**다. Apple은 background task를 요청해도 시스템이 실행할 최적 시점을 정하며, background refresh에는 제한된 실행 시간을 준다고 설명한다. [Apple: Background 전략](https://developer.apple.com/documentation/backgroundtasks/choosing-background-strategies-for-your-app) 그래서 같은 Wi‑Fi/VPN 조건을 맞춰도 "반드시 만료 전에 100% 갱신"을 보장할 수는 없다.

## 최종 권고

현재 조건에서는 **AltStore를 Tailscale 원격 갱신용으로 포크하거나, 불명확한 인증서/서명 서비스를 찾는 데 시간을 쓰지 않는 것**이 맞다.

- 무료·Tailscale 상시를 유지한다면: AltStore를 쓰되, Mac과 같은 로컬 Wi‑Fi에 돌아왔을 때 자동 갱신을 기대하고, 놓쳤다면 USB로 수동 갱신한다.
- "Wi‑Fi 없이도"만 절대 조건이면: USB 수동 갱신만이 검증된 무료 경로다.
- "집 밖·셀룰러에서도 자동으로, 신뢰성 있게"가 절대 조건이면: Personal Team의 범위를 벗어난다. Developer Program 가입 후 TestFlight 같은 Apple 배포 경로로 바꾸는 것이 지원되는 해결책이다. [Apple: 멤버십 비교](https://developer.apple.com/support/compare-memberships/) · [Apple: TestFlight](https://developer.apple.com/testflight/)
