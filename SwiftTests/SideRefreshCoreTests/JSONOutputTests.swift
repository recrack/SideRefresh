import Darwin
import XCTest
@testable import SideRefreshCore

final class JSONOutputTests: XCTestCase {
    func testWritingToAClosedDescriptorThrowsInsteadOfTrapping() {
        XCTAssertThrowsError(
            try SideRefreshJSONOutput.write(
                ["renewEveryHours": 144],
                to: -1
            )
        )
    }

    func testWritingToAPipeWithoutAReaderThrowsInsteadOfReceivingSIGPIPE() {
        var descriptors = [Int32](repeating: -1, count: 2)
        XCTAssertEqual(Darwin.pipe(&descriptors), 0)
        Darwin.close(descriptors[0])
        defer { Darwin.close(descriptors[1]) }

        XCTAssertThrowsError(
            try SideRefreshJSONOutput.write(
                ["renewEveryHours": 144],
                to: descriptors[1]
            )
        )
    }
}
