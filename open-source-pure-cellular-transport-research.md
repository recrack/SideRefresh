# 순수 셀룰러 iOS 재설치·7일 갱신 — 오픈소스 운송 수단 조사

조사일: 2026-07-24
조건: 무료 Personal Team, 네이티브 IPA, iPhone은 Wi‑Fi 비연결·셀룰러만 사용, Tailscale은 계속 사용, 탈옥/취약점/상시 USB 게이트웨이 없음.

## 결론

위 조건을 **동시에** 만족하는 검증된 오픈소스 프로젝트는 찾지 못했다. 특히 “Tailscale을 iPhone에서 계속 활성화”라는 조건 때문에, 자체 VPN을 써야 하는 SideStore 계열은 대체제가 될 수 없다.

다만 이는 “통신을 중계하는 방법을 만들 수 없다”는 뜻은 아니다. `pymobiledevice3`/CoreDevice를 바탕으로 한 **새 오픈소스 harness**의 연구 여지는 있다. 하지만 현재 upstream이 제공하는 경로는 Bonjour로 발견한 Wi‑Fi RemotePairing 또는 USB/USB Ethernet이고, **Tailscale IP를 받아 순수 셀룰러 iPhone으로 개발 설치하는 완성된 경로는 없다**. 따라서 이 경로는 기존 도구 설치가 아니라 실기기 PoC가 먼저인 신규 구현이다.

## 후보 판정

| 도구 | 실제 할 수 있는 일 | 순수 셀룰러 + Tailscale 유지 + 7일 갱신 |
| --- | --- | --- |
| AltStore Classic | Mac AltServer로 개인 개발 인증서 재서명·갱신 | 불가: 공식 동작 조건은 AltServer와 같은 Wi‑Fi 또는 USB |
| SideStore | 기기 내 재서명·갱신, 자체 LocalDevVPN | Tailscale 유지 조건에서는 불가: iOS는 한 번에 VPN 하나만 활성화 |
| Feather | 사용자가 가진 유효한 인증서/프로파일로 기기 내 IPA 서명·설치 | 불가: 무료 Personal Team 프로파일 재발급/7일 갱신을 수행하지 않음 |
| JitStreamer / JitStreamer-EB | Tailscale/WireGuard를 통한 원격 JIT | 불가: IPA 설치·서명·프로파일 갱신 기능이 아님 |
| `usbfluxd` | USB에 연결된 iPhone을 다른 컴퓨터에 USB 장치처럼 중계 | 불가: 원격 쪽에 iPhone이 물리적으로 USB 연결돼 있어야 함 |
| `usbmuxd2` | Bonjour로 무선 iOS 기기를 발견·heartbeat 유지 | 불가: 현재 소스에서 일반 포트 연결 자체가 미구현이며, 임의 Tailscale IP 직접 연결도 없음 |
| `pymobiledevice3` / go-ios | iOS 통신·설치용 저수준 구현체 | **harness의 기반 후보**일 뿐, 이 조건을 만족하는 완성품은 아님 |

## 도구별 근거

### AltStore Classic

