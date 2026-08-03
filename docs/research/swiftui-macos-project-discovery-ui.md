# SideRefresh macOS 프로젝트 탐색 UI 리서치

- 조사일: 2026-07-25
- 범위: macOS SwiftUI 설정 화면의 Xcode `.xcodeproj`/`.xcworkspace` 자동 탐색, 수동 추가, 검색·목록·진행 피드백·접근성
- 출처 정책: Apple 공식 Human Interface Guidelines와 Apple Developer Documentation만 사용

## 결론

SideRefresh에는 프로젝트 경로를 직접 입력하게 하는 대신, **자동 발견 목록과 시스템 파일 선택기를 함께 제공**하는 방식이 적합하다.

권장 흐름은 다음과 같다.

1. `갱신 대상 앱` 카드에서 현재 선택된 프로젝트를 한 줄로 보여준다.
2. `변경…`을 누르면 별도 프로젝트 선택 화면을 연다.
3. 화면이 열리면 사용자 홈 범위의 프로젝트 후보를 비동기로 찾고, 찾은 항목부터 목록에 표시한다.
4. 목록 상단 검색 필드에서 프로젝트 이름과 상대 경로를 즉시 필터링한다.
5. 자동 탐색으로 못 찾은 경우를 위해 `폴더에서 찾기…`와 `프로젝트 직접 선택…`을 항상 노출한다.
6. SideRefresh는 후보를 보여줄 뿐, 비슷한 이름의 다른 프로젝트를 자동 확정하지 않는다. 사용자가 한 항목을 선택하고 `사용`해야 갱신 대상이 바뀐다.

