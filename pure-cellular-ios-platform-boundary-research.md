# 순수 셀룰러 iOS 개발 앱 갱신: 플랫폼 경계 검증

조사일: 2026-07-24
대상 조건: 본인 iPhone 1대, 무료 Apple Personal Team, iOS 17 이상, Tailscale 상시 사용, 탈옥·취약점·유료 멤버십·Enterprise 자격 없이 **Wi-Fi가 꺼져 있거나 어느 SSID에도 연결되지 않은 순수 셀룰러 상태**에서 네이티브 앱을 설치 또는 7일 갱신.

## 결론

이 조건을 모두 만족한다고 **독립 검증된 방법은 확인하지 못했다.** 다만 이전 조사에서 빠뜨렸던, Apple이 문서화한 **직접 IP 연결**은 정확한 조건에서 시험할 가치가 있는 후보로 확인됐다.

- Apple의 Xcode에는 같은 네트워크의 Bonjour 발견 경로와, 이미 페어링한 기기에 IP 주소를 직접 입력하는 경로가 모두 있다. 후자는 Tailscale IP를 넣어 시험할 수 있다.
- iOS 17+ 개발 서비스의 공개 오픈소스 구현(`pymobiledevice3`)도 RemotePairing 경로를 Wi-Fi 전용으로 분류한다. iOS 17.4+의 다른 경로는 USB의 `CoreDeviceProxy`를 사용한다.
- Tailscale 자체는 셀룰러에서도 상시 연결할 수 있다. 하지만 이는 전송망일 뿐, iPhone이 셀룰러 상태에서 CoreDevice/개발 설치 서비스를 수신하게 만드는 권한이나 API는 아니다.
- 무료 Personal Team은 프로파일 만료 뒤 **새로 빌드하고 다시 설치**해야 한다. 프로파일의 기간만 원격으로 연장하는 API는 없다.

Apple의 비공개 CoreDevice 구현까지 포함한 수학적 “절대 불가능” 증명도 아니다. Apple은 해당 listener가 Wi-Fi 미연결에서 실제로 어떻게 바인딩되는지, Tailscale의 Network Extension IP를 직접 목적지로 삼을 때의 지원 여부를 공개하지 않는다. 따라서 정확한 판정은 **“순수 셀룰러 + Tailscale IP 설치는 아직 검증되지 않았지만, 공식 직접-IP 기능을 이용한 작은 PoC가 남아 있다”** 이다.

## 검증된 사실

### 1. 무료 Personal Team의 만료와 설치 방식

Apple은 무료 계정의 Personal Team에서 설치용 provisioning profile이 발급 후 7일에 만료되고, 만료 후에는 앱을 다시 빌드하여 기기에 재설치해야 한다고 명시한다. 이는 ‘같은 프로파일의 자동 연장’이 아니라 새 서명 자산으로 앱을 다시 설치하는 문제다. [Apple Developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account)

### 2. Apple에는 Bonjour와 직접 IP라는 두 무선 개발 연결 경로가 있다

현재 Device Hub 문서는 무선으로 기기를 페어링하기 전에 Mac과 기기를 같은 Wi-Fi에 두어 발견하게 하라고 안내하며, 케이블을 뺀 뒤에도 같은 네트워크의 Wi-Fi로 Xcode 실행을 설명한다. [Apple Device Hub: physical device pairing](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub)

그러나 Xcode의 별도 공식 도움말은 최초 페어링 후 앱을 “Wi-Fi 또는 다른 네트워크 연결”로 실행할 수 있다고 하며, Mac과 기기가 같은 네트워크가 아니면 Bonjour 대신 **기기의 IP 주소로 연결**하라고 명시한다. [Apple Xcode Help: Run an app on a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html)

