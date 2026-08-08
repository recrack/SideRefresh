<p align="center">
  <img src="Assets/readme/hero.svg" width="100%" alt="SideRefresh는 서명이 만료되기 전에 에이전트가 만든 iOS 앱을 다시 빌드하고 설치합니다">
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="https://recrack.github.io/SideRefresh/ko/">홈페이지</a> ·
  <a href="docs/MANUAL.ko.md">사용 설명서</a> ·
  <a href="https://github.com/recrack/SideRefresh/releases">릴리스 상태</a>
</p>

SideRefresh는 무료 Xcode Personal Team으로 설치한 내 iOS 앱 하나를 서명이
만료되기 전에 다시 빌드·서명·설치하는 오픈소스 macOS 앱입니다. 내 Mac의
소스와 Apple 도구를 사용하며 IPA 카탈로그, 서명 서비스, 탈옥, Apple Account
암호 수집 기능이 아닙니다.

> 소스 빌드는 지금 사용할 수 있습니다. Developer ID 서명·공증된 공개 Mac
> 앱은 별도의 릴리스 검증을 통과해야 합니다.

현재 소스 프리릴리스:
[v0.2.0-beta.2](https://github.com/recrack/SideRefresh/releases/tag/v0.2.0-beta.2).

## 실제 화면

<img src="docs/product-hunt/assets/screenshots/en/healthy.png" width="100%" alt="앱 하나와 iPhone 한 대, 갱신 시점과 확인 결과를 보여주는 SideRefresh 샘플 화면">

<sub>샘플 미리보기 · 합성 데이터. 현재 앱 인터페이스는 영어와 한국어를 지원합니다.</sub>

Simple 화면은 내 앱 → 빌드·서명·설치 → 내 iPhone 관계를 한눈에 보여줍니다.
원본 Xcode와 CoreDevice 출력은 Diagnostics에서 확인합니다.

## 한 번 확인한 뒤 자동 갱신

1. **Xcode를 한 번 준비합니다.** Apple Account와 무료 Personal Team을
   설정하고 iPhone 페어링·개발자 모드를 마친 뒤 앱을 한 번 실행합니다.
2. **앱 하나와 iPhone 한 대를 고릅니다.** 앱 이름, Bundle ID, 버전, Scheme,
   Team과 CoreDevice 기기 정보를 확인하고 저장합니다.
3. **지금 갱신을 실행합니다.** Xcode 빌드, Bundle ID 확인, CoreDevice 설치,
   서명 만료 증거까지 확인된 경우에만 성공을 기록합니다.

첫 설치를 확인한 뒤 **자동 갱신**을 명시적으로 켭니다. 갱신 시점에는 Mac이
깨어 있고 iPhone에 연결할 수 있어야 합니다.

## 소스에서 시작

**필요 환경:** macOS 13 이상, Xcode 16.2 또는 호환 Swift 6 도구 체인, Apple
Account Personal Team, 페어링된 실제 iPhone 한 대.

```sh
swift test
Scripts/validate-samples.sh
Scripts/build-app.sh
open dist/SideRefresh.app
```

기본 빌드는 로컬 개발용 ad-hoc 서명이며 백그라운드 Agent나 로그인 항목을
자동 등록하지 않습니다.

## Mac에서 일어나는 일

```text
launchd → 짧게 실행되는 Agent → 갱신 엔진 → xcodebuild → devicectl → iPhone
                                   ↘ 선택적 Tailnet 사전 확인
```

- 현재 Xcode 소스를 다시 빌드하며 Git 변경을 가져오지 않습니다.
- 정확한 앱 결과를 찾은 뒤 Bundle ID를 확인합니다.
- 버전 유지·증가는 빌드 전략과 별도 설정입니다.
- 네이티브 화면, CLI, LaunchAgent, MCP가 같은 core를 사용합니다.

## 의도적으로 좁은 범위

설정 하나당 내가 소유한 앱 하나, Xcode 프로젝트나 워크스페이스 하나, 페어링된
iPhone 한 대를 지원합니다. 타인의 IPA 설치, Personal Team 서명 영구화,
여러 기기 관리, Xcode 없는 사용, 순수 셀룰러 CoreDevice 갱신을 지원한다고
주장하지 않습니다. Tailscale은 선택적 실험 기능이며 Apple 페어링·신뢰·서명을
대신하지 않습니다.

## 더 알아보기

- **설정:** [사용 설명서](docs/MANUAL.ko.md) · [Personal Team](docs/PERSONAL-TEAM-SETUP.ko.md)
- **동작:** [구현 상태](docs/STATUS.md) · [아키텍처](docs/side-refresh-architecture.html)
- **자동화:** [CLI, LaunchAgent, MCP](docs/HEADLESS.md) · [갱신 도구](docs/IOS-RENEWAL.md)
- **빌드:** [예제](Examples/README.md) · [배포](docs/DISTRIBUTION.md)
- **전략:** [오픈소스 비교](docs/research/open-source-viability-and-landscape.md) · [Product Hunt](docs/product-hunt/README.md)

## 기여와 라이선스

`Scripts/install-git-hooks.sh`로 저장소 hook을 설치한 뒤
[CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요. 민감한 문제는
[SECURITY.md](SECURITY.md)로 제보합니다. 코드와 문서는
[Apache License 2.0](LICENSE), 이름과 시각 자산은
[브랜드 정책](BRAND_POLICY.md)을 따릅니다. `v0.2.0-beta.1`까지는 MIT가 유지됩니다.
