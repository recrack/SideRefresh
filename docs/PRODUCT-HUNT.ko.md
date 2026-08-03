# SideRefresh Product Hunt 출시 자료

[English](PRODUCT-HUNT.md) | [한국어](PRODUCT-HUNT.ko.md)

업데이트: 2026-08-02

이 문서는 Product Hunt에 사용할 공식 한국어 기준 문구와 준비 체크리스트입니다.
등록과 홍보 운영 계획은 [Product Hunt 실행 문서](product-hunt/README.md)를
기준으로 합니다. 어느 문서도 실제로 제출했다는 뜻은 아닙니다.

## 현재 판단: 아직 예약하지 않음

업데이트 시점의 상태는 다음과 같습니다.

- 개인정보를 제거한 단일 커밋 스냅샷으로 소스 공개를 준비했습니다.
- GitHub Pages에는 아직 공개 다운로드를 연결하지 않습니다.
- Developer ID 서명과 Apple 공증을 마친 안정 Mac 다운로드가 없습니다.
- Product Hunt 예약은 해당 안정 릴리스와 실제 빌드 미디어가 준비된 뒤
  진행합니다.

앱과 문서의 영어·한국어 지원은 Product Hunt 방문자를 받을 기반이지만, 아래
Go/No-Go 항목을 모두 만족한 뒤에만 출시를 예약합니다.

## 제출 문구

제품명:

> SideRefresh

Tagline:

> Keep agent-built iOS apps alive on your iPhone

짧은 설명:

> SideRefresh is an open-source Mac app that rebuilds, signs, and reinstalls agent-built iOS apps before free Personal Team signing expires. Personal use needs no paid Apple Developer Program membership; Mac, Xcode, and an Apple Account are required.

제출 화면에 실제로 존재하는 항목 중 선택할 주제 후보:

- Open Source
- Developer Tools
- Artificial Intelligence

가격:

> Free

기본 URL:

> https://github.com/recrack/SideRefresh

## Maker 첫 댓글

Product Hunt는 AI가 생성한 댓글을 금지합니다. SideRefresh의 보수적인 운영
원칙으로 Maker가 제품을 만든 계기, 정확한 흐름, 신뢰 경계, 요구사항, 첫 릴리스
범위와 구체적인 피드백 질문을 자기 말로 직접 작성합니다. 생성된 문장을 붙여
넣거나 자동 게시·답글을 사용하지 않습니다. 최신 작성 체크리스트는
[제출 자료](product-hunt/submission.md#maker-first-comment-outline)를 기준으로 합니다.

실제 Product Hunt 게시물과 Gallery에는 영어를 사용합니다. 이 한국어 문구는
제품 설명, 국내 커뮤니티와 지원 답변의 기준입니다.

## 자주 받을 질문

누구를 위한 제품인가요?

> Claude Code, Codex, Cursor 또는 Xcode로 App Store 배포 목적이 아닌 개인용
> iOS 앱을 만드는 사용자입니다.

무엇을 자동화하나요?

> 로컬 Xcode 재빌드, Personal Team 서명, Bundle ID 검증, CoreDevice 설치와
> 만료 증거 기록입니다.

Apple의 만료 제한을 없애나요?

> 아닙니다. 만료 전에 Apple의 정상 개발 빌드와 설치 경로를 다시 실행합니다.

유료 개발자 가입이 필요한가요?

> 사용자의 개인 iOS 앱에는 필요하지 않지만 Apple Account Personal Team은
> 필요합니다. 별도로 공개 SideRefresh Mac 바이너리는 배포자가 Developer ID
> 서명과 Apple 공증을 해야 합니다.

Tailscale이면 완전 원격 설치가 되나요?

> Tailscale은 실험적입니다. Peer 식별자와 원격 주소를 확인하지만 Xcode
> 페어링을 대신하거나 CoreDevice 도달을 증명하지 않습니다. 순수 셀룰러
> 설치는 아직 공개 지원 항목이 아닙니다.

## Gallery 순서

Product Hunt에는 영어 UI의 1270×760 이미지를 사용합니다.

1. Hero — “Your agent builds it. SideRefresh keeps it running.”
2. 문제 — Personal Team 서명이 만료되면 재빌드·재설치가 필요함
3. Simple 홈 — 한 가지 상태, 한 가지 다음 행동, 앱 → iPhone, 마지막 검증
4. 같은 창 설정 — 앱·iPhone 선택과 아래 고정 확정 영역
5. 연결 — 항상 보이는 Xcode/CoreDevice와 실험적으로 구분된 Tailscale
6. 오픈소스 — 로컬 소스, MIT, GitHub와 개인정보 경계

45–75초 데모에는 에이전트 프로젝트, 선택, 첫 검증 설치와 준비 완료 상태를
담습니다. 검증하지 않은 원격 설치를 연출하지 않습니다.

## 첫 릴리스 범위

포함:

- 사용자가 소유한 앱 한 개
- Xcode 프로젝트 또는 워크스페이스 한 개
- 페어링된 실제 iPhone 한 대
- Xcode와 Apple Account Personal Team이 있는 Mac
- 영어·한국어 Simple 홈·최초 설정·선택 화면, 앱 내 언어 선택과 사용자 문서

제외:

- 타인의 IPA 설치
- 여러 앱·여러 iPhone 동시 관리
- Xcode가 없는 사용자
- 팀·조직 단위 장비 관리
- 서명이 영구적이 된다는 주장

## Go/No-Go 체크리스트

- [ ] Git 전체 이력, Actions 로그, 문서와 자산에서 비밀정보, 개인 경로,
  Apple Account 정보, 서명 자료, UDID와 Tailnet ID 감사
- [ ] GitHub 저장소 공개 후 모든 링크 재확인
- [ ] 저장소 설명, 홈페이지, topics와 소셜 미리보기 추가
- [ ] Developer ID 서명·Apple 공증을 마친 안정 Mac 다운로드 공개
- [ ] 체크섬 공개와 깨끗한 계정의 Gatekeeper 검증
- [ ] 에이전트 앱 1개 × iPhone 1대에서 첫 설치와 두 번째 실제 갱신 완료
- [ ] 배포 번들의 영어·한국어 Simple 설정 흐름 확인
- [ ] README, 설명서, 개인정보 경계, 지원·제거 문서와 실제 릴리스 일치
- [ ] Thumbnail, Gallery, 공개 데모, Maker 프로필과 출시 당일 대응 준비
- [ ] 예약 직전 실제 Product Hunt 제출 화면에서 제한과 필드명 재확인

Upvote를 요청하거나 upvote의 대가로 보상을 제공하지 않습니다. 봇, 구매 트래픽,
대량 비동의 메시지도 사용하지 않습니다. 실제 사용과 솔직한 피드백을 요청합니다.

현재 Product Hunt 정책 조사와 출처는
[공식 출처 조사](product-hunt/research.md)에 유지합니다.
