@testable import SideRefreshAppPresentation
import XCTest

final class SimpleErrorMessagePresentationTests: XCTestCase {
    func testKnownProductErrorUsesTheSelectedCatalog() throws {
        XCTAssertEqual(
            SimpleErrorMessagePresentation.message(
                .productKey("Xcode를 찾을 수 없습니다."),
                bundle: try languageBundle("en")
            ),
            "Xcode could not be found."
        )
        XCTAssertEqual(
            SimpleErrorMessagePresentation.message(
                .productKey("Xcode를 찾을 수 없습니다."),
                bundle: try languageBundle("ko")
            ),
            "Xcode를 찾을 수 없습니다."
        )
    }

    func testVerbatimKoreanOutputIsNeverTreatedAsAProductKey() throws {
        let output = "새로운 외부 도구 오류 문구"
        XCTAssertEqual(
            SimpleErrorMessagePresentation.message(
                .verbatim(output),
                bundle: try languageBundle("en")
            ),
            output
        )
    }

    func testVerbatimOutputMatchingAProductKeyIsNotTranslated()
        throws
    {
        let output = "Xcode를 찾을 수 없습니다."
        XCTAssertEqual(
            SimpleErrorMessagePresentation.message(
                .verbatim(output),
                bundle: try languageBundle("en")
            ),
            output
        )
    }

    private func languageBundle(_ language: String) throws -> Bundle {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try XCTUnwrap(
            Bundle(
                path: root
                    .appendingPathComponent("AppBundle/Resources")
                    .appendingPathComponent("\(language).lproj")
                    .path
            )
        )
    }
}
