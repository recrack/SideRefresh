import Foundation
import XCTest

final class LocalizationFormatPlaceholderTests: XCTestCase {
    func testTranslationsPreserveFormatPlaceholderTypes() throws {
        let english = try strings(language: "en")
        let korean = try strings(language: "ko")

        for key in english.keys.sorted() {
            let source = try XCTUnwrap(
                placeholders(in: key),
                "Invalid source format string: \(key)"
            )
            XCTAssertEqual(
                try XCTUnwrap(
                    placeholders(in: english[key] ?? ""),
                    "Invalid English format string for: \(key)"
                ),
                source,
                "English placeholders differ for: \(key)"
            )
            XCTAssertEqual(
                try XCTUnwrap(
                    placeholders(in: korean[key] ?? ""),
                    "Invalid Korean format string for: \(key)"
                ),
                source,
                "Korean placeholders differ for: \(key)"
            )
        }
    }

    func testPlaceholderParserCoversFlagsWidthsAndEscapes() {
        XCTAssertEqual(
            placeholders(
                in: "value %@ count %02ld ratio %.2f hex %#08x %%"
            ),
            ["%@", "%02ld", "%.2f", "%#08x"]
        )
        XCTAssertEqual(
            placeholders(in: "%1$@ · %2$lld · %3$u"),
            ["%1$@", "%2$lld", "%3$u"]
        )
    }

    func testPlaceholderParserRejectsMalformedFormats() {
        for value in ["%", "%Q", "%2$", "%."] {
            XCTAssertNil(placeholders(in: value), value)
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

    private func placeholders(in text: String) -> [String]? {
        let value = text as NSString
        var searchLocation = 0
        var result: [String] = []

        while searchLocation < value.length {
            let percentRange = value.range(
                of: "%",
                range: NSRange(
                    location: searchLocation,
                    length: value.length - searchLocation
                )
            )
            guard percentRange.location != NSNotFound else {
                break
            }
            let percentLocation = percentRange.location
            if percentLocation + 1 < value.length,
               value.character(at: percentLocation + 1) == 37
            {
                searchLocation = percentLocation + 2
                continue
            }

            let remainder = value.substring(from: percentLocation)
            let range = NSRange(
                location: 0,
                length: (remainder as NSString).length
            )
            guard let match = Self.placeholderExpression.firstMatch(
                in: remainder,
                range: range
            ),
                  match.range.location == 0
            else {
                return nil
            }
            result.append(
                (remainder as NSString).substring(with: match.range)
            )
            searchLocation = percentLocation + match.range.length
        }
        return result
    }

    private static let placeholderExpression = try! NSRegularExpression(
        pattern:
            #"^%(?:\d+\$)?[-+ #0']*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|q|L|z|t|j)?[@diuoxXfFeEgGaAcCsSp]"#
    )
}
