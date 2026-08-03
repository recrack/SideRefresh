# SideRefresh: Tailscale 외 iPhone 갱신 연결 대안 조사

- 조사일: 2026-07-26
- 범위: 무료 Personal Team으로 Mac에서 `xcodebuild`로 다시 빌드·서명하고
  `devicectl`로 **같은 iPhone에 재설치**하는 SideRefresh 흐름의 연결 대안
- 출처 정책: Apple 공식 문서, 각 제품의 공식 문서, 또는 해당 제품의 공식 오픈소스
  저장소만 인용

## 결론

**가장 신뢰할 수 있는 순서는 USB → Xcode가 이미 페어링한 같은 LAN 연결 → Xcode의
직접 IP 연결이다.** Apple은 iPhone을 케이블로 연결해 신뢰하고 네트워크 페어링하는
절차, 같은 네트워크의 Bonjour 발견, 그리고 Bonjour가 아닌 IP 주소 직접 연결을
명시적으로 문서화한다. 네트워크 장치 통신에는 TCP 포트 `62078`이 필요하다.
[Apple — Pair a wireless device with Xcode](https://help.apple.com/xcode/mac/current/en.lproj/devbc48d1bad.html)
[Apple — Run an app on a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html)
[Apple — Troubleshoot a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/devac3261a70.html)

WireGuard, ZeroTier, NetBird, site-to-site VPN은 모두 **Mac과 iPhone 사이에 IP
경로를 만들 수 있는 후보**다. 하지만 Apple의 공개 1차 자료는 그러한 오버레이 VPN
위에서 Xcode/CoreDevice 또는 `devicectl` 설치가 지원된다고 보장하지 않는다. 따라서
이는 “Tailscale의 교체품”이 아니라 **페어링을 끝낸 뒤 IP 직접 연결을 시험할 수 있는
전송망 후보**다. iPhone이 셀룰러만 쓰는 상태도 같은 이유로 제품 보장 대상이 아니다.

AltStore와 SideStore는 IPA를 서명·설치·갱신하는 별도 사이드로딩 체계다. 원본 Xcode
프로젝트를 빌드하고 `devicectl`로 재설치하는 SideRefresh의 전송 경로를 대체하지
않는다. TestFlight, App Store, MDM은 7일 Personal Team 갱신 문제를 제거할 수 있지만
무료 Personal Team 경로가 아니라 유료/조직 배포 경로다.

## 먼저 고정할 Apple 경계

무료 Apple 계정의 Personal Team은 Xcode에서 개인 기기에 설치·시험할 수 있지만,
프로비저닝 프로파일은 발급 뒤 7일 만료되고 만료 뒤에는 다시 빌드·재설치해야 한다.
이는 어떤 VPN을 쓰더라도 바뀌지 않는 서명·프로비저닝 제약이다.
[Apple — Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account)

Apple이 문서화한 네트워크 개발 기기 흐름은 다음과 같다.

1. 최초에는 iPhone을 Mac에 케이블로 연결하고, iPhone에서 Mac을 신뢰한 뒤 Xcode의
   `Connect via network`로 페어링한다.
2. 같은 네트워크라면 Bonjour로 발견할 수 있다.
3. Bonjour로 발견되지 않아도, Mac과 iPhone이 어떤 네트워크에 연결돼 있고 Mac에서
   iPhone IP에 도달할 수 있으면 Xcode의 `Connect via IP Address`를 사용할 수 있다.
4. 네트워크 기기 통신에는 포트 `62078`이 열려 있어야 한다.

이는 Xcode UI의 공식 절차다. Apple은 공개 문서에서 `devicectl` 명령이 WireGuard,
ZeroTier, NetBird, Headscale 또는 셀룰러망 위에서 같은 동작을 보장한다고 쓰지 않는다.
따라서 SideRefresh의 예약 실행에 새 전송 방식을 넣기 전에는 **해당 Mac, iPhone, iOS,
Xcode 버전 조합에서** 다음을 실측해야 한다.

```text
1. 케이블 신뢰 + Xcode 네트워크 페어링 완료
2. Xcode Devices and Simulators에서 대상이 Connected인지 확인
3. IP 직접 연결 후 Xcode가 동일 UDID를 표시하는지 확인
4. SideRefresh가 사용하는 xcodebuild destination과 devicectl install이 모두 성공하는지 확인
5. iPhone이 잠김·절전·셀룰러 전환 상태여도 다음 예약 시점에 재현되는지 확인
```

이 문서에서 “조건부”는 위 실측 전에는 사용자에게 자동화 성공을 약속하면 안 된다는
뜻이다.

## 방식별 판단

| 방식 | Personal Team의 `xcodebuild` + `devicectl` 재설치와 관계 | 최초 준비와 IP/Bonjour | 셀룰러만인 iPhone | 운영·보안 부담 | 제품 우선순위 |
|---|---|---|---|---|---|
| USB | **실제 대체 경로**. 네트워크가 전혀 필요 없다. | 케이블 연결·기기 신뢰. IP/Bonjour 불필요. | 해당 없음. 물리 연결 중에는 셀룰러/Wi-Fi와 무관. | 가장 낮음. Mac과 케이블이 같은 장소에 있어야 한다. | **P0** |
| 같은 LAN의 Xcode/CoreDevice | **실제 보완 경로**. Apple 문서화됨. | 최초 USB 페어링, 같은 네트워크의 Bonjour. 필요하면 IP 직접 연결. TCP 62078. | 보통 해당 없음. 같은 LAN 조건이 깨진다. | 낮음~중간. AP client isolation/방화벽을 피해야 한다. | **P0** |
| 직접 WireGuard | **조건부 전송망 보완**. IP가 도달해도 Apple이 `devicectl` 호환을 보장하지 않는다. | 최초 USB 페어링 후, 터널 IP로 Xcode IP 연결을 실험. Bonjour에 의존하지 않는다. | 터널이 iOS에서 활성·유지되고 Mac이 IP에 도달할 때만 후보. 공식 보장 없음. | 키 배포, 피어·라우팅·NAT/배터리 관리. | **P2: 범용 직접 IP 실험 뒤에만** |
| Headscale | **직접 대체 아님**. Tailscale 클라이언트의 self-hosted coordination server다. | Headscale 운영 + 각 기기에 Tailscale 클라이언트 등록. 그 뒤에도 Xcode 페어링/IP 검증 필요. | Tailscale 클라이언트의 셀룰러 연결이 살아 있고 Xcode가 IP로 연결되는지를 별도 실측. | 서버, HTTPS, 키·노드·업데이트 책임. | **P3: 별도 UI/브랜드 지원 없음** |
| ZeroTier | **조건부 전송망 보완**. macOS/iOS 클라이언트는 공식 제공. | 양쪽에서 네트워크 가입·승인 후 overlay IP로 Xcode IP 연결 실험. iOS VPN API 제약상 Bonjour 해결책으로 둘 수 없다. | iOS 클라이언트가 연결된 경우의 후보일 뿐, Xcode 설치 보장은 없음. | 네트워크 권한·멤버 관리, 중앙 관리 계정 또는 controller 관리. | **P2: 범용 직접 IP 실험 뒤에만** |
| NetBird | **조건부 전송망 보완**. iOS/macOS client와 self-host가 가능. | 양쪽 peer 등록·정책 설정 후 overlay IP로 Xcode IP 연결 실험. | 릴레이가 되면 지연/대역폭 비용이 생긴다. 셀룰러에서 Xcode 설치는 미보장. | identity provider/ACL/relay 또는 self-host 운영. | **P2: 범용 직접 IP 실험 뒤에만** |
| site-to-site VPN | **조건부 전송망 보완**. 원격 LAN 간 라우팅일 뿐 개발 기기 프로토콜이 아니다. | 최초 USB 페어링. Bonjour가 양 사이트에 자동으로 퍼진다고 가정하지 말고 IP 직접 연결과 62078을 검증. | iPhone이 VPN 쪽 LAN 또는 별도 모바일 VPN에 실제로 도달할 때만 후보. | 라우터 ACL, 라우트 중복, 방화벽, 두 사이트 장애 대응. | **P2: 직접 IP generic 경로 우선** |
| 원격 Mac | **실행 위치를 바꾸는 보완**. 원격 Mac이 빌드·서명·설치하고, 사용자는 그 Mac을 원격 관리한다. | 그 Mac에서 iPhone USB 또는 Apple이 문서화한 LAN/IP 페어링을 완료해야 한다. | iPhone과 원격 Mac의 연결 방식에 따라 다름. 원격 제어 자체가 iPhone 연결을 만들지는 않는다. | 가장 큼: 소스, 개발 인증서 개인키, Apple 계정 접근, 원격 로그인 보안. | **P2: 별도 worker/agent 설계일 때** |
| AltStore | **대체 불가(다른 제품 경로)**. IPA를 개인 개발 인증서로 재서명해 AltServer가 설치한다. | AltServer와 같은 Wi-Fi 또는 USB. Wi-Fi sync/발견이 핵심. | 공식 문서는 같은 Wi-Fi 또는 USB를 요구한다. | Apple ID/AltServer, IPA 배포·갱신 모델을 별도 운영. | **지원하지 않음** |
| SideStore | **대체 불가(다른 제품 경로)**. 기기 안 VPN·pairing file 기반 IPA 갱신이다. | 초기 USB 신뢰, pairing file, LocalDevVPN과 Wi-Fi가 기본 요구사항이다. | 공식 문서가 상충하는 셀룰러 관련 안내를 포함하므로, 신뢰 가능한 셀룰러-only 경로로 보장할 수 없다. | pairing file 만료/교체, VPN·Apple 계정·별도 도구 운영. | **지원하지 않음** |
| TestFlight/App Store | **문제 자체의 유료 대안**. `devicectl` 재설치가 아니라 App Store Connect 배포·설치다. | Apple Developer Program + App Store Connect, 업로드와 배포 절차. | 인터넷만 있으면 설치·업데이트 가능하지만, TestFlight build는 90일 후 만료. | 서명, 업로드, 배포/리뷰 운영. | **P1: 제품 외부의 권장 탈출구** |
| MDM/Enterprise | **개인용 대체 불가**. 조직 관리·배포 경로다. | 조직의 device management, 적격 Enterprise Program 또는 Business/School 배포. | MDM이 관리하는 셀룰러 기기에 배포할 수는 있으나 개인 Personal Team과 별개. | 조직 ID, APNs/MDM, 규정·기기 관리. | **지원하지 않음** |

### 1. USB: 유일한 “순수 무선 없음” 해법

USB는 Wi-Fi, 인터넷, 셀룰러, Bonjour, overlay VPN 모두 없이 Mac과 iPhone을 직접
연결한다. Apple도 iOS 기기의 네트워크 페어링 전에 케이블 연결과 iPhone의 Trust를
요구한다. 따라서 “iPhone이 어떤 무선망에도 연결되지 않아도 재설치”라는 요구에는
USB가 유일하게 Apple 문서 범위 안에 있는 답이다.
[Apple — Pair a wireless device with Xcode](https://help.apple.com/xcode/mac/current/en.lproj/devbc48d1bad.html)

SideRefresh는 USB에서 기기 UDID를 읽고, `xcodebuild` destination과 `devicectl`에 같은
UDID를 넘기는 현재 모델을 유지하는 것이 맞다. 예약 자동화의 한계는 프로토콜이 아니라
**케이블이 연결된 물리적 상태여야 한다**는 점이다.

### 2. 같은 LAN, 그리고 Xcode의 직접 IP

같은 LAN은 Bonjour가 자동 발견을 제공하는 편한 경로다. 그러나 제품 설계에서 Bonjour를
필수로 두면 AP isolation, 회사/공용 Wi-Fi, 다른 서브넷에서 실패한다. Apple은 그런 경우
`Connect via IP Address`를 별도 절차로 제공한다. 따라서 SideRefresh의 보편적인 네트워크
개념은 “Tailscale”이 아니라 **`Xcode에 이미 페어링된 iPhone의 검증된 IP/DNS 경로`**여야
한다.
[Apple — Run an app on a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html)

이 경로가 실패하면 먼저 Mac에서 IP reachability와 TCP 62078을 확인해야 한다. Apple은
이 포트를 네트워크 기기 통신 포트로 지정한다.
[Apple — Troubleshoot a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/devac3261a70.html)

현재 SideRefresh의 “IP/DNS 직접 입력” 화면은 Xcode에서 수동으로 연결할 주소를 보여주는
도움 경로다. 이 연구의 결론은 그 UI에 VPN별 제품 통합을 덧붙이는 것이 아니라, 우선
**Xcode/CoreDevice가 이미 인식한 UDID와 성공 검증을 예약 작업의 전제 조건으로 만드는
것**이다.

### 3. 직접 WireGuard

WireGuard는 iOS와 macOS 앱을 포함하는 공식 프로젝트이며 MIT 라이선스로 제공된다.
[WireGuard 공식 `wireguard-apple` 저장소](https://github.com/WireGuard/wireguard-apple)

그 사실은 양단에 터널 IP를 만들 수 있다는 뜻이지, Apple 개발 기기 서비스가 그 터널을
지원한다는 뜻은 아니다. SideRefresh에서의 안전한 위치는 다음과 같다.

- 최초 pairing은 USB와 Xcode로 한다.
- 사용자가 WireGuard의 iPhone tunnel IP를 입력해 Xcode `Connect via IP Address`를
  성공시킨 뒤에만 SideRefresh가 해당 UDID를 대상으로 시험한다.
- 자동 예약 전에는 실제 `xcodebuild`와 `devicectl` 재설치의 dry run/실행 성공을 별도로
  기록한다.
- 실패 시 USB 또는 같은 LAN을 안내하며, VPN을 자동으로 재설정하거나 키를 생성·보관하지
  않는다.

이 방식은 iPhone이 셀룰러를 쓰면서도 tunnel이 살아 있는 환경에서 **시험할 수는** 있다.
하지만 Apple은 셀룰러·VPN 상태에서의 장기 연결, 절전 복귀, `devicectl` 설치를 보장하지
않으므로 SideRefresh의 “자동 갱신 보장” 문구로 쓰면 안 된다.

### 4. Headscale

Headscale은 Tailscale control server의 오픈소스 self-hosted 구현이다. 문서상 목표도
개인/소규모 조직용 단일 tailnet control server이고, 사용에는 Tailscale client 설치 및
노드 등록이 필요하다.
[Headscale — 개요](https://headscale.net/stable/)
[Headscale — 시작하기](https://headscale.net/stable/usage/getting-started/)

따라서 Headscale은 Tailscale macOS/iOS client를 없애는 방식이 아니라 Tailscale SaaS
control plane을 self-host로 바꾸는 선택이다. 공개 운영에는 인터넷에서 도달 가능한
server, HTTPS/443, 그리고 설정·키·업데이트 관리가 요구된다.
[Headscale — Requirements and Assumptions](https://headscale.net/development/setup/requirements/)

SideRefresh가 별도 Headscale 선택지를 만들 우선순위는 낮다. 사용자가 이미 Headscale에
등록한 Tailscale client로 IP 직접 연결을 실측했다면, 제품은 provider 이름 대신 generic
IP/DNS 경로로 취급하면 된다.

### 5. ZeroTier와 NetBird

ZeroTier는 macOS와 iOS/iPadOS를 지원하며, iOS는 GUI 앱으로 제공된다. 공식 저장소는
피어 간 암호화된 네트워크와 iOS 앱 제공을 설명한다. 단, ZeroTier 문서는 iOS/iPadOS의
VPN API가 multicast/broadcast를 허용하지 않는다고 명시한다. 그러므로 ZeroTier를
Bonjour 자동 발견의 해법으로 설계하면 안 된다.
[ZeroTier — OS and Device Compatibility](https://docs.zerotier.com/compatibility/)
[ZeroTier — Bridging limitations](https://docs.zerotier.com/bridging/)
[ZeroTier 공식 저장소](https://github.com/zerotier/zerotierone)

NetBird도 iOS 앱과 macOS client를 제공하고, WireGuard 기반 peer-to-peer overlay 및
self-host 옵션을 문서화한다. NAT 때문에 직접 연결이 불가하면 relay로 암호화된 트래픽을
전달할 수 있으며, 이는 특히 셀룰러/CGNAT 환경에서 지연·대역폭 변수가 된다.
[NetBird — Mobile Applications](https://docs.netbird.io/get-started/install/mobile)
[NetBird — How NetBird Works](https://docs.netbird.io/about-netbird/how-netbird-works)
[NetBird — NAT and Connectivity](https://docs.netbird.io/about-netbird/understanding-nat-and-connectivity)
[NetBird 공식 저장소](https://github.com/netbirdio/netbird)

두 제품 모두 “iPhone과 Mac에 overlay IP를 준다”는 차원의 후보다. 어느 쪽도 Apple의
Xcode/CoreDevice 페어링이나 Personal Team 7일 만료를 제거하지 않는다. 특히 Xcode의
Bonjour 경로를 기대하지 말고 IP 직접 연결만 검증해야 하며, provider별 자동 탐색·계정
로그인·키 관리를 SideRefresh가 맡을 이유는 없다.

### 6. site-to-site VPN과 원격 Mac

site-to-site VPN은 두 사설망 사이의 IP 라우팅을 제공할 수 있다. 그러나 Apple의 문서화된
자동 발견 경로는 “같은 네트워크의 Bonjour”이고, 다른 망에서는 IP 직접 연결 절차를
쓴다. 그러므로 site-to-site 구성이 Bonjour multicast를 넘길지 가정하지 말고, 대상 IP와
TCP 62078을 검증해야 한다.
[Apple — Run an app on a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html)
[Apple — Troubleshoot a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/devac3261a70.html)

원격 Mac은 더 강한 대안이지만, 연결 프로토콜을 바꾸는 것이 아니라 **빌드·서명·설치하는
Mac을 iPhone 가까이에 옮기는 것**이다. 그 Mac에는 프로젝트 소스, 개발 인증서의
private key, 대상 device provisioning이 있어야 한다. Apple은 개발/등록 기기 배포에
서명 인증서의 public/private key와 등록 기기·프로비저닝 프로파일이 필요하다고 설명하며,
개발자 계정 자격 증명의 보호와 비인가자에게 제공하지 않을 책임을 명시한다.
[Apple — Distributing your app to registered devices](https://developer.apple.com/documentation/Xcode/distributing-your-app-to-registered-devices)
[Apple Developer Program License Agreement](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)

따라서 원격 Mac 지원은 단순 SSH 버튼이 아니라, 다음을 설계한 별도 worker 기능이어야
한다.

- 고정된 한 사용자 계정에서만 Xcode/Keychain을 사용
- 소스 checkout과 실행 가능한 명령을 allowlist로 고정
- 원격 로그인은 개인 키·MFA·최소 권한으로 제한
- 인증서 private key, pairing material, Apple 계정 secret을 로그·동기화·지원 요청에
  포함하지 않음
- 원격 Mac이 iPhone에 USB 또는 검증된 Xcode IP 경로로 실제 연결됐는지 실행 직전에 확인

### 7. AltStore와 SideStore

AltStore는 탈옥하지 않은 iOS 기기에 IPA를 설치하는 대체 앱 스토어다. 개인 개발
인증서로 앱을 재서명하고, AltServer가 iTunes Wi-Fi sync로 설치한다. 백그라운드 갱신도
AltServer와 같은 Wi-Fi에 있을 때의 모델이다.
[AltStore 공식 저장소](https://github.com/altstoreio/AltStore)
[AltStore — AltServer](https://faq.altstore.io/altstore-classic/altserver)

따라서 AltStore는 “사용자가 빌드한 Xcode project를 현재 선택 UDID에
`devicectl install`”하는 SideRefresh의 transport replacement가 아니다. AltStore를
지원하려면 IPA export, AltSource/AltServer 통합, Apple ID·인증 정책, 3-app 제한 등
별도 제품을 만들어야 한다.

SideStore도 SideRefresh와 다르다. 공식 설치 문서는 초기 USB 신뢰, pairing file,
Apple Account, 그리고 LocalDevVPN을 요구한다. 기본 요구사항과 오류 문서는 Wi-Fi가
필요하며 mobile network는 적합하지 않다고 쓰고, 갱신·설치 시 VPN이 켜져 있어야 한다고
설명한다. 다만 별도 release/advanced 문서에는 StosVPN 및 셀룰러 관련 안내가 있어
공식 문서가 하나의 안정된 셀룰러 계약을 제공하지 않는다. 그래서 셀룰러-only 갱신을
제품 보장으로 채택할 근거는 없다. pairing file은 iOS 업데이트·재설정 뒤 또는 임의
시점에 만료되어 교체가 필요할 수 있다.
[SideStore — Prerequisites](https://docs.sidestore.io/docs/installation/prerequisites)
[SideStore — Install](https://docs.sidestore.io/docs/installation/install)
[SideStore — Error Codes](https://docs.sidestore.io/docs/troubleshooting/error-codes)
[SideStore — Release Notes](https://docs.sidestore.io/docs/release-notes)

그러므로 SideStore는 “Wi-Fi 없이 순수 셀룰러에서 SideRefresh를 대체하는 방법”도 아니다.
SideRefresh가 이를 지원하지 않는 것이 기능 누락이 아니라 보안 경계와 실행 모델을
분리하는 결정이다.

### 8. TestFlight, App Store, MDM

Apple Developer Program에 가입하면 App Store Connect를 사용해 TestFlight 및 App Store
배포를 할 수 있다. TestFlight build는 최대 90일 시험 가능하며, 외부 tester에는 최초
build의 review가 필요할 수 있다.
[Apple — Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account)
[Apple — TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)

이는 iPhone이 인터넷에만 연결돼 있으면 배포·업데이트할 수 있는 일반 사용자용 탈출구다.
그러나 비용과 App Store Connect 운영이 생기며, 무료 Personal Team의 7일 프로필을
`xcodebuild`/`devicectl`로 갱신하는 흐름은 끝난다.

MDM과 Enterprise Program은 개인용 지름길이 아니다. Apple은 MDM으로 enterprise app에
필요한 provisioning profile을 배포하는 방법을 별도로 제공하고, Enterprise Program을
100명 이상인 법인 조직이 직원용 proprietary app을 안전하게 배포하는 용도로 제한한다.
[Apple — Installing provisioning profiles on devices](https://developer.apple.com/documentation/devicemanagement/installing-provisioning-profiles-on-devices)
[Apple — Apple Developer Enterprise Program](https://developer.apple.com/programs/enterprise/)

## SideRefresh 지원 우선순위

### P0 — Apple 문서 안의 신뢰 가능한 경로

1. **USB**: 예약 실행 직전 CoreDevice가 같은 UDID를 볼 때만 실행할 수 있게 상태를
   표시한다. 무선·VPN 요구를 만들지 않는다.
2. **Xcode 자동 연결 / 같은 LAN**: 최초 케이블 pairing, Trust, 같은 LAN Bonjour를
   사용자 가이드에 유지한다.
3. **IP/DNS 직접 입력**: Tailscale뿐 아니라 이미 Xcode에서 `Connect via IP Address`를
   성공시킨 모든 경로에 쓸 수 있는 provider-neutral 입력이다. 주소 자체가 성공을
   보장하지 않으므로 UDID 일치와 실제 dry run 성공을 저장해야 한다.

### P1 — 네트워크 브랜드가 아닌 사전 검증 기능

- “Xcode에서 IP 연결 확인” 체크리스트와 마지막 성공 시각을 표시한다.
- 실행 전 CoreDevice 목록에서 저장된 UDID가 보이지 않으면 빌드/설치하지 않고 재연결
  안내를 낸다.
- TCP 62078, device reachability, 일시적 절전/잠금 실패를 진단 메시지로 분리한다.
- **Tailscale/Headscale/ZeroTier/NetBird 각각의 로그인·탐색 SDK는 넣지 않는다.**
  그들은 IP를 제공하는 수단이고 Apple 개발 기기 연결의 권위자는 Xcode다.

### P2 — 명시적 experimental 기능

- WireGuard, ZeroTier, NetBird, site-to-site VPN을 “검증되지 않은 IP overlay”로
  수동 실험할 수 있게 하되, 자동 갱신 성공을 광고하지 않는다.
- 원격 Mac은 별도 worker 보안 모델과 key custody 설계가 생긴 뒤에만 검토한다.
- iPhone이 셀룰러만 쓰는 시나리오는 USB가 아닌 이상 iOS 버전·VPN·절전·carrier NAT를
  포함한 end-to-end 실측 후에만 지원 목록에 올린다.

### 지원하지 않는 경계

- AltStore/SideStore를 SideRefresh 내부에 포함하거나 Apple ID를 대신 입력·보관하지 않는다.
- 무료 Personal Team의 7일 한계를 VPN으로 없앨 수 있다고 표현하지 않는다.
- MDM/Enterprise를 개인 사용자의 자동 갱신 해법으로 안내하지 않는다.

## 사용자별 선택 요약

| 상황 | 권장 선택 |
|---|---|
| Mac과 iPhone이 같은 장소에 있음 | USB를 기본으로 사용한다. |
| 집/사무실 같은 Wi-Fi | 최초 USB 페어링 후 Xcode Bonjour, 실패하면 IP 직접 연결을 쓴다. |
| 여러 사설망·공용 Wi-Fi | VPN brand 통합 전에 Xcode IP 직접 연결 + 62078 + 실제 재설치를 검증한다. |
| iPhone이 셀룰러만 사용 | USB가 아니면 지원 보장 없음. overlay VPN은 개별 실험이며 실패 시 로컬 경로로 돌아간다. |
| 7일 갱신을 없애고 싶음 | 유료 Apple Developer Program의 TestFlight/App Store 배포를 검토한다. |
| 조직 소유 기기 다수 | Personal Team이 아니라 MDM/Business/School/Enterprise 적합성을 조직 정책과 함께 검토한다. |

## 한계와 다음 검증

이 조사는 Apple이 문서화한 Xcode 네트워크 절차와 각 VPN/사이드로더 프로젝트가
공개한 범위만 사용했다. 다음 주장은 의도적으로 하지 않는다.

- 특정 VPN이 iOS 셀룰러에서 항상 background 유지된다는 주장
- overlay VPN 위 `devicectl` install이 Apple 지원이라는 주장
- IP reachability 하나만으로 기존 Xcode pairing·Trust·프로비저닝 제약을 우회한다는 주장
- SideStore/AltStore가 SideRefresh의 Xcode source build를 투명하게 대신한다는 주장

SideRefresh에 새 연결 방식을 추가하기 전, 한 iPhone과 한 Mac의 실제 환경에서 USB →
Xcode pairing → IP 연결 → `xcodebuild` → `devicectl`의 순서로 성공/실패 로그를 남기는
작은 호환성 매트릭스를 먼저 만든다. 그 결과가 있어야 “지원”과 “실험”을 정직하게 나눌
수 있다.
