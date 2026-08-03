import Foundation
import XCTest

final class LocalizationCatalogTests: XCTestCase {
    func testEnglishAndKoreanCatalogsCoverSimpleWorkspace() throws {
        let english = try strings(language: "en", table: "Localizable")
        let korean = try strings(language: "ko", table: "Localizable")

        XCTAssertEqual(Set(english.keys), Set(korean.keys))
        XCTAssertGreaterThanOrEqual(english.count, 100)
        for key in Self.requiredSimpleKeys {
            XCTAssertNotNil(english[key], "Missing English key: \(key)")
            XCTAssertNotNil(korean[key], "Missing Korean key: \(key)")
        }
        for (key, value) in english {
            XCTAssertFalse(
                value.containsHangul,
                "English value contains Korean for key: \(key)"
            )
        }
    }

    func testInfoPlistDeclaresAndTranslatesBothLanguages() throws {
        let data = try Data(
            contentsOf: repositoryRoot
                .appendingPathComponent("AppBundle/Info.plist")
        )
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        )
        XCTAssertEqual(
            Set(plist["CFBundleLocalizations"] as? [String] ?? []),
            Set(["en", "ko"])
        )

        let english = try strings(language: "en", table: "InfoPlist")
        let korean = try strings(language: "ko", table: "InfoPlist")
        XCTAssertEqual(Set(english.keys), Set(korean.keys))
        XCTAssertFalse(english.values.contains { $0.containsHangul })
    }

    private func strings(
        language: String,
        table: String
    ) throws -> [String: String] {
        let url = repositoryRoot
            .appendingPathComponent("AppBundle/Resources")
            .appendingPathComponent("\(language).lproj")
            .appendingPathComponent("\(table).strings")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(
            PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            )
                as? [String: String]
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static let requiredSimpleKeys = [
        "설정", "갱신 상태", "내 앱", "내 iPhone", "앱 미설정",
        "SideRefresh — 샘플 미리보기", "샘플 미리보기",
        "예시 데이터입니다. 실제 설정은 변경되지 않습니다.",
        "샘플 미리보기에서는 설정을 변경하지 않습니다.",
        "프로젝트 확인",
        "예시 진단 정보입니다. 실제 로그는 Release 앱에서 표시됩니다.",
        "iPhone 미선택", "iPhone 연결", "Xcode/CoreDevice 연결",
        "Xcode에서 iPhone 확인", "Tailscale 설치 필요",
        "Tailscale 주소 확인 완료", "자동 갱신", "진단 로그",
        "추가 주소 없음", "Tailscale 주소 · 실험적", "IP/DNS 직접 입력",
        "아직 Tailscale 기기 목록을 확인하지 않았습니다.",
        "갱신을 시작할 준비가 됐습니다.",
        "Xcode의 iPhone 목록 확인 시간이 초과되었습니다. Xcode에서 iPhone 연결 상태를 확인한 뒤 다시 시도해 주세요.",
        "저장 필요", "설정 미완료", "변경사항 저장",
        "Mac에서 설치할 앱 선택", "설치할 iPhone 선택",
        "먼저 설치할 앱을 선택하세요.",
        "먼저 설치할 iPhone을 선택하세요.",
        "선택한 앱의 Xcode 구성과 Apple 서명을 확인하세요.",
        "자동화의 임시 빌드 폴더를 확인하세요.",
        "검색 위치", "검색 위치 확인 중", "%ld개 위치에서 검색",
        "%ld개 위치 확인 필요", "%ld개 위치 접근 차단",
        "검색 가능한 위치 없음",
        "언어", "시스템 설정 따르기",
        "SideRefresh에서 사용할 언어를 선택하세요.",
        "기록 없음", "갱신할 앱을 선택하세요.",
        "앱 이름", "앱 식별자", "버전",
        "선택한 앱 사용", "Xcode에서 빌드할 대상 · %@",
        "프로젝트", "워크스페이스", "프로젝트 파일 수정 · %@",
        "앱 갱신",
        "Mac에서 빌드해 iPhone에 설치할 앱을 선택하세요. 같은 앱의 워크스페이스가 있으면 자동으로 사용합니다.",
        "Mac에서 iOS 앱 프로젝트를 찾을 준비가 됐습니다.",
    ]
}

private extension String {
    var containsHangul: Bool {
        range(of: "[가-힣]", options: .regularExpression) != nil
    }
}
