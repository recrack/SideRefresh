# SideRefresh 오픈소스 가능성 및 경쟁 지형 조사

> 라이선스 정책 변경: 이 문서의 SideRefresh MIT 권고는 당시 판단을 보존한
> 역사적 기록이다. `v0.2.0-beta.2`부터 적용되는 Apache-2.0 및 브랜드 경계는
> [ADR 0001](../adr/0001-apache-2-license-and-brand-boundary.md)이 대체한다.

> 조사 기준일: 2026-07-29
> 범위: 당시 비공개 개발 저장소의 읽기 전용 점검과 프로젝트별 공식
> 문서·공식 저장소만 비교했다. 저장소 상태 관찰은 역사적 스냅샷이다.
> 결론: **P0 공개 준비를 마친 뒤 오픈소스로 전환하는 것을 권장한다(GO).** 다만 소스 공개와 일반 사용자가 바로 설치할 수 있는 바이너리 배포는 분리해서 진행해야 한다.

## 1. 결정 요약

SideRefresh는 오픈소스로 공개할 가치가 있다. 해결하는 문제는 Apple의 Personal Team 프로비저닝이 7일 뒤 만료되어 앱을 다시 빌드·설치해야 한다는 실제 제약이다. Apple도 무료 Personal Team의 App ID, 기기 등록과 프로비저닝 프로파일이 7일 후 만료된다고 명시한다.[Apple 개발자 계정 안내](https://developer.apple.com/help/account/basics/about-your-developer-account)

직접 경쟁군은 이미 크다. AltStore, SideStore, ReProvision Reborn은 7일 갱신 문제를 다루고, fastlane과 XcodeBuildMCP는 빌드 자동화 기반을 제공한다. 그러나 조사한 공식 프로젝트 중 SideRefresh와 동일하게 아래 조건을 모두 결합한 제품은 찾지 못했다.

- 사용자가 보유한 Xcode 소스에서만 빌드
- 사용자가 이미 Xcode에 로그인한 서명 환경을 재사용
- Apple 계정·비밀번호를 앱이 수집하거나 보관하지 않음
- 실제 프로파일 만료일과 갱신 결과를 영수증 형태로 추적
- 사용자 승인 LaunchAgent로 예약 갱신
- 동일 엔진을 macOS UI, CLI, MCP에서 제공
- 실패를 성공으로 기록하지 않는 보수적 상태 모델

이는 “전 세계에 같은 프로젝트가 없다”는 증명이 아니라, 아래 명시한 공식 프로젝트와 GitHub 검색 범위에서 발견하지 못했다는 결과다. 따라서 포지셔닝은 **“또 하나의 IPA 사이드로더”가 아니라 “Personal Team용 소스 갱신 오케스트레이터”**가 적합하다.

조사 당시 판단은 다음과 같다.

| 항목 | 판단 |
| --- | --- |
| 소스 오픈소스 공개 | P0 점검 후 가능 |
| 개발자 대상 소스 프리뷰 | 준비도 높음 |
| 일반 사용자용 설치 바이너리 | 아직 준비 부족 |
| Mac App Store 배포 | 구조적으로 높은 심사 위험, 비권장 |
| 권장 배포 | MIT 소스 + Developer ID 서명·공증 ZIP + GitHub Releases |
| Homebrew | 서명된 안정 바이너리와 사용 수요를 확인한 뒤 Cask 제공 |

## 2. SideRefresh가 해결하는 문제와 법적 경계

Apple의 Personal Team은 개인 소유 기기에서 개발·테스트하기 위한 경로이며 App Store나 기업 배포용이 아니다.[Apple QA1915](https://developer.apple.com/library/archive/qa/qa1915/_index.html) Personal Team 앱은 프로비저닝 프로파일 만료 후 다시 빌드·설치해야 하므로 SideRefresh의 자동화 대상은 실제로 존재한다.

다만 오픈소스화가 Apple 플랫폼 제한을 없애지는 않는다.

- Xcode는 Apple 브랜드 macOS에서 개발·테스트 목적으로 사용해야 하며 Apple 소프트웨어 자체를 재배포하거나 네트워크 다중 사용자 서비스로 제공해서는 안 된다.[Xcode 및 Apple SDK 계약](https://www.apple.com/legal/sla/docs/xcode.pdf)
- Apple 계정과 비밀번호는 공유하면 안 되며 계정 소유자가 보안을 책임진다.[Apple Developer Agreement](https://developer.apple.com/support/downloads/terms/apple-developer-agreement/Apple-Developer-Agreement-20250318-English.pdf)
- iOS 실행 코드는 Apple이 발급한 인증서로 서명되어야 한다.[Apple Platform Security](https://support.apple.com/guide/security/sec7c917bf14/web)
- Developer Mode는 Xcode로 설치한 개발 앱 실행에 필요하며 사용자가 기기에서 직접 승인한다.[Developer Mode 안내](https://developer.apple.com/documentation/Xcode/enabling-developer-mode-on-a-device)

SideRefresh의 현재 로컬·자기 소스·자기 기기 모델은 이 경계와 잘 맞는다. 공개 문서에는 반드시 “본인 또는 사용 권한이 있는 소스와 기기만 지원”, “Apple과 무관한 독립 프로젝트”, “Apple 계정 우회·IPA 카탈로그·클라우드 Xcode 서비스는 비목표”를 명시해야 한다.

Mac App Store는 App Sandbox가 필수이고, 앱이 독립 실행 앱을 설치하거나 컨테이너 밖을 자유롭게 읽고 쓰는 동작 및 기능을 바꾸는 코드 설치가 제한된다.[App Sandbox](https://developer.apple.com/documentation/security/app-sandbox) [App Review Guidelines 2.4.5·2.5.2](https://developer.apple.com/app-store/review/guidelines/#performance) Xcode 프로젝트를 빌드하고 iOS 기기에 앱을 설치하며 LaunchAgent를 등록하는 현재 구조는 심사 위험이 높다. 반면 Developer ID는 Mac App Store 밖 배포를 위한 공식 서명 방식이며, 공증에는 hardened runtime과 secure timestamp가 요구된다.[Developer ID](https://developer.apple.com/help/glossary/developer-id-certificate/) [macOS 공증](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

## 3. 경쟁·인접 오픈소스 비교

별표 수는 수요의 직접 증거가 아니라 오픈소스 생태계 활동성을 가늠하는 참고치다. 수치는 조사일 GitHub 공식 저장소 기준이다.

| 프로젝트 | 입력·실행 모델 | 계정/서명 모델 | 자동 갱신·인터페이스 | SideRefresh와의 차이 |
| --- | --- | --- | --- | --- |
| [AltStore](https://github.com/altstoreio/AltStore) | IPA, iOS 클라이언트 + Mac/Windows AltServer | Apple ID 입력, 개인 개발 인증서로 재서명 | 같은 Wi-Fi에서 주기적 백그라운드 갱신, AGPL-3.0, 14.1k★ | 7일 문제를 해결하지만 소스 재빌드가 아니며 Apple 인증 흐름을 다룸 |
| [SideStore](https://github.com/SideStore/SideStore) | 최초 컴퓨터 설정 후 iOS에서 IPA 갱신 | Apple 계정·Anisette·pairing file·VPN | 컴퓨터 없는 갱신, AGPL-3.0, 6.0k★ | 편의성은 높지만 자격 증명·페어링·VPN 복잡도가 크고 Xcode 소스를 빌드하지 않음 |
| [fastlane](https://github.com/fastlane/fastlane) | Xcode 프로젝트/워크스페이스 → 앱/IPA | 기존 Xcode 서명 또는 API 키·세션 | lane 기반 CLI 자동화, MIT, 41.9k★ | 강력한 빌드 기반이지만 Personal Team 만료 상태·LaunchAgent·사용자 UI·영수증은 없음 |
| [XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP) | Xcode 소스 빌드·실기기 설치·실행 | 기존 Xcode 서명, 서명 설정 자체는 하지 않음 | CLI + MCP, MIT, 6.2k★ | 매우 가까운 도구 기반이지만 7일 갱신 제품·스케줄러·macOS 사용자 UI는 없음 |
| [RebuildMe](https://github.com/AryanRogye/RebuildMe) | iOS 대시보드 → SSH Mac → xcodebuild → devicectl | Mac의 기존 서명, 키체인 비밀번호 환경 변수 사용 | 수동 원격 요청, MIT | 소스 재빌드 선례지만 만료 추적·예약·로컬 macOS UI/CLI/MCP가 없음 |
| [ReProvision Reborn](https://github.com/sohsatoh/ReProvision-Reborn) | 탈옥 iOS에서 설치 앱/IPA 재서명 | Apple 계정을 Keychain에 저장 | daemon 자동 재서명, AGPL-3.0 | 자동 갱신 선례지만 탈옥·IPA·계정 보관 모델 |
| [Feather](https://github.com/claration/Feather) | iOS에서 IPA 서명·설치 | p12와 mobileprovision 사용 | GPL-3.0, 4.4k★ | Apple 비밀번호는 요구하지 않지만 인증서 자료를 다루며 소스 빌드/예약 갱신이 아님 |
| [ios-deploy](https://github.com/ios-control/ios-deploy) | 이미 서명된 `.app` 설치·디버그 | 유효한 개발 인증서 필요 | CLI, GPL-3.0 | 빌드·서명·예약 기능이 없고 README도 주로 iOS 17 이전 용도라고 설명 |
| [pymobiledevice3](https://github.com/doronz88/pymobiledevice3) | 서명된 IPA/앱 설치와 기기 서비스 | 자체 서명·계정 처리 없음 | 크로스플랫폼 CLI, GPL-3.0, 2.6k★ | 전송·진단 기반 도구이지 갱신 제품이 아님 |
| [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller) | 서명 패키지/개발 `.app` 설치·업그레이드 | 자체 서명 없음 | 크로스플랫폼 CLI, GPL-2.0 | 빌드·서명·예약 없음 |
| [libimobiledevice/ideviceprovision](https://github.com/libimobiledevice/libimobiledevice) | 프로파일 조회·복사·설치·삭제 | 계정/빌드 없음 | CLI, LGPL-2.1 계열 | SideRefresh의 선택적 읽기 전용 검사 기반으로 유용하나 갱신 오케스트레이터는 아님 |
| [LiveContainer](https://github.com/LiveContainer/LiveContainer) | 호스트 iOS 앱 안에서 guest IPA 실행 | 설치 경로는 AltStore/SideStore/TrollStore 등에 의존 | AGPL-3.0, 10.3k★ | 호스트 자체의 설치·갱신 문제를 해결하지 않음 |
| [TrollStore](https://github.com/opa334/TrollStore) | CoreTrust 취약점으로 IPA 영구 설치 | 정상 Personal Team 서명 만료 모델을 우회 | 지원 OS가 iOS 14~16 일부와 17.0으로 제한, 21.8k★ | 취약점·구형 OS 경로로 SideRefresh의 정상 Xcode 서명 모델과 범위가 다름 |

### SideStore와 사용자 관점 비교

SideStore는 초기 설정 후 iPhone/iPad만으로 갱신할 수 있어 체감 편의성이 높다. 대신 Apple 계정 로그인, Anisette 서버, pairing file, LocalDevVPN/Wi-Fi가 필요하며 공식 FAQ도 오래된 공유 Anisette 서버가 Apple 계정 잠금 위험을 만들 수 있다고 경고한다.[SideStore FAQ](https://docs.sidestore.io/docs/faq) [SideStore 설치](https://docs.sidestore.io/docs/installation/install)

SideRefresh는 Mac과 Xcode가 계속 필요해 대상 사용자가 좁다. 대신 Apple 비밀번호를 수집하지 않고 사용자가 이미 신뢰한 Xcode 서명 환경과 자기 소스를 사용한다. 따라서 “컴퓨터 없는 사이드로딩” 편의성으로 SideStore와 경쟁하기보다 아래 사용자를 명확히 겨냥해야 한다.

- 본인이 개발하거나 소스를 보유한 앱을 무료 Personal Team으로 장기 실기기 테스트하는 사용자
- Apple 계정이나 인증서 파일을 별도 도구에 제공하고 싶지 않은 사용자
- 빌드·설치 결과와 만료일을 UI, CLI 또는 AI/MCP 자동화에서 동일하게 확인하려는 사용자

## 4. 2026-07-29 비공개 저장소 감사 스냅샷

### 강점

- MIT `LICENSE`, README, CONTRIBUTING, SECURITY, CI가 이미 존재한다.
- Swift Package에 외부 Swift 의존성이 없다.
- macOS 앱, agent, iOS 갱신 helper, CLI, MCP가 동일 저장소에 있다.
- Apple 공식 `SMAppService`를 사용한다. macOS 13 이상에서 bundled LaunchAgent/Login Item을 사용자 승인 아래 등록하는 공식 API다.[SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- Xcode 명령을 shell 없이 호출하고, exact Bundle ID 확인, dry-run 기본값, 사용자 Xcode 서명 재사용 등 보수적 경계가 있다.
- 최근 로컬 검증에서 Swift 테스트 153개, sample validation, headless validation이 통과했다.
- 로컬 패턴 검색에서는 자격 증명이나 private key를 찾지 못했다. 단, 전체 Git 이력과 GitHub Actions 로그에 대한 전문 secret scan을 대체하지는 않는다.

### 감사에서 확인한 공개 전 문제

- 비공개 전신 저장소의 GitHub community profile은 57%였고 CODE_OF_CONDUCT,
  issue template/form, PR template이 없었다.
- `v0.1.0` 릴리스에 바이너리 자산이 없으므로 일반 사용자는 소스에서 직접 빌드해야 한다.
- 비공개 개발 이력의 커밋 메타데이터에는 개인 작성자 메타데이터가 있었다.
- 비공개 개발 트리에는 공개할 필요가 없는 `.scratch` 조사 문서가 있었다.
- 당시 CI는 `swift test`와 sample validation만 실행하고 CONTRIBUTING이
  요구하는 headless validation을 실행하지 않았다.
- 큰 파일은 외부 기여자의 진입 비용을 높인다: `SideRefreshApp.swift` 4,150줄, `SideRefreshViewModel.swift` 2,490줄, `XcodeContainerScanner.swift` 1,355줄, `SideRefreshMCPToolHandler.swift` 966줄.
- 현재 빌드 스크립트는 host architecture로 빌드하고 기본적으로 ad hoc 서명한다. 공개 바이너리는 universal 또는 아키텍처별 표기와 Developer ID 서명·공증이 필요하다.
- 최종 reverse-DNS Bundle ID와 LaunchAgent ID의 소유권을 확정해야 한다.

기존 비공개 저장소의 visibility를 직접 바꾸면 코드뿐 아니라 활동과 Actions
로그가 공개되고 누구나 fork할 수 있다.[GitHub 저장소 공개 전환](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility)
따라서 SideRefresh는 검토한 트리를 새 단일 커밋으로 내보내고 비공개 개발
그래프는 별도 보관하는 방식을 선택했다. GitHub의 public secret scanning은
공개 후 방어선이며 자체 사전 검사를 대체하지 않는다.[GitHub secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)

## 5. 권장 공개 계획

### P0 — 공개 후보에서 완료

1. 비공개 branch, tag, Git history, Actions log를 공개 저장소로 복사하지 않는다.
2. 검토한 트리를 개인 작성자 메타데이터가 없는 새 루트 커밋으로 내보낸다.
3. `.scratch` 조사 자료는 공개 후보에서 제외한다.
4. 코드·브랜드 자산·생성 이미지·복사한 snippet의 출처와 라이선스를 감사한다. AGPL/GPL 경쟁 프로젝트 코드를 MIT core로 가져오지 않는다.
5. Apple 비제휴 고지, 본인 소스/기기 사용 범위, Personal Team 7일 제약, 비목표를 README와 SECURITY에 명시한다. Apple 상표는 제품명보다 덜 두드러진 호환성 설명에만 사용한다.[Apple 상표 지침](https://www.apple.com/legal/intellectual-property/guidelinesfor3rdparties.html)
6. CI에 headless, 샘플, Product Hunt 자산·사이트, 공개 소스 검사를 포함한다.
7. 서명 바이너리 전에 최종 Bundle ID와 LaunchAgent ID를 확정한다.

### P1 — 개발자 프리뷰

1. CODE_OF_CONDUCT, issue form, PR template, 지원 Xcode/iOS/macOS 표를 추가한다. Issue form에는 UDID, Team ID, 로컬 경로와 로그 redaction 안내를 넣는다.
2. GitHub Discussions, private vulnerability reporting, secret/code scanning과 push protection을 활성화한다.[Community profile](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories) [Private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository)
3. 저장소 설명, 홈페이지, topics를 채우고 source-only 개발자 프리뷰를 공개한다.
4. 최소 10명이 8일 이상 사용하게 해 최초 설정 완료율, 자동 갱신 시도율, 성공률, 실패 복구율을 측정한다.

### P1 — 일반 사용자용 바이너리 베타

1. 유지관리자가 Apple Developer Program에 가입해 Developer ID를 발급받는다. 연회비는 현재 미화 99달러다.[Apple Developer Program](https://developer.apple.com/programs/)
2. hardened runtime, timestamp, notarization, stapling, Gatekeeper 검증과 SHA-256 checksum을 자동화한다.
3. universal binary 또는 Intel/Apple Silicon 별도 자산을 제공하고 깨끗한 macOS 계정에서 설치를 검증한다.
4. 현재 및 직전 Xcode, USB/Wi-Fi 실기기 조합을 지원 표로 관리한다. Tailscale pure-cellular 경로는 재현 검증 전까지 공식 지원으로 약속하지 않는다.
5. 안정된 GitHub Release 자산이 생긴 뒤 자체 Homebrew tap의 Cask를 제공한다. Homebrew Cask는 Gatekeeper를 비활성화하지 않는 검증 가능한 upstream 바이너리를 요구한다.[Homebrew Acceptable Casks](https://docs.brew.sh/Acceptable-Casks)

### P2 — 기여자 확장

- 대형 UI·ViewModel·scanner·MCP handler를 명확한 기능 경계로 분리한다.
- CLI/MCP JSON schema와 버전 정책을 고정하고 dry-run fixture 테스트를 제공한다.
- good first issue와 재현 가능한 실기기 로그 수집 지침을 만든다.
- 다중 앱 지원은 단일 앱의 8일 이상 자동 갱신 성공률을 검증한 뒤 확장한다.

## 6. 핵심 위험과 완화책

| 위험 | 영향 | 완화 |
| --- | --- | --- |
| Xcode CLI, CoreDevice, 프로파일 형식 변경 또는 서비스 제한 | 높음 | Xcode 현재/직전 버전 매트릭스, parser fixture, fail-closed, 빠른 호환성 릴리스 |
| IPA·Anisette·계정 수집·클라우드 Xcode로 범위 확대 | 높음 | 명시적 non-goals, 로컬 자기 소스 모델 유지 |
| 로그에 UDID, Team ID, 경로, 소스 정보 노출 | 높음 | 기본 redaction, issue form 경고, private vulnerability report |
| 사용자 프로젝트 build phase가 임의 코드를 실행 | 높음 | 프로젝트 신뢰 확인, 대상/명령 표시, 자동 Git pull 금지 |
| Mac/Xcode/Developer Mode/기기 연결의 진입 장벽 | 중상 | 서명된 바이너리, 단계별 onboarding, 사전 점검과 명확한 상태 표시 |
| 기기·Xcode 조합 지원 부담 | 중상 | 검증 범위 공개, 미지원 경로 명시, 커뮤니티 재현 템플릿 |
| 직접 수요 불확실성 | 중간 | 경쟁 프로젝트 별표가 아닌 10명·8일 실제 갱신 지표로 판단 |
| 향후 GPL/AGPL/LGPL 구성요소 포함 | 중간 | dependency/SBOM/license CI, 링크·복사·번들 전 라이선스 검토 |

## 7. 최종 권고

**SideRefresh는 P0를 완료한 뒤 MIT 오픈소스로 공개할 가능성이 충분하다.** 오픈소스는 소스·서명·기기 접근이라는 민감한 경로를 사용자가 감사할 수 있게 해 신뢰 형성에 특히 유리하다. 다만 성공 기준은 저장소 공개 자체가 아니라 “비밀번호를 받지 않고, 사용자의 소스가 8일 이상 실제로 자동 갱신되는가”다.

권장 순서는 다음과 같다.

1. 이력·개인정보·라이선스·식별자 P0 감사
2. source-only 개발자 프리뷰
3. 10명 이상의 8일 실제 사용 검증
4. Developer ID 서명·공증 GitHub Release
5. 안정화 후 Homebrew Cask

SideRefresh macOS 앱의 배포 서명과 사용자가 갱신하는 iOS 앱의 서명은 문서에서 분리해야 한다. 전자는 유지관리자의 유료 Developer ID와 공증, 후자는 각 사용자의 무료 Personal Team과 자기 기기·소스다. 이 구분을 일관되게 유지하면 SideRefresh는 SideStore의 대체재라기보다, 현재 오픈소스 생태계에서 비어 있는 **안전한 자기 소스 갱신 계층**으로 자리 잡을 수 있다.