Apple은 파일 검색에 시스템 제공 열기/저장 화면을 우선 사용하고, 앱 안에서 고급 파일 검색이 필요하면 Spotlight를 활용하라고 안내한다. 시스템 패널에는 시스템 전체를 검색하는 기능도 기본 제공된다. 따라서 자동 탐색과 `NSOpenPanel`은 경쟁 기능이 아니라 서로의 누락을 보완하는 두 경로다. [Apple HIG — Searching](https://developer.apple.com/design/human-interface-guidelines/searching)

## 제안 UI

### 1. 설정 본문

현재 `갱신 대상 앱` 카드에는 아래 정보만 남긴다.

```text
갱신 대상 앱

[앱 아이콘] MyApp
           ~/Projects/MyApp/MyApp.xcworkspace
                                      [변경…]
```

경로처럼 사용자가 복사할 가능성이 있는 정보는 선택 가능하게 제공한다. Apple은 위치, IP 주소, 오류 메시지처럼 유용한 라벨 텍스트를 선택·복사할 수 있게 하는 방식을 권장한다. [Apple HIG — Labels](https://developer.apple.com/design/human-interface-guidelines/labels)

`변경…`처럼 추가 입력이나 다른 화면을 여는 macOS 버튼에는 말줄임표를 붙인다. Apple은 다른 창·뷰·앱을 여는 push button 제목에 후행 말줄임표를 사용하라고 안내한다. [Apple HIG — Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)

### 2. 프로젝트 선택 화면

권장 구조:

```text
프로젝트 선택
자동으로 찾은 프로젝트와 워크스페이스입니다.

[ 프로젝트 이름 또는 경로                     🔍 ]

┌──────────────────────────────────────────────────┐
│ ◉ MyApp              Workspace · 권장           │
│   Projects/MyApp/MyApp.xcworkspace              │
│   프로젝트 파일 수정 · 2026. 8. 2.              │
├──────────────────────────────────────────────────┤
│   Sample             Project                    │
│   Development/Sample/Sample.xcodeproj           │
│   프로젝트 파일 수정 · 2026. 7. 31.             │
└──────────────────────────────────────────────────┘

[다시 찾기] [폴더에서 찾기…] [프로젝트 직접 선택…]  [취소] [사용]
```

구현 형태는 설정 창 위의 sheet 또는 설정 창 안의 명확한 하위 화면이 적합하다. 핵심은 프로젝트 탐색·선택·수동 추가가 한 문맥 안에 있어야 한다는 점이다. Apple은 특정 작업에만 영향을 주는 옵션을 별도 설정 깊숙이 숨기지 말고 해당 작업 화면에서 제공하라고 권장한다. [Apple HIG — Settings](https://developer.apple.com/design/human-interface-guidelines/settings)

목록은 `List(selection:)` 또는 macOS `Table`의 표준 선택 동작을 사용한다. 각 행은 다음을 포함한다.

- 기본 정보: 확장자를 제외한 프로젝트 이름
- 보조 정보: 홈 폴더 기준 상대 경로
- 종류: `Workspace` 또는 `Project`
- 보조 날짜: 앱 프로젝트의 `project.pbxproj` 수정일(확인할 수 있을 때만)
- 선택 상태: 시스템 행 highlight와, 필요하다면 checkmark

Apple은 행 기반 목록을 텍스트 스캔에 적합한 표현으로 보고, 선택했을 때 지속적인 행 highlight나 checkmark 같은 명확한 피드백을 제공하라고 한다. [Apple HIG — Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables) macOS의 focus는 텍스트 필드에는 focus ring, 목록에는 행 전체 highlight를 사용하는 것이 플랫폼 관례다. [Apple HIG — Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/)

파일명이나 같은 폴더라는 이유만으로 `.xcworkspace`와 `.xcodeproj`를 합치지 않는다. Workspace가 표준화된 project 경로를 실제로 참조하고, 양쪽에서 확인한 앱 identity 집합이 같고 비어 있지 않으며, 대표 workspace가 하나로 확정될 때만 한 후보로 표시한다. 이때 workspace를 빌드 컨테이너로 사용하고 포함된 project 경로는 검색과 상세 확인을 위해 보존한다. 여러 앱을 포함하거나 여러 workspace가 같은 project를 참조해 모호하면 후보를 합치지 않는다.

날짜는 소스 코드의 최근 작업일이나 앱의 최근 사용일이 아니다. Project 후보는 `project.pbxproj`, 그룹화된 workspace 후보는 연결된 iOS 앱 project의 `project.pbxproj` 수정일을 `프로젝트 파일 수정`으로만 표시한다. 날짜를 확인할 수 없으면 생략하고 기본 정렬의 주 기준으로 사용하지 않는다.

### 3. 검색

검색 필드는 `searchable(text:prompt:)`로 목록에 연결하고 placeholder는 `프로젝트 이름 또는 경로`처럼 검색 범위를 구체적으로 설명한다. Apple은 단순히 `검색`이라고 쓰기보다 검색 가능한 정보의 종류를 알려주는 placeholder를 권장하며, 가능하면 입력과 동시에 결과를 갱신하라고 한다. [Apple HIG — Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields) SwiftUI의 `searchable`은 바인딩된 검색어가 바뀔 때 앱이 결과를 갱신하는 표준 모델을 제공한다. [Apple Developer Documentation — SwiftUI Search](https://developer.apple.com/documentation/swiftui/search)

프로젝트 수가 많지 않으므로 자동 탐색이 끝난 뒤의 이름·경로 필터링은 debounce 없이 메모리에서 즉시 수행해도 된다. 그룹에서 숨긴 project의 이름·경로가 검색어와 일치하면 대표 workspace 후보를 결과로 보여준다. 파일시스템 재스캔은 검색어 입력마다 수행하지 않는다.

기본 정렬은 다음처럼 예측 가능하게 유지한다.

1. 최근에 SideRefresh에서 선택한 경로
2. 표시 이름의 localized case-insensitive 순서
3. 이름이 같으면 홈 기준 상대 경로 순서

검색 결과가 없을 때는 빈 목록만 표시하지 말고 다음 행동을 함께 제시한다.

```text
일치하는 프로젝트가 없습니다.
검색어를 지우거나 다른 폴더에서 찾아보세요.
[폴더에서 찾기…] [프로젝트 직접 선택…]
```

Apple은 실행할 수 없는 상태를 알려주는 것에 그치지 말고 그 이유를 이해할 수 있게 하라고 권장한다. [Apple HIG — Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback)

## 자동 탐색 구현 권고

### 권장 구조: Spotlight 빠른 경로 + 제한된 파일 열거 fallback

홈 폴더 전체의 매번 반복되는 재귀 열거를 유일한 탐색 방식으로 두지 않는다. Apple은 앱 안의 파일 검색에 Spotlight를 활용할 수 있다고 안내하며, `NSMetadataQuery`는 Spotlight metadata를 검색하고 초기 수집과 live-update 두 단계를 제공한다. [Apple HIG — Searching](https://developer.apple.com/design/human-interface-guidelines/searching) [Apple Developer Documentation — NSMetadataQuery](https://developer.apple.com/documentation/foundation/nsmetadataquery)

자동 목록의 빠른 경로는 다음 API 조합이 적합하다.

- `NSMetadataQuery`
- `searchScopes = [NSMetadataQueryUserHomeScope]`
- `NSMetadataItemFSNameKey`로 `.xcodeproj`/`.xcworkspace` 이름 조건 구성
- `NSMetadataItemURLKey`에서 실제 URL 획득
- `.NSMetadataQueryDidUpdate`에서 발견 결과를 batch로 반영
- `.NSMetadataQueryDidFinishGathering`에서 `찾는 중` 상태 종료
- 화면이 닫히거나 재검색하면 `stopQuery()`

`NSMetadataQueryUserHomeScope`는 사용자 홈 디렉터리를 검색하는 공식 scope다. [Apple Developer Documentation — NSMetadataQueryUserHomeScope](https://developer.apple.com/documentation/foundation/nsmetadataqueryuserhomescope) `NSMetadataItemFSNameKey`는 파일시스템에서 보이는 항목 이름이고, `NSMetadataItemURLKey`는 파일을 열 수 있는 URL이다. [Apple Developer Documentation — NSMetadataItemFSNameKey](https://developer.apple.com/documentation/foundation/nsmetadataitemfsnamekey) [Apple Developer Documentation — NSMetadataItemURLKey](https://developer.apple.com/documentation/foundation/nsmetadataitemurlkey)

다만 Spotlight 색인이나 접근 권한 때문에 자동 결과가 모든 경로를 포괄한다고 가정해서는 안 된다. 이 판단은 API가 “Spotlight metadata query”임을 근거로 한 제품 설계상의 안전 장치다. 따라서 자동 목록에는 `자동으로 찾은 프로젝트`라고 쓰고, `모든 프로젝트`라고 표현하지 않는다. 수동 파일/폴더 선택을 항상 함께 둔다.

현재 구현처럼 `FileManager.DirectoryEnumerator`를 사용할 경우에는 다음 규칙을 적용한다.

- UI의 `MainActor`에서 직접 열거하지 않고 별도 task/actor에서 수행한다.
- `includingPropertiesForKeys`에 실제 판정에 필요한 `.isDirectoryKey`, `.isPackageKey`, `.nameKey`만 넣어 metadata를 미리 가져온다.
- `.skipsHiddenFiles`와 `.skipsPackageDescendants`를 사용한다.
- `.git`, `.build`, `.swiftpm`, `.dart_tool`, `.gradle`, `DerivedData`, `Library`, `node_modules`, `Pods`, `build`처럼 프로젝트 컨테이너 발견 가치보다 비용이 큰 디렉터리는 발견 즉시 `skipDescendants()` 한다.
- `.xcodeproj`/`.xcworkspace`를 찾으면 그 패키지 내부는 더 내려가지 않는다.
- 한 번에 모든 결과를 기다리지 말고, 예를 들어 20개 단위로 UI에 반영한다.
- 결과 수에 상한을 둔다. 현재 제품 정책으로 200개를 권장하며, 상한에 도달하면 `200개 이상 발견 · 검색하거나 폴더 범위를 좁히세요`라고 표시한다.
- 읽기 실패는 전체 탐색 실패로 만들지 말고 접근하지 못한 위치를 집계한다.

Apple의 `enumerator(at:includingPropertiesForKeys:options:errorHandler:)`는 deep enumeration을 제공하고, 지정한 resource key를 각 URL에 미리 가져와 cache한다. 또한 `DirectoryEnumerator.skipDescendants()`로 현재 경로 아래를 건너뛸 수 있고, error handler 반환값으로 계속 진행할지 중단할지 결정할 수 있다. [Apple Developer Documentation — FileManager directory enumerator](https://developer.apple.com/documentation/foundation/filemanager/enumerator%28at%3Aincludingpropertiesforkeys%3Aoptions%3Aerrorhandler%3A%29) `.skipsHiddenFiles`와 `.skipsPackageDescendants`는 Foundation이 제공하는 표준 열거 옵션이다. [Apple Developer Documentation — DirectoryEnumerationOptions](https://developer.apple.com/documentation/foundation/filemanager/directoryenumerationoptions)

Apple의 파일시스템 가이드는 디렉터리 열거가 많은 항목을 건드려 비용이 빠르게 커질 수 있으므로 sparingly 수행하고, 필요한 resource key를 미리 가져와 디스크 접근을 줄이라고 설명한다. [Apple File System Programming Guide — Accessing Files and Directories](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html)

### 취소와 재검색

ViewModel은 현재 탐색 작업을 강하게 보관한다.

```swift
private var discoveryTask: Task<Void, Never>?
```

다음 시점에는 이전 작업을 먼저 `cancel()`한다.

- 사용자가 `다시 찾기`를 누름
- 다른 폴더를 탐색 범위로 선택함
- 프로젝트 선택 화면이 닫힘
- 새 탐색 task를 시작함

열거 loop에서는 항목마다 또는 작은 batch마다 `Task.checkCancellation()`이나 `Task.isCancelled`를 확인한다. Swift task cancellation은 작업을 강제로 멈추는 것이 아니라 취소 상태를 전달하는 협력적 메커니즘이므로, 실제 파일 열거 코드가 적절한 지점에서 확인해야 한다. [Apple Developer Documentation — Task cancellation](https://developer.apple.com/documentation/swift/task/)

취소는 오류 alert로 표시하지 않는다. 사용자가 취소한 경우 기존에 표시된 결과를 유지하거나 조용히 초기 상태로 돌아간다.

### cache 정책

- 설정 화면이 다시 그려질 때마다 스캔하지 않는다.
- 앱 프로세스 안에서는 마지막 결과를 재사용하고, 사용자가 `다시 찾기`를 선택할 때 갱신한다.
- 디스크에 후보를 cache한다면 경로와 마지막 확인 시각만 저장하고, 선택 직전 `fileExists`와 확장자를 다시 검증한다.
- cache가 비어 있어도 수동 선택은 즉시 사용할 수 있어야 한다.

## 수동 추가 구현 권고

### 두 개의 명확한 동작

하나의 애매한 파일 패널에서 “프로젝트 패키지”와 “검색 루트 폴더”를 동시에 고르게 하지 말고 목적을 분리한다.

#### `프로젝트 직접 선택…`

정확한 `.xcodeproj` 또는 `.xcworkspace` 하나를 고르는 경로다.

```swift
let panel = NSOpenPanel()
panel.title = "Xcode 프로젝트 선택"
panel.message = ".xcodeproj 또는 .xcworkspace를 선택하세요."
panel.prompt = "추가"
panel.canChooseFiles = true
panel.canChooseDirectories = false
panel.allowsMultipleSelection = false
panel.treatsFilePackagesAsDirectories = false
panel.allowedContentTypes = [xcodeProjectType, xcodeWorkspaceType]
```

`NSOpenPanel`은 파일 또는 디렉터리 선택 여부와 다중 선택 여부를 명시적으로 설정할 수 있고 선택 결과는 URL로 제공한다. [Apple Developer Documentation — NSOpenPanel](https://developer.apple.com/documentation/appkit/nsopenpanel) [Apple Developer Documentation — NSOpenPanel.urls](https://developer.apple.com/documentation/appkit/nsopenpanel/urls) `treatsFilePackagesAsDirectories = false`는 package를 내부 탐색용 디렉터리가 아니라 하나의 선택 항목으로 표시한다. [Apple Developer Documentation — treatsFilePackagesAsDirectories](https://developer.apple.com/documentation/appkit/nssavepanel/treatsfilepackagesasdirectories)

`.xcodeproj`와 `.xcworkspace`용 `UTType`은 filename extension으로 만들되 package에 conform하도록 생성한다. Uniform Type Identifiers는 filename extension으로 type을 찾거나 만들 수 있고, `UTType.package`는 사용자에게 일반 파일처럼 보이는 packaged directory의 기반 type이다. [Apple Developer Documentation — Uniform Type Identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers/) [Apple Developer Documentation — UTTypePackage](https://developer.apple.com/documentation/uniformtypeidentifiers/uttypepackage)

가능하면 `runModal()`보다 현재 설정 창의 `beginSheetModal(for:)` 또는 async variant를 사용해 어느 창에 속한 선택인지 명확하게 한다. Apple은 `beginSheetModal(for:)`를 지정한 window에 sheet-modal로 표시하는 API로 제공한다. [Apple Developer Documentation — beginSheetModal](https://developer.apple.com/documentation/appkit/nssavepanel/beginsheetmodal%28for%3Acompletionhandler%3A%29)

#### `폴더에서 찾기…`

프로젝트가 들어 있는 상위 폴더를 골라 그 하위에서 후보를 찾는 경로다. 이 동작이 사용자가 말한 “하위 폴더에 있는 프로젝트를 선택할 수 없음” 문제의 직접적인 해법이다.

```swift
let panel = NSOpenPanel()
panel.title = "프로젝트가 있는 폴더 선택"
panel.message = "선택한 폴더와 하위 폴더에서 Xcode 프로젝트를 찾습니다."
panel.prompt = "이 폴더에서 찾기"
panel.canChooseFiles = false
panel.canChooseDirectories = true
panel.allowsMultipleSelection = false
panel.treatsFilePackagesAsDirectories = false
panel.allowedContentTypes = [.folder]
```

`canChooseDirectories`는 사용자가 디렉터리를 선택할 수 있게 하는 공식 속성이다. [Apple Developer Documentation — canChooseDirectories](https://developer.apple.com/documentation/appkit/nsopenpanel/canchoosedirectories) `UTType.folder`는 사용자 탐색용 폴더를 나타내며, 더 넓은 `UTType.directory`는 package까지 포함하므로 이 목적에는 `.folder`가 더 명확하다. [Apple Developer Documentation — System-declared uniform type identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers/system-declared-uniform-type-identifiers)

폴더 안에서 후보가 하나만 발견되어도 즉시 저장하지 말고 목록에서 그 후보를 선택된 상태로 보여준 뒤 `사용`을 받는다. 여러 후보가 있으면 동일한 선택 목록으로 전환한다.

## 진행 상태와 오류

파일 개수를 미리 알 수 없는 홈 탐색은 indeterminate `ProgressView`가 맞다. Apple은 기간을 알 수 없는 작업에는 indeterminate indicator를 사용하고, indicator는 작업 중에만 나타났다가 완료하면 사라져야 한다고 설명한다. [Apple HIG — Progress indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators)

권장 상태 문구:

| 상태 | 화면 표현 |
|---|---|
| 시작 전 | `프로젝트를 찾으면 여기에 표시됩니다.` |
| 탐색 중 | spinner + `홈 폴더에서 Xcode 프로젝트 찾는 중…` + `취소` |
| 일부 결과 도착 | 목록 유지 + `12개 찾음 · 계속 찾는 중…` |
| 완료 | `12개 찾음 · 방금 확인` |
| 0개 | `자동으로 찾은 프로젝트가 없습니다.` + 수동 동작 |
| 일부 접근 거부 | `일부 폴더를 확인하지 못했습니다.` + `프로젝트 직접 선택…` |
| 상한 도달 | `200개 이상 발견 · 이름이나 경로로 검색하세요.` |

spinner를 넣기 어려운 좁은 위치에서는 버튼 내부 activity indicator도 사용할 수 있다. Apple은 버튼 안의 activity indicator가 공간을 절약하면서 지연 이유를 명확히 전달할 수 있다고 설명한다. [Apple HIG — Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)

파일 하나의 읽기 오류를 매번 alert로 띄우지 않는다. inline 상태로 요약하고, 사용자가 직접 선택한 경로까지 읽을 수 없거나 `사용`을 완료할 수 없을 때만 구체적인 오류를 제시한다. Apple은 일반 상태는 비방해적인 방식으로 문맥 가까이에 통합하고, 중요한 실패나 경고는 중요도에 맞게 전달하라고 권장한다. [Apple HIG — Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback)

## 개인정보 보호와 파일 접근

홈 폴더 전체를 볼 수 있다고 가정하면 안 된다. macOS는 Documents, Downloads, Desktop, iCloud Drive, network volume 등 보호 위치에 대한 사용자 동의를 적용한다. 접근이 거부된 폴더는 건너뛰고 수동 선택 경로를 안내해야 한다. [Apple Platform Security — Controlling app access to files in macOS](https://support.apple.com/guide/security/controlling-app-access-to-files-secddd1d86a6/web)

일반 프로젝트 탐색을 위해 Full Disk Access를 요구하지 않는다. Apple은 full disk access를 앱이 entitlement나 코드로 자동 획득할 수 없으며 사용자가 System Settings에서 직접 허용해야 하므로, 접근 실패를 방어적으로 처리하라고 한다. [Apple Developer Documentation — Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)

향후 SideRefresh를 App Sandbox로 배포한다면 수동으로 선택한 프로젝트 또는 상위 폴더의 security-scoped bookmark를 저장해야 한다. Apple은 표준 open panel로 선택한 URL에 sandbox access가 확장되고, 재실행 뒤에도 접근하려면 security-scoped bookmark를 만들고 resolve한 뒤 `startAccessingSecurityScopedResource()`/`stopAccessingSecurityScopedResource()`를 사용하라고 안내한다. [Apple Developer Documentation — Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)

백그라운드 Agent가 프로젝트를 읽어야 한다면 bookmark/access 권한이 Agent에도 유효한지 별도로 설계·검증해야 한다. Apple은 프로세스 간 전달에 URL bookmark를 사용할 수 있는 모델도 설명하지만, 단순 문자열 경로 저장만으로 sandbox 권한이 전달된다고 가정할 수는 없다. [Apple Developer Documentation — Share file access between processes with URL bookmarks](https://developer.apple.com/documentation/Security/accessing-files-from-the-macos-app-sandbox)

## 접근성 체크리스트

- 표준 `List`, `Button`, `TextField`, `ProgressView`를 우선 사용한다. SwiftUI는 표준 요소에서 기본 접근성 정보를 제공한다. [Apple Developer Documentation — Accessibility fundamentals](https://developer.apple.com/documentation/SwiftUI/Accessibility-fundamentals)
- 아이콘만 있는 버튼이 있다면 `accessibilityLabel`을 붙인다. 단, `다시 찾기`, `Finder에서 보기`처럼 짧은 텍스트가 더 명확하면 텍스트 버튼을 우선한다.
- 프로젝트 행은 `프로젝트 이름, Workspace, Projects/MyApp/...`가 하나의 이해 가능한 accessibility label/value로 읽히게 한다.
- 탐색 중에는 `프로젝트 탐색 중`, 완료 후에는 `12개 프로젝트 발견`을 텍스트와 accessibility value로 함께 전달한다.
- online/오류/선택 상태를 색만으로 구분하지 않고 아이콘 또는 텍스트를 함께 쓴다. Apple은 중요한 정보를 색 하나에만 의존하지 말라고 한다. [Apple HIG — Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/)
- system font와 semantic foreground style을 사용하고 Light, Dark, Increase Contrast에서 확인한다. Apple은 system color가 appearance와 접근성 설정에 맞게 자동 적응한다고 설명한다. [Apple HIG — Color](https://developer.apple.com/design/human-interface-guidelines/color)
- macOS control hit target은 가능하면 28×28pt 이상, 최소 20×20pt 이상을 확보하고 인접 control 간 간격을 둔다. [Apple HIG — Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/)
- Tab/Shift-Tab, 화살표, Return, Escape만으로 검색→목록 선택→취소/사용이 가능해야 한다. Apple은 Mac 사용자가 물리 키보드를 상시 사용하고 Full Keyboard Access와 표준 shortcut 동작을 기대한다고 설명한다. [Apple HIG — Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards/)
- context menu에 `Finder에서 보기`를 넣을 수 있지만 그 기능을 context menu에만 숨기지 않는다. Apple은 context menu의 동작을 main interface에서도 제공하라고 한다. [Apple HIG — Context menus](https://developer.apple.com/design/human-interface-guidelines/context-menus) Finder 표시는 `NSWorkspace.activateFileViewerSelecting(_:)`를 사용할 수 있다. [Apple Developer Documentation — activateFileViewerSelecting](https://developer.apple.com/documentation/appkit/nsworkspace/activatefileviewerselecting%28_%3A%29)

## SideRefresh 적용 우선순위

### P0 — 현재 불편 해결

1. `프로젝트 선택…` 단일 버튼을 `변경…`으로 바꾸고 프로젝트 선택 화면을 추가한다.
2. 자동 탐색 결과를 `List(selection:)`로 제공한다.
3. `프로젝트 직접 선택…`은 `.xcodeproj`/`.xcworkspace` package를 정확히 선택하게 한다.
4. `폴더에서 찾기…`는 일반 폴더를 고른 후 하위 폴더까지 비동기로 탐색한다.
5. 선택한 후보를 명시적으로 `사용`해야 `target.containerPath`를 바꾼다.

### P1 — 성능과 신뢰성

1. 자동 홈 탐색은 UI actor 밖에서 실행한다.
2. 진행 상태, 결과 batch 반영, cancel/rescan을 구현한다.
3. hidden/package descendant 및 대형 생성 디렉터리를 건너뛴다.
4. Spotlight `NSMetadataQueryUserHomeScope`를 빠른 자동 탐색 경로로 사용하고 수동 선택을 완전성 fallback으로 유지한다.
5. 설정 창 재렌더링·재포커스마다 반복 스캔하지 않고 session cache를 사용한다.

### P2 — 마감 품질

1. 이름/경로 즉시 검색
2. 동일 이름의 프로젝트를 상대 경로로 명확히 구분
3. Finder에서 보기
4. keyboard-only와 VoiceOver 검증
5. 접근 거부·0개·200개 상한·취소 상태의 inline copy 정리

## 검증 시나리오

1. 홈 폴더에 프로젝트가 0개, 1개, 여러 개일 때 상태가 각각 자연스러운가?
2. 같은 이름의 project가 서로 다른 경로에 있을 때 오선택하지 않는가?
3. 같은 앱의 참조 관계가 확인된 `.xcodeproj`와 `.xcworkspace`는 workspace 한 후보가 되고, 모호한 관계는 합쳐지지 않는가?
4. `node_modules`, `Pods`, `.git`, `DerivedData`가 큰 저장소에서도 설정 UI scroll·입력이 멈추지 않는가?
5. 탐색 중 `다시 찾기`, sheet 닫기, 앱 종료 시 이전 task가 취소되는가?
6. Documents/Desktop 접근을 거부해도 나머지 결과와 수동 선택 동작이 유지되는가?
7. 수동 파일 패널에서 여러 단계 하위 폴더로 이동해 package를 선택할 수 있는가?
8. 폴더 선택 후 그 하위의 project/workspace를 찾아 목록으로 되돌아오는가?
9. 200개 상한에 도달했음을 숨기지 않고 범위를 좁히는 방법을 안내하는가?
10. VoiceOver가 이름, 종류, 경로, 선택 상태, 탐색 진행 상태를 구분해 읽는가?
11. 키보드만으로 검색, 목록 이동, `사용`, `취소`가 가능한가?
12. Light, Dark, Increase Contrast에서 선택 highlight와 보조 경로가 읽히는가?
