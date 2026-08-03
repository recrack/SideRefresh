# Personal Team 준비와 Team ID 찾기

[English](PERSONAL-TEAM-SETUP.md) | [한국어](PERSONAL-TEAM-SETUP.ko.md)

SideRefresh가 무료 Apple Personal Team으로 iOS 앱을 다시 빌드·서명하려면
Xcode가 사용하는 10자리 Team ID가 필요합니다. Apple Developer Program
유료 등록은 필요하지 않습니다.

## Personal Team이 아직 없는 경우

Personal Team은 개발자 웹사이트에서 별도로 만드는 항목이 아닙니다. 유료
멤버십이 없는 Apple Account를 Xcode에 추가하면 Xcode가
`이름 (Personal Team)`으로 표시합니다.

1. Xcode를 열고 **Xcode → Settings → Accounts**로 이동합니다.
2. `+` 버튼을 눌러 Apple Account를 추가합니다.
3. 로그인, 2단계 인증, 약관 동의가 나타나면 Xcode에서 직접 완료합니다.
4. iOS 프로젝트 또는 워크스페이스를 엽니다.
5. 프로젝트 편집기에서 실제 iOS 앱 **Target**을 선택합니다.
6. **Signing & Capabilities**에서 **Automatically manage signing**을
   켭니다.
7. **Team**에서 `이름 (Personal Team)`을 선택합니다.

SideRefresh는 Apple Account 비밀번호나 2단계 인증 코드를 받지 않으며 이
과정을 자동으로 조작하지 않습니다.

## 최초 서명 자산 만들기

Team을 선택했더라도 이 Mac에 프로비저닝 프로파일이 아직 없을 수 있습니다.
다음 과정을 Xcode에서 한 번 수행합니다.

1. 고유한 Bundle Identifier를 사용합니다.
2. 앱 확장, 위젯 등이 있으면 관련 Target에도 같은 Team을 지정합니다.
3. iPhone을 Mac에 연결하고 잠금을 해제합니다.
4. iPhone의 **이 컴퓨터를 신뢰**와 **Developer Mode** 요청을 승인합니다.
5. Xcode에서 실행 대상을 해당 iPhone으로 선택합니다.
6. **Product → Run**을 한 번 실행합니다.

자동 서명이 켜져 있으면 Xcode가 필요한 개발 인증서, 기기 등록, App ID와
프로비저닝 프로파일을 관리합니다.

## SideRefresh에서 Team ID 자동으로 찾기

SideRefresh **설정**에서 앱을 선택한 뒤 **Apple 서명 → Personal Team 찾기**를
누릅니다.
SideRefresh는 다음 근거를 우선순위대로 확인합니다.

1. 선택한 Xcode 앱 Target의 `DEVELOPMENT_TEAM`
2. 아직 유효한 로컬 Personal Team 프로비저닝 프로파일
3. 만료된 로컬 Personal Team 프로파일의 Team ID 기록
4. Keychain의 Apple Development 서명 인증서에 포함된 Team ID 후보

Apple 발급 개발 인증서의 Subject Organizational Unit(OU)에는 Team ID가
들어갑니다. 그러나 인증서만으로는 Xcode가 그 팀을 Personal Team으로
표시하는지 확정할 수 없습니다. 따라서 인증서에서만 찾은 값은
**Personal Team 여부 확인 필요**로 표시하고, 후보가 하나뿐이어도 자동으로
적용하지 않습니다. Xcode에서 확인한 사용자가 직접 적용해야 합니다.

여러 Team ID가 발견되면 SideRefresh가 첫 항목을 임의로 선택하지 않습니다.
Xcode의 Signing & Capabilities에 선택된 Team과 같은 10자리 ID를 사용자가
고릅니다.

버튼을 누를 때 SideRefresh는 로컬 프로젝트, 프로비저닝 프로파일과
Apple Development 인증서를 읽기만 합니다. Apple Account, Keychain,
인증서와 Xcode 설정은 변경하지 않습니다.

## 상태별 의미

### 사용 가능한 Personal Team 프로파일

유효한 로컬 Personal Team 프로파일에서 Team ID를 확인한 상태입니다.
설치할 앱, Bundle ID와 iPhone을 계속 확인하면 됩니다.

### 만료된 Personal Team 기록

Team ID는 확인했지만 기존 7일 프로파일이 만료됐습니다. Xcode에서
Automatically manage signing과 Personal Team을 확인하고 실제 iPhone으로
한 번 Run한 뒤 다시 찾습니다.

### Apple Development 인증서 후보

10자리 Team ID는 확인했지만 Personal Team인지 유료 개발 팀인지 인증서
하나만으로 확정할 수 없습니다. Xcode에서 같은 Team ID를 확인해야 합니다.

### Personal Team을 찾지 못함

다음 경우를 SideRefresh가 공개된 로컬 정보만으로 완전히 구분할 수 없습니다.

- Xcode에 Apple Account를 아직 추가하지 않음
- Personal Team을 앱 Target에 아직 지정하지 않음
- 첫 실제 iPhone Run 전이라 서명 자산이 없음
- 로컬 프로파일과 Apple Development 인증서가 없음

이 문서의 첫 두 절을 완료한 뒤 **Personal Team 찾기**를 다시 누릅니다.

## 무료 Personal Team의 제한

- 프로비저닝 프로파일은 발급 후 7일 동안 유효합니다.
- 만료 후 앱을 계속 사용하려면 다시 빌드·서명·설치해야 합니다.
- 앱 ID, 기기와 기기별 설치 앱 수에 무료 계정 제한이 있습니다.
- App Store 제출과 일반 배포에는 Apple Developer Program 멤버십이
  필요합니다.

SideRefresh는 이 제한을 우회하지 않고, Xcode가 제공하는 정상적인 개발 서명
경로를 예약 실행합니다.

## 공식 참고 문서

- [Apple Developer 계정과 Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Xcode에서 프로젝트에 Team 지정](https://help.apple.com/xcode/mac/current/en.lproj/dev23aab79b4.html)
- [실제 기기에서 앱 실행과 프로비저닝](https://developer.apple.com/documentation/Xcode/running-your-app-on-simulated-or-physical-devices)
- [앱에 Capability 추가와 자동 서명 준비](https://developer.apple.com/documentation/xcode/adding-capabilities-to-your-app)
- [프로비저닝 프로파일 구조와 Team 식별자](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)
- [Apple 코드 서명 인증서](https://developer.apple.com/documentation/technotes/tn3161-inside-code-signing-certificates)

외부 튜토리얼에서 Keychain Access의 Apple Development 인증서
**Organizational Unit**을 직접 확인하는 방법도 소개하지만, SideRefresh는
이 단계를 버튼의 읽기 전용 탐지로 대신합니다. 기술적 판단과 절차는 위
Apple 공식 문서를 기준으로 합니다.