이 직접-IP 메뉴가 iPhone의 Tailscale `100.x.y.z` 주소를 순수 셀룰러에서 받아들이는지는 문서화되어 있지 않다. 하지만 이 기능은 “Tailscale은 단지 통신 수단이고, 직접 IP를 넣으면 되지 않나?”라는 요구에 정확히 대응하는 **공식 PoC 진입점**이다. 같은 Wi-Fi가 필요한 것은 Bonjour 자동 발견 경로이지, 직접-IP 메뉴 전체에 명시된 조건은 아니다.

Apple Platform Security는 더 넓은 host-pairing 모델에서 Xcode development 등을 위한 암호화 세션이 호스트의 Wi-Fi 연결과 최초 물리 페어링을 요구한다고 설명한다. [Apple Platform Security: Physical pairing](https://support.apple.com/en-gb/guide/security/secadb5b6434/1/web/1) 이 문서는 셀룰러+Tailscale을 승인하지 않으므로 성공 보장은 하지 못한다. 동시에 최신 Xcode 도움말의 “other network connection / IP address”와 충돌 여지가 있어, 이 둘만으로 순수 셀룰러를 가능·불가능 어느 쪽으로도 단정할 수 없다.

### 3. iOS 17+ 오픈소스 구현의 전송 경로

`pymobiledevice3`는 iOS 17부터 개발 서비스가 CoreDevice/RemoteXPC와 RSD tunnel을 사용한다고 문서화한다. 특히 다음을 구분한다.

- iOS 17.0–17.3.1: RemotePairing 경로는 “Wi-Fi-only”라고 명시한다.
- iOS 17.4+: `CoreDeviceProxy` lockdown service를 **USB**로 이용하는 userspace tunnel을 지원한다.
- RemotePairing pair record를 만드는 bootstrap 절차도 이미 신뢰된 USB lockdownd를 이용한다고 문서화한다.

출처: [pymobiledevice3 iOS 17+ tunnel 문서](https://doronz88.github.io/pymobiledevice3/guides/ios17-tunnels/).

소스도 RSD 기기 검색을 `_remoted._tcp.local.`의 로컬 mDNS/Bonjour browse로 구현한다. 원격 IP나 Tailscale hostname으로 해당 개발 서비스를 직접 발견·설치하는 별도 경로는 이 구현에 없다. [서비스 타입과 browse 구현](https://github.com/doronz88/pymobiledevice3/blob/master/pymobiledevice3/bonjour.py#L22-L26) · [RSD를 Bonjour에서 찾는 코드](https://github.com/doronz88/pymobiledevice3/blob/master/pymobiledevice3/remote/remote_service_discovery.py#L387-L397)

이것은 그 프로젝트의 구현과 지원 범위에 대한 1차 증거다. Apple의 CoreDevice 서버 전체가 공개된 것은 아니므로, 이를 iOS 자체의 완전한 규격으로 과대해석하지 않는다.

Bonjour 자동 발견이 Tailnet에서 바로 동작하지 않는 이유도 확인했다. Apple이 공개한 macOS `mDNSResponder` 소스는 multicast-capable이면서 point-to-point가 아닌 인터페이스에만 mDNS multicast를 송수신한다고 명시한다. [mDNSResponder 소스](https://github.com/apple-oss-distributions/mDNSResponder/blob/8f70f98fc1d0cf439ca3a6470be6ad8ac2bcc019/mDNSMacOSX/mDNSMacOSX.c#L2500-L2523) 이는 Tailscale 같은 터널 인터페이스에서 Bonjour 발견이 자동으로 되지 않는 설명이며, **직접 IP 연결이나 iPhone의 listener 정책을 불가능하다고 증명하는 것은 아니다.**

### 4. Tailscale은 셀룰러 전송에는 쓸 수 있지만, 다른 VPN과 병행할 수 없다

Tailscale의 iOS VPN On Demand는 셀룰러 연결 시 `Always`로 자동 연결할 수 있다. 따라서 “Tailscale이 셀룰러라서 안 된다”는 것이 원인은 아니다. [Tailscale iOS VPN On Demand](https://tailscale.com/docs/features/client/ios-vpn-on-demand)

반면 iOS는 동시에 활성화할 수 있는 VPN이 하나뿐이라고 Tailscale이 명시한다. 그러므로 LocalDevVPN을 쓰는 SideStore류를 Tailscale 상시 사용 조건과 동시에 정상 해법으로 제시할 수 없다. [Tailscale: other VPNs](https://tailscale.com/docs/reference/faq/other-vpns)

### 5. MDM/OTA는 무료 개발 IPA의 설치 권한을 만들지 않는다

Apple의 MDM 앱 관리 문서는 iOS의 관리 앱 소스를 App Store 또는 Enterprise app으로 열거하고, `ManifestURL`은 enterprise app의 manifest라고 규정한다. 개인용 무료 개발 프로파일을 MDM 서버·APNs·Tailscale로 운반한다고 해서 Enterprise 서명 자격으로 바뀌지 않는다. [Apple: installing and managing apps](https://developer.apple.com/documentation/devicemanagement/installing-managing-updating-and-removing-apps)

Enterprise 배포도 개인 1명용 우회 수단이 아니다. Apple은 100명 이상 직원이 있는 법인의 직원 전용 내부 배포에만 Enterprise Program을 허용한다. [Apple Developer Enterprise Program](https://developer.apple.com/programs/enterprise/)

## 검토한 오픈소스 경로

| 경로 | 근거 | 순수 셀룰러 조건 판정 |
| --- | --- | --- |
| AltStore Classic | 클라이언트가 Bonjour service를 찾아 `NWConnection(to: .service(...))`로 연결한다. [소스](https://github.com/altstoreio/AltStore/blob/develop/AltStore/Server/ServerManager.swift#L32-L54) · [연결 코드](https://github.com/altstoreio/AltStore/blob/develop/AltStore/Server/ServerManager.swift#L102-L118) | 불충족: 원격 Tailscale 대상 주소를 정상 기능으로 지정하는 경로가 없다. |
| SideStore/LocalDevVPN | LocalDevVPN이 필요하고 iOS의 단일 VPN 제한과 충돌한다. [SideStore 소스](https://github.com/SideStore/SideStore) · [Tailscale 제한](https://tailscale.com/docs/reference/faq/other-vpns) | 불충족: Tailscale 상시 사용 조건을 깬다. |
| JitStreamer | pairing file 뒤 Tailscale/VPN으로 JIT tunnel을 여는 오픈소스 도구다. [프로젝트 안내](https://github.com/joshrad-dev/JitStreamer) | 부분 증거: VPN을 통한 개발 tunnel 가능성을 보이지만 JIT만 다루며 IPA 설치·7일 갱신·순수 셀룰러를 입증하지 않는다. |
| `pymobiledevice3` | 위 3절의 CoreDevice tunnel 구현 | 불충족: 공개 지원 경로가 Wi-Fi RemotePairing 또는 USB다. |
| `usbmuxd2` | Wi-Fi 기기의 `start_connect`는 “Legacy connection proxying is currently not implemented”로 종료된다. [해당 소스](https://github.com/tihmstar/usbmuxd2/blob/744c46fc7faf61ed87b38bc97b1ac793d50e163d/usbmuxd2/Devices/WIFIDevice.cpp#L88-L110) | 불충족: Tailscale을 통한 Wi-Fi-device 연결 대행 자체가 구현돼 있지 않다. |
| `usbfluxd`/USB-over-IP | 원격 장치의 물리 USB 연결을 host에 중계한다. [usbfluxd](https://github.com/corellium/usbfluxd) | 조건 밖: iPhone이 다른 장비에 계속 USB로 연결돼 있어야 한다. |

## 보조 주장: CoreDevice/Tailnet bridge

2026년 5월의 한 독립 재현 보고는 Mac의 로컬 Bonjour proxy와 TCP/UDP relay를 조합해, 서로 다른 Wi-Fi에 있는 iPhone으로 `xcrun devicectl` 설치를 수행했다고 주장한다. 이 방식은 “Mac과 iPhone이 같은 Wi-Fi여야 한다”는 문제에는 유효한 PoC 후보이며, Apple 바이너리를 바꾸지 않고 Tailscale을 실제 데이터 경로로 사용한다. [재현 보고](https://dev.to/kvnpt/how-to-remotely-iterate-deploy-your-sideloaded-ios-apps-over-tailnet-jak)

그러나 이 보고는 **2차 출처이자 단일 재현 사례**다. 더 중요하게 저자는 iPhone이 임의의 Wi-Fi SSID에는 연결돼 있어야 하며, Wi-Fi 미연결·순수 셀룰러에서는 개발 서비스 포트가 열리지 않았다고 썼다. 이는 현재 질문의 답을 바꾸는 증거가 아니다. 독립 소스나 Apple 문서로 그 조건을 재현·검증하지 못했으므로, 이 관찰은 ‘검증된 iOS 규격’이 아니라 **미검증 관찰**로만 취급한다.

## 판정과 다음 검증 기준

### 이번 SideRefresh 티켓의 판정

“초기 설정 뒤, Wi-Fi 연결·USB·수동 조작 없이 iPhone이 순수 셀룰러로 유지된 상태에서 무료 Personal Team 앱을 원격 자동 갱신”은 현재 조사 범위에서 **검증 완료된 방법은 없다.** 그러나 Apple의 직접-IP 연결 기능 때문에 “방법이 없다”로 티켓을 닫는 것도 부정확하다.

정확한 다음 행동은 7일 자동화 구현이 아니라, 최초 USB 페어링 뒤 다음 단일 PoC를 수행하는 것이다.

1. iPhone의 Wi-Fi를 끄거나 어떤 SSID에도 연결하지 않고, Tailscale VPN On Demand를 `Cellular = Always`로 둔다.
2. Mac과 iPhone의 Tailscale ACL이 서로의 접속을 허용하는지 확인하고 iPhone의 Tailscale IP를 얻는다.
3. Xcode의 **Devices and Simulators → 기기 우클릭 → Connect via IP Address**에 그 IP를 넣는다.
4. Xcode에서 Personal Team 앱 1회를 Build & Run한다. 성공하면 먼저 Xcode 연결이 유지되는지, 다음으로 `devicectl`/빌드 스케줄러가 같은 페어링 경로를 재사용하는지를 별도로 검증한다.

이 조사에서는 실제 기기·Tailscale 설정을 변경하지 않았으므로, 이 PoC의 성공 여부는 아직 알 수 없다.

### 이 결론을 뒤집을 수 있는 증거

다음 셋 중 하나가 확인되면 재평가할 만하다.

1. Wi-Fi가 꺼진 실제 iPhone에서, 최초 페어링 뒤 Tailscale IP를 Xcode에 넣어 Personal Team 앱 설치까지 성공한 재현. 가장 먼저 해야 할 PoC다.
2. Wi-Fi가 꺼진 실제 iPhone에서, 위의 연결을 `devicectl` 또는 Xcode command-line build가 재사용해 7일 갱신까지 성공한 재현.
3. Apple이 무료 development provisioning profile을 Enterprise가 아닌 OTA/MDM `ManifestURL` 설치 대상으로 허용한다는 공식 문서.

현 시점에서 1~3의 성공 근거는 찾지 못했다. 따라서 남은 합리적 작업은 자동화를 바로 구축하는 것이 아니라, 이 **직접-IP 순수 셀룰러 PoC**부터 수행하는 것이다. 실패하면 그때에만 다른 Wi-Fi에 연결된 상태의 CoreDevice/Tailnet bridge를 별도, 완화된 요구사항으로 판단한다. 이 조사에서는 시스템 설정을 변경하지 않았다.
