# SideRefresh iPhone 정보 수집 표

SideRefresh는 같은 화면에 서로 다른 출처의 값을 섞어 “정확한 값”처럼
표시하지 않습니다. 각 정보는 다음 세 출처 중 하나로 구분합니다.

- **iPhone 직접 조회**: 버튼을 누른 시점에 Xcode/CoreDevice 또는
  `ideviceprovision`이 실제 기기에서 읽은 값
- **설치 영수증**: SideRefresh가 빌드한 앱을 같은 iPhone에 설치하는 데
  성공했을 때 그 앱 번들에서 기록한 값
- **Mac 설정**: 사용자가 고른 프로젝트와 자동 갱신 설정

## 현재 수집하는 정보

| 영역 | 필드 | 출처 | 정확도와 용도 |
|---|---|---|---|
| iPhone | 이름, 모델, iOS 버전, 페어링 상태, UDID | Xcode 기기 목록 | 설치 대상을 식별 |
| 연결 | 자동/Tailscale/직접 주소, 현재 주소 | Mac 설정·명시적 Tailscale 조회 | 기기에 도달하는 경로이며 UDID와 별개 |
| 개발자 앱 | 앱 이름, Bundle ID, 버전, 빌드 번호 | iPhone 직접 조회 | 현재 설치 여부와 갱신 대상 대조 |
| 개발자 앱 | Developer App, App Clip, 삭제 가능, 내부 번들 경로 | iPhone 직접 조회 | 고급 진단 |
| Apple Development | 인증서 Common Name | iPhone 프로파일 직접 조회 | iOS 설정의 개발자 서명 주체와 대조 |
| Team | Team 이름, Team ID | iPhone 프로파일 직접 조회 | 실제 설치 프로파일의 개발 팀 |
| 프로파일 | 이름, UUID, App ID 이름·값 | iPhone 보유 프로파일 직접 조회 | Bundle ID 후보를 찾고 SideRefresh 설치 영수증 UUID와 대조 |
| 프로파일 | 발급일, 만료일, 남은 기간, TTL | iPhone 프로파일 직접 조회 | 실제 서명 유효 기간 |
| 프로파일 | 플랫폼, Local Provision 여부 | iPhone 프로파일 직접 조회 | 프로파일 종류 진단 |
| 프로파일 | 등록 기기 수, 현재 UDID 포함 여부 | iPhone 프로파일 직접 조회 | 현재 iPhone 허용 여부 |
| 프로파일 | Entitlement 키 목록 | iPhone 프로파일 직접 조회 | Capability 문제 진단 |
| 설치 영수증 | 마지막 설치 성공, 설치 앱 프로파일 만료일 | SideRefresh 설치 성공 | 직접 프로파일 조회가 없어도 SideRefresh가 설치한 번들의 만료를 증명 |
| 일정 | 갱신 주기, 다음 갱신 | Mac 설정·설치 영수증 | 설정 주기와 만료 24시간 전 중 빠른 시각 |
| 빌드 대상 | Project/Workspace, 전체 경로, Scheme, Configuration | Mac 설정 | 무엇을 빌드할지 결정 |
| 앱 대상 | Product, 예상 Bundle ID, Team ID | Mac 설정 | 빌드 결과와 서명 검증 |
| 설치 대상 | 정확한 UDID | Mac 설정·Xcode 조회 | 어느 iPhone에 설치할지 결정 |

`devicectl`은 앱 목록과 `builtByDeveloper` 여부를 제공하지만 설치 앱의
프로비저닝 만료일이나 Apple Development 인증서 이름은 제공하지 않습니다.
그 값은 오픈소스 libimobiledevice의 `ideviceprovision`이 실제 iPhone에서
복사한 프로파일을 읽을 때만 **iPhone 직접 조회**로 표시합니다. 도구가 없거나
같은 Bundle ID 프로파일이 여러 개여서 매칭이 모호하면 확정값을 만들지
않습니다. 조회 버튼을 누르면 먼저 페어링된 USB/local 서비스로 읽고, 실패하면
같은 읽기 명령을 `--network` 모드로 한 번 재시도합니다. 설치·삭제·프로파일
변경 명령은 실행하지 않습니다.

설치 영수증 UUID와 같은 프로파일이 iPhone에 남아 있어도 현재 앱이 그
프로파일을 내장했다고 직접 증명하지는 않습니다. SideRefresh 설치 이후 외부에서
앱을 교체할 수 있기 때문에 UI도 이를 “영수증 UUID와 같은 프로파일 있음”으로
표시합니다.

## 수집 가능하지만 아직 제품화하지 않은 정보

| 필드 | 상태 | 이유 또는 다음 단계 |
|---|---|---|
| 앱 아이콘 | 미구현 | `devicectl` 앱 목록에 아이콘이 없어 프로젝트 Asset Catalog 또는 별도 기기 서비스를 읽어야 함 |
| 설치 시각 | 공개 CoreDevice 출력에 없음 | SideRefresh 설치 시각은 영수증으로 알 수 있지만 외부에서 설치한 앱의 시각은 확정할 수 없음 |
| 인증서 자체 만료일 | 미구현 | 프로파일 만료와 별개로 X.509 인증서 Validity를 상세 파싱해야 함 |
| 프로파일 entitlement 값 | 키만 표시 | 토큰·그룹 등 민감하거나 긴 값이 있어 안전한 allowlist 설계 필요 |
| 앱 실행 가능 여부 | 간접 확인 | 설치 존재와 프로파일 유효성은 알 수 있지만 iOS의 최종 launch policy 결과는 실제 실행 확인이 필요 |
| VPN 및 기기 관리 화면의 표시 순서 | 직접 제공 안 됨 | 인증서 Common Name과 프로파일을 대조하되 설정 앱 UI 순서를 추측하지 않음 |
| 외부에서 같은 버전으로 재설치했는지 | 완전 판별 불가 | SideRefresh 영수증 이후 동일 버전·빌드로 외부 재설치하면 CoreDevice 앱 목록만으로 구분 불가 |

## 쉬운 모드에서 사용할 핵심 값

상세 정보가 확보되면 쉬운 모드는 다음 다섯 문장으로 축약할 수 있습니다.

1. **어떤 앱인가** — 앱 이름과 아이콘, Bundle ID
2. **어느 iPhone인가** — 기기 이름과 모델
3. **지금 설치돼 있는가** — 실제 앱 버전과 마지막 확인 시각
4. **언제 만료되는가** — 직접 프로파일 만료 또는 SideRefresh 설치 영수증
5. **언제 다시 설치할 것인가** — 다음 갱신 시각과 자동화 상태

각 문장에서 상세 정보로 들어가면 원본 출처, 정확 식별자와 진단 값을 모두
확인할 수 있어야 합니다.
