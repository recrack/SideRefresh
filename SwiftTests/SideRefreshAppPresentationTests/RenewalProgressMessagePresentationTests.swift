@testable import SideRefreshAppPresentation
import SideRefreshCore
import XCTest

final class RenewalProgressMessagePresentationTests: XCTestCase {
    func testPresentationUsesThePhaseInsteadOfRawHelperCopy() {
        let event = RenewalProgressEvent(
            phase: .building,
            state: .started,
            message: "Runner · Release · 스마트 증분 빌드"
        )

        XCTAssertEqual(
            RenewalProgressMessagePresentation.message(for: event),
            "Xcode 빌드를 시작합니다."
        )
    }

    func testEveryProgressStateHasEnglishAndKoreanCatalogCopy()
        throws
    {
        let english = try strings(language: "en")
        let korean = try strings(language: "ko")

        for phase in RenewalProgressPhase.allCases {
            for state in Self.states {
                let event = RenewalProgressEvent(
                    phase: phase,
                    state: state,
                    message: "raw helper detail"
                )
                let key = RenewalProgressMessagePresentation
                    .sourceMessage(for: event)
                let englishValue = try XCTUnwrap(
                    english[key],
                    "Missing English progress copy: \(key)"
                )
                XCTAssertNotNil(
                    korean[key],
                    "Missing Korean progress copy: \(key)"
                )
                XCTAssertFalse(
                    englishValue.containsHangul,
                    "English progress copy contains Korean: \(key)"
                )
            }
        }
    }

    private func strings(language: String) throws -> [String: String] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root
            .appendingPathComponent("AppBundle/Resources")
            .appendingPathComponent("\(language).lproj")
            .appendingPathComponent("Localizable.strings")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(
            PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: String]
        )
    }

    private static let states: [RenewalProgressState] = [
        .started,
        .succeeded,
        .failed,
    ]
}

private extension String {
    var containsHangul: Bool {
        range(of: "[가-힣]", options: .regularExpression) != nil
    }
}
