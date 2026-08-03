# 지원 답변 모음 — 한국어

Product Hunt 댓글에는 이 문구를 복사하지 말고 Maker가 직접 답변합니다.

## 누가 사용하나요?

Claude Code, Codex, Cursor 또는 Xcode로 자신이 소유한 개인용 iOS 앱을 만들고,
App Store 배포 없이 페어링된 iPhone 1대에서 사용하는 사람을 위한 도구입니다.

## Apple의 만료를 없애나요?

아닙니다. 현재 Personal Team 서명이 만료되기 전에 Apple의 일반 개발
빌드·서명·검증·설치 과정을 다시 실행합니다.

## 유료 개발자 멤버십이 필요한가요?

개인 기기 사용에는 필요하지 않습니다. Apple Account Personal Team, Xcode,
Apple이 요구하는 기기 설정은 여전히 필요합니다. SideRefresh Mac 앱의 공개
배포에는 별도로 Developer ID 서명과 Apple 공증이 필요합니다.

## 자동 갱신 전에 무엇을 해야 하나요?

Xcode에 Apple Account로 로그인하고 프로젝트에 Personal Team을 선택한 다음,
iPhone을 페어링·신뢰하고 Developer Mode를 켜 Xcode에서 한 번 설치해야 합니다.
그 뒤 SideRefresh에서 앱과 iPhone을 선택·저장하고 한 번 갱신을 검증한 후 자동
갱신을 명시적으로 켭니다.

## Apple Account 비밀번호를 받나요?

아닙니다. 로그인, 약관, 인증서, 페어링, 신뢰와 Developer Mode는 Xcode와
시스템 설정에 남습니다. 비밀번호, 개인 키, 전체 서명 로그를 지원 채널로
보내지 마세요.

## 소스 코드를 업로드하나요?

아닙니다. 선택한 로컬 소스를 Mac에서 Xcode로 다시 빌드합니다. Git 변경을
가져오거나 클라우드 서명 서비스를 사용하지 않습니다.

## 타인의 IPA나 여러 앱을 설치할 수 있나요?

아닙니다. 첫 릴리스는 사용자가 소유한 Xcode 프로젝트 또는 workspace의 앱
1개와 페어링된 iPhone 1대를 지원합니다. IPA 스토어나 장비 관리 도구가
아닙니다.

## Tailscale 옵션은 무엇을 지원하나요?

선택적·실험적 기능입니다. Tailnet peer와 네트워크 경로를 확인할 수 있지만
Xcode 페어링을 대신하거나 셀룰러 CoreDevice 설치를 보장하지 않습니다. 최초
설치는 USB로 검증하세요.

## “No Accounts” 또는 “No profiles”가 나오면요?

Xcode 설정의 Accounts에서 Apple Account를 추가하고, 프로젝트 앱 target에
Personal Team을 선택한 뒤 iPhone을 연결해 Xcode에서 한 번 실행하세요.
SideRefresh는 Apple 서명 자산을 생성하거나 복구하지 않습니다.

## 버그 제보에는 무엇을 넣나요?

SideRefresh·macOS·Xcode 버전, 프로젝트 유형, 화면의 정확한 메시지, 실패 단계,
민감정보를 제거한 진단을 적어주세요. 이메일, 경로, Team ID, UDID, serial,
IP·Tailnet 정보, 인증서, 프로필과 token은 공개하지 마세요.
