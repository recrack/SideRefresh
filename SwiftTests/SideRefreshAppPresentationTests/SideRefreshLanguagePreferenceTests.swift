import Foundation
import SideRefreshAppPresentation
import XCTest

final class SideRefreshLanguagePreferenceTests: XCTestCase {
    func testUnknownOrMissingStoredValueFallsBackToSystem() {
        let defaults = isolatedDefaults()

        XCTAssertEqual(
            SideRefreshLocalization.languagePreference(in: defaults),
            .system
        )

        defaults.set(
            "unsupported",
            forKey: SideRefreshLocalization.preferenceKey
        )

        XCTAssertEqual(
            SideRefreshLocalization.languagePreference(in: defaults),
            .system
        )
    }

    func testLanguagePreferencePersistsInInjectedDefaults() {
        let defaults = isolatedDefaults()

        SideRefreshLocalization.setLanguagePreference(
            .english,
            in: defaults
        )

        XCTAssertEqual(
            SideRefreshLocalization.languagePreference(in: defaults),
            .english
        )
        XCTAssertEqual(
            defaults.string(
                forKey: SideRefreshLocalization.preferenceKey
            ),
            SideRefreshLanguagePreference.english.rawValue
        )
    }

    func testExplicitLanguageUsesMatchingLocalizationBundle() throws {
        let appBundle = try XCTUnwrap(
            Bundle(
                path: repositoryRoot
                    .appendingPathComponent("AppBundle")
                    .path
            )
        )

        XCTAssertEqual(
            SideRefreshLocalization.string(
                "설정",
                language: .english,
                bundle: appBundle
            ),
            "Settings"
        )
        XCTAssertEqual(
            SideRefreshLocalization.string(
                "설정",
                language: .korean,
                bundle: appBundle
            ),
            "설정"
        )
    }

    func testExplicitLanguagesExposeLocaleWhileSystemDefers() {
        XCTAssertNil(SideRefreshLanguagePreference.system.localeIdentifier)
        XCTAssertEqual(
            SideRefreshLanguagePreference.korean.localeIdentifier,
            "ko"
        )
        XCTAssertEqual(
            SideRefreshLanguagePreference.english.localeIdentifier,
            "en"
        )
    }

    func testDateFormattingUsesExplicitAppLanguage() throws {
        let date = try XCTUnwrap(
            Calendar(identifier: .gregorian).date(
                from: DateComponents(
                    timeZone: TimeZone(secondsFromGMT: 0),
                    year: 2026,
                    month: 8,
                    day: 2,
                    hour: 13,
                    minute: 5
                )
            )
        )

        let english = SideRefreshLocalization.date(
            date,
            dateStyle: .medium,
            timeStyle: .short,
            language: .english,
            timeZone: TimeZone(secondsFromGMT: 0)
        )
        let korean = SideRefreshLocalization.date(
            date,
            dateStyle: .medium,
            timeStyle: .short,
            language: .korean,
            timeZone: TimeZone(secondsFromGMT: 0)
        )

        XCTAssertNotEqual(english, korean)
        XCTAssertTrue(english.localizedCaseInsensitiveContains("Aug"))
        XCTAssertTrue(korean.contains("8"))
    }

    func testLocalizedTextPreservesSemanticArgumentsAcrossLanguages()
        throws
    {
        let appBundle = try XCTUnwrap(
            Bundle(
                path: repositoryRoot
                    .appendingPathComponent("AppBundle")
                    .path
            )
        )
        let message = SideRefreshLocalizedText.format(
            "%@에서 %ld개 발견",
            .localizedKey("허용된 검색 위치"),
            .integer(4)
        )

        XCTAssertEqual(
            message.resolved(language: .korean, bundle: appBundle),
            "허용된 검색 위치에서 4개 발견"
        )
        XCTAssertEqual(
            message.resolved(language: .english, bundle: appBundle),
            "In Allowed search locations, found 4"
        )
    }

    func testLocalizedTextKeepsProjectScanWarningMeaning() throws {
        let appBundle = try XCTUnwrap(
            Bundle(
                path: repositoryRoot
                    .appendingPathComponent("AppBundle")
                    .path
            )
        )
        let message = SideRefreshLocalizedText.format(
            "%@에서 200개 발견 · 최대 200개까지만 보여줍니다. 일부 폴더를 확인하지 못했습니다.",
            .localizedText(.key("허용된 검색 위치"))
        )

        let korean = message.resolved(
            language: .korean,
            bundle: appBundle
        )
        let english = message.resolved(
            language: .english,
            bundle: appBundle
        )

        XCTAssertTrue(korean.contains("최대 200개"))
        XCTAssertTrue(korean.contains("일부 폴더"))
        XCTAssertTrue(english.contains("first 200"))
        XCTAssertTrue(english.contains("Some folders"))
    }

    func testLocalizedTextKeepsCoreDeviceFailureMeaning() throws {
        let appBundle = try XCTUnwrap(
            Bundle(
                path: repositoryRoot
                    .appendingPathComponent("AppBundle")
                    .path
            )
        )
        let message = SideRefreshLocalizedText.key(
            "Xcode의 iPhone 목록을 읽지 못했습니다."
        )

        XCTAssertEqual(
            message.resolved(language: .korean, bundle: appBundle),
            "Xcode의 iPhone 목록을 읽지 못했습니다."
        )
        XCTAssertEqual(
            message.resolved(language: .english, bundle: appBundle),
            "Could not read Xcode's iPhone list."
        )
    }

    private func isolatedDefaults() -> UserDefaults {
        let suiteName = "SideRefreshLanguagePreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            UserDefaults(suiteName: suiteName)?
                .removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