AltServer는 `WirelessConnectionHandler`와 `WiredConnectionHandler`로 요청을 받고, 설치 직전에 `ALTDeviceManager.shared.availableDevices`에서 대상 UDID가 보여야 한다. 즉 AltStore 앱과 Mac 사이의 통신을 Tailscale로 우회하더라도, Mac의 Apple 기기 관리 계층이 iPhone을 사용 가능한 기기로 인식해야 한다. [AltServer 요청 처리 코드](https://github.com/altstoreio/AltStore/blob/develop/AltServer/Connections/RequestHandler.swift) · [무선/유선 handler 등록](https://github.com/altstoreio/AltStore/blob/develop/AltServer/Connections/RequestHandler.swift#L12-L15)

공식 프로젝트 설명도 갱신 시 AltServer와 같은 Wi‑Fi에 있어야 한다고 명시한다. 따라서 Tailscale 자체는 AltStore의 순수 셀룰러 해법이 아니다. [AltStore README](https://github.com/altstoreio/AltStore#readme)

### SideStore — 유일한 셀룰러 후보였지만 Tailscale과 양립하지 않음

SideStore는 Apple ID/Personal Team으로 서명한 앱의 갱신을 목표로 하는 AGPL 프로젝트다. 과거 병합된 PR에는 StosVPN으로 셀룰러 갱신이 가능하다는 주장과 0.6.2 릴리스 반영이 있다. 이후 최신 구현에서는 StosVPN 표기를 LocalDevVPN으로 바꿨다. [cellular PR #935](https://github.com/SideStore/SideStore/pull/935) · [LocalDevVPN 전환 PR #1126](https://github.com/SideStore/SideStore/pull/1126)

그러나 최신 공식 문서는 여전히 설치·갱신에 “Wi‑Fi와 LocalDevVPN”을 요구하고, 오류 1414도 Wi‑Fi 또는 LocalDevVPN 부재로 정의한다. 그러므로 **셀룰러 전용은 과거 구현 주장과 현재 문서가 충돌하는 실험 조건**이지 보장 기능이 아니다. [SideStore prerequisite](https://docs.sidestore.io/docs/installation/prerequisites) · [오류 코드 1414](https://docs.sidestore.io/docs/troubleshooting/error-codes)

더 결정적으로 LocalDevVPN은 iOS VPN 구성이다. Tailscale 공식 문서는 iOS에서 동시에 활성화할 수 있는 VPN이 하나뿐이라고 설명한다. 즉 SideStore의 셀룰러 PoC가 성공해도, 사용자의 “Tailscale은 유지” 조건에서는 Tailscale을 끄거나 교체해야 한다. [Tailscale: 다른 VPN과 함께 사용](https://tailscale.com/docs/reference/faq/other-vpns)

### Feather

Feather는 `.p12` 인증서와 `.mobileprovision` 프로파일 쌍으로 IPA를 기기 내 서명·설치하는 GPL 프로젝트다. 유효한 인증서 쌍을 전제로 하므로, 무료 Personal Team의 Apple API 인증·새 프로파일 발급·주간 재설치를 자동화하는 도구는 아니다. [Feather README](https://github.com/khcrysalis/Feather) · [서명 동작 설명](https://github.com/khcrysalis/Feather/blob/main/HOW_IT_WORKS.md)

### JitStreamer / JitStreamer-EB

이 둘은 Tailscale 또는 WireGuard를 사용한 원격 **JIT 활성화** 사례라서 헷갈리기 쉽다. JitStreamer는 Tailscale, pairing file, SideStore의 `SideJITServer` 설정을 요구하며, 코드도 `InstallationProxy`로 개발 가능한 앱 목록을 읽어 debug proxy에 attach해 JIT를 켠다. IPA를 서명하거나 설치·갱신하는 엔드포인트는 없다. [JitStreamer README](https://github.com/joshrad-dev/JitStreamer#readme) · [JIT 동작 소스](https://github.com/joshrad-dev/JitStreamer/blob/main/JitStreamer/__init__.py)

따라서 JitStreamer가 Tailscale에서 동작한다는 사실은 “iPhone에 앱을 원격 설치할 수 있다”의 증거가 아니다.

### usbfluxd / usbmuxd2

`usbfluxd`는 표준 usbmuxd 소켓을 다른 호스트에 노출해 원격 iPhone을 로컬 USB처럼 보이게 하는 도구다. 공식 Linux 사용법의 출발 조건은 명시적으로 “iPhone을 USB로 연결”한 뒤 그 usbmuxd 소켓을 TCP로 노출하는 것이다. 상시 USB 게이트웨이를 금지한 이 요구에는 맞지 않는다. [usbfluxd README](https://github.com/corellium/usbfluxd#linux-usage)

`usbmuxd2`는 이름과 달리 현재 Wi‑Fi 매니저가 `_apple-mobdev2._tcp`/`_remotepairing-manual-pairing._tcp`를 mDNS로 browse하는 구조다. 그리고 발견한 Wi‑Fi 장치의 일반 연결 함수는 소스에 `Legacy connection proxying is currently not implemented`라고 명시되어 있다. 따라서 현 상태에서 임의 Tailscale IP를 넣어 설치 트래픽을 보내는 해법이 아니다. [Wi‑Fi mDNS discovery](https://github.com/tihmstar/usbmuxd2/blob/master/usbmuxd2/Manager/WIFIDeviceManager-mDNS.cpp) · [미구현된 Wi‑Fi 연결](https://github.com/tihmstar/usbmuxd2/blob/master/usbmuxd2/Devices/WIFIDevice.cpp#L98-L100)

### pymobiledevice3와 custom harness

`pymobiledevice3`는 앱 설치 API와 iOS 17+ 개발 서비스 tunnel을 제공하므로 가장 현실적인 기반이다. 그러나 upstream의 Wi‑Fi 경로는 `_remotepairing._tcp.local.` Bonjour browse로 장치를 찾고, `tunneld`도 Wi‑Fi/USB/usbmux monitor에서 발견된 장치만 대상으로 한다. `/start-tunnel`의 `ip`은 발견된 장치의 주소를 **필터링**할 뿐, 새로운 Tailscale IP에 직접 dial하는 옵션이 아니다. [iOS 17+ tunnel 문서](https://doronz88.github.io/pymobiledevice3/guides/ios17-tunnels/) · [Bonjour 상수와 browse](https://github.com/doronz88/pymobiledevice3/blob/master/pymobiledevice3/bonjour.py) · [tunneld의 발견 기반 시작 로직](https://github.com/doronz88/pymobiledevice3/blob/master/pymobiledevice3/tunneld/server.py)

그러므로 가능한 오픈소스화 방향은 다음처럼 명확하다.

```text
Tailscale 상태/IP 조회(사용자 승인 후, 읽기 전용)
    → iPhone CoreDevice/RemotePairing 서비스가 Tailnet에서 실제 응답하는지 PoC
    → 응답한다면: 인증된 pair record + RemotePairing/RSD tunnel + InstallationProxy를 묶는 harness
    → 6일 주기: Xcode/Apple 계정으로 재서명 후 harness가 덮어설치
```

하지만 첫 번째 단계, 즉 **Wi‑Fi association이 완전히 없는 iPhone이 해당 개발 서비스 포트를 Tailnet에 열고 유지하는지**는 upstream이 보장하지 않고 실기기 검증 전에는 가정할 수 없다. 지금 공개된 Tailscale bridge 사례도 iPhone을 다른 SSID/핫스팟 Wi‑Fi에는 연결한 상태에서만 성공했다고 보고한다. [현장 구현 보고](https://dev.to/kvnpt/how-to-remotely-iterate-deploy-your-sideloaded-ios-apps-over-tailnet-jak)

## 권고

1. **Tailscale을 유지해야 한다면** SideStore·JitStreamer·usbfluxd를 자동 설치 후보에서 제외한다.
2. Xcode 직접 IP/Tailscale 또는 `pymobiledevice3` 기반 custom harness를 하나의 실험 브랜치로 취급한다. 설치 자동화는 이 PoC가 순수 셀룰러에서 성공한 뒤에만 설계한다.
3. 사용자에게 자동으로 VPN 전환, Tailscale 설정 변경, USB 연결을 요구하거나 실행하지 않는다. Tailscale 장치 IP 조회도 사용자가 명시적으로 실행을 승인했을 때만 읽는다.
