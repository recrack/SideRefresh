import Foundation
import XCTest

final class LocalizationCatalogUniquenessTests: XCTestCase {
    func testStringCatalogsDoNotContainDuplicateKeys() throws {
        for language in ["en", "ko"] {
            for table in ["Localizable", "InfoPlist"] {
                let keys = try rawKeys(language: language, table: table)
                XCTAssertEqual(
                    keys.count,
                    Set(keys).count,
                    "Duplicate key in \(language).lproj/\(table).strings"
                )
            }
        }
    }

    private func rawKeys(
        language: String,
        table: String
    ) throws -> [String] {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root
            .appendingPathComponent("AppBundle/Resources")
            .appendingPathComponent("\(language).lproj")
            .appendingPathComponent("\(table).strings")
        let source = try String(contentsOf: url, encoding: .utf8)
        let expression = try NSRegularExpression(
            pattern: #"(?m)^\s*"((?:\\.|[^"\\])*)"\s*="#
        )
        let range = NSRange(source.startIndex..., in: source)
        return expression.matches(in: source, range: range).compactMap {
            Range($0.range(at: 1), in: source).map { String(source[$0]) }
        }
    }
}
