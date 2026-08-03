# SideRefresh 갱신 연결 경로 용어

조사일: 2026-08-01
범위: Apple 공식 Xcode 문서와 현재 SideRefresh 도메인 문서·소스

## 결론

프로토타입의 **“USB 또는 같은 Wi‑Fi에서 Xcode가 이 iPhone을 찾았습니다”**는 바꿔야 한다. 현재 SideRefresh는 `devicectl list devices` 결과에서 UDID와 `pairingState`만 보존하고 전송 방식을 읽지 않으므로 USB인지 Wi‑Fi인지 알 수 없다. 또한 Apple의 네트워크 경로는 같은 네트워크의 Bonjour뿐 아니라, 페어링된 기기에 대한 직접 IP 연결도 포함한다. ([프로토타입 state.js](../iphone-connection-prototype/state.js#L6-L12), [CoreDeviceReader.swift](../../Sources/SideRefreshCore/CoreDeviceReader.swift#L3-L16), [CoreDeviceReader.swift](../../Sources/SideRefreshCore/CoreDeviceReader.swift#L101-L130), [Apple — Run an app on a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html))

따라서 **USB / 로컬 네트워크 / Tailscale 원격**을 동급의 “갱신 경로” 세 개로 제시하지 않는다. 제품의 실제 구조는 다음 두 층이다.

1. **Xcode/CoreDevice 연결**: USB 또는 Xcode가 성립시킨 네트워크 연결(Bonjour 자동 발견이나 직접 IP)을 사용한다.
2. **실험적 연결 준비·진단**: Tailscale에서 iPhone과 주소를 찾을 수 있지만, 이것은 Xcode 연결이나 갱신 성공이 아니다.

Apple은 최초 네트워크 페어링에 기기 신뢰와 케이블 또는 현재 Device Hub의 무선 페어링 절차를 요구한다. 같은 네트워크에서는 Bonjour를 쓰며, 발행 중인 Xcode 도움말은 **Connect via IP Address** 절차도 제공한다. 연결 증거는 Device Hub/Xcode에 기기가 사용 가능하거나 **Connected**로 표시되는 것이다. ([Apple — Managing devices in Device Hub](https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub), [Apple — Pair a wireless device with Xcode](https://help.apple.com/xcode/mac/current/en.lproj/devbc48d1bad.html), [Apple — Run an app on a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/dev3e2f4ee6d.html))

“USB”와 “네트워크”도 구현상 완전히 분리된 프로토콜 이름은 아니다. Apple은 Xcode 15 이후 USB 연결 기기와도 link-local IPv6 기반 네트워크 인터페이스로 통신한다고 설명한다. 그러므로 UI는 관찰하지 않은 전송 방식을 단정하기보다 Xcode/CoreDevice 연결 증거를 표시해야 한다. ([Apple — TN3158: Resolving Xcode 15 device connection issues](https://developer.apple.com/documentation/technotes/tn3158-resolving-xcode-15-device-connection-issues))

## 증거를 섞지 않는 기준

| 개념 | 의미와 현재 증거 | 안전한 UI 상태 |
| --- | --- | --- |
| 갱신 작업 | SideRefresh가 빌드·서명·Bundle ID 검증·설치를 수행한다. 연결 방식과는 별개다. ([SideRefreshIOSRenewal/main.swift](../../Sources/SideRefreshIOSRenewal/main.swift#L89-L271)) | `앱 빌드·서명·설치 중` |
| 기기 연결/전송 | 실제 명령은 같은 UDID를 `xcodebuild` destination과 `devicectl --device`에 전달하고, USB·Bonjour·직접 IP를 선택하는 인자는 없다. ([IOSAppRenewalPlan.swift](../../Sources/SideRefreshCore/IOSAppRenewalPlan.swift#L166-L247)) | `Xcode/CoreDevice 연결 사용` |
| 발견 증거 | 현재 목록 조회는 페어링된 UDID를 찾지만 전송 방식이나 설치 가능성을 증명하지 않는다. ([CoreDeviceReader.swift](../../Sources/SideRefreshCore/CoreDeviceReader.swift#L33-L98), [CoreDeviceReader.swift](../../Sources/SideRefreshCore/CoreDeviceReader.swift#L173-L243)) | `페어링된 기기 목록에서 확인됨` |
| 구성된 경로 | UI에는 자동/Tailscale/직접 주소가 있지만, 실행 설정에는 선택적으로 Tailscale 실행 파일·Node ID·DNS 이름만 저장된다. 직접 입력 주소는 UI의 `UserDefaults`에만 남고 Agent 실행 설정에는 들어가지 않는다. ([RenewalTargetDraft.swift](../../Sources/SideRefreshApp/RenewalTargetDraft.swift#L4-L20), [AgentConfiguration.swift](../../Sources/SideRefreshCore/AgentConfiguration.swift#L20-L42), [SideRefreshViewModel.swift](../../Sources/SideRefreshApp/SideRefreshViewModel.swift#L69-L104), [SideRefreshViewModel.swift](../../Sources/SideRefreshApp/SideRefreshViewModel.swift#L747-L792)) | `Tailscale 대상 저장됨` 또는 `IP 주소로 Xcode 연결 필요` |
| Verified renewal | 설치 성공 뒤 서명 만료 증거까지 기록해야 한다. 과거 증거는 현재 연결을 뜻하지 않는다. ([CONTEXT.md](../../CONTEXT.md#L79-L89), [RenewalEngine.swift](../../Sources/SideRefreshCore/RenewalEngine.swift#L147-L213)) | `갱신 확인됨 · <시각>`과 만료일 |

## Tailscale 온라인의 한계

**Tailscale 온라인만으로 Xcode 도달 가능성을 증명할 수 없다.** 현재 사전 확인은 `tailscale status --json`에서 저장된 노드가 온라인이고 주소가 있는지만 검사한 뒤, 그 주소를 사용하지 않은 채 동일한 UDID 기반 갱신 명령을 실행한다. ([TailscaleStatusReader.swift](../../Sources/SideRefreshCore/TailscaleStatusReader.swift#L36-L67), [TailnetTarget.swift](../../Sources/SideRefreshCore/TailnetTarget.swift#L35-L55), [ConfiguredRenewalRunner.swift](../../Sources/SideRefreshCore/ConfiguredRenewalRunner.swift#L86-L125))

반면 Apple의 네트워크 진단은 Xcode의 **Connected** 표시, IP 도달성, 그리고 기기 통신 포트 62078을 별도로 확인한다. Apple 문서는 Tailscale/VPN 위의 CoreDevice 설치를 보장하지 않는다. 그러므로 “Tailscale 온라인 → 연결 완료/갱신 가능”은 근거 없는 승격이다. ([Apple — Troubleshoot a wireless device](https://help.apple.com/xcode/mac/current/en.lproj/devac3261a70.html))

도메인 용어도 이를 분리한다. **Direct-IP device connection**은 Xcode 경로이고, **Tailnet device discovery**는 읽기 전용 진단이며, **CoreDevice/Tailnet bridge**는 별도의 실험적 프록시·릴레이다. 현재 소스에는 브리지 구현이나 Xcode 직접 IP 등록 자동화가 없다. ([CONTEXT.md](../../CONTEXT.md#L19-L29), [SideRefreshApp.swift](../../Sources/SideRefreshApp/SideRefreshApp.swift#L2991-L3118))

## 권장 한국어 UI 문구

준비 상태의 프로토타입 문구:

- 상태: **`Xcode 기기 확인됨`**
- 제목: **`Xcode에서 이 iPhone을 확인했습니다.`**
- 설명: **`페어링된 기기 목록에서 선택한 iPhone의 UDID를 확인했습니다. 현재 전송 경로는 구분하지 않습니다.`**

연결 설정은 다음처럼 계층화한다.

- **`Xcode/CoreDevice 연결`**
  - `자동 연결 (USB 또는 네트워크)`
  - 도움말: `같은 로컬 네트워크에서는 자동으로 찾을 수 있습니다. 필요하면 Xcode에서 IP 주소로 연결하세요.`
- **`Tailscale 주소 찾기 · 실험적`**
  - 상태: `Tailscale 주소 확인 완료`
  - 다음 행동: `Xcode에서 iPhone 확인`
  - 도움말: `Tailscale 주소를 확인했습니다. Xcode/CoreDevice에서 같은 설치 기기를 확인하세요.`

`연결 완료`는 Xcode/CoreDevice의 실제 연결 증거가 있을 때만, `갱신 확인됨`은 설치와 서명 만료 증거가 모두 기록됐을 때만 사용한다. Tailscale은 **원격 갱신 경로**가 아니라, 검증 전 단계에서는 **실험적 직접-IP 연결 준비 수단**으로 표시한다.
