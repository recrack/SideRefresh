@testable import SideRefreshAppPresentation
import XCTest

final class RenewalIPhoneNamePolicyTests: XCTestCase {
    func testNameAndModelIdentifyTheSelectedIPhone() {
        XCTAssertEqual(
            RenewalIPhoneNamePolicy.resolve(
                discoveredName: "My iPhone",
                rememberedName: nil,
                deviceIdentifier: "00008120-001C2D123456A1B2",
                discoveredModelName: "iPhone 13 Pro Max"
            ),
            "My iPhone · iPhone 13 Pro Max"
        )
    }

    func testRememberedModelIdentifiesSavedIPhoneBeforeDiscovery() {
        XCTAssertEqual(
            RenewalIPhoneNamePolicy.resolve(
                discoveredName: nil,
                rememberedName: "My iPhone",
                deviceIdentifier: "00008120-001C2D123456A1B2",
                rememberedModelName: "iPhone 13 Pro Max"
            ),
            "My iPhone · iPhone 13 Pro Max"
        )
    }

    func testModelIsNotRepeatedWhenItMatchesTheDeviceName() {
        XCTAssertEqual(
            RenewalIPhoneNamePolicy.resolve(
                discoveredName: "iPhone 13 Pro Max",
                rememberedName: nil,
                deviceIdentifier: "00008120-001C2D123456A1B2",
                discoveredModelName: "iPhone 13 Pro Max"
            ),
            "iPhone 13 Pro Max"
        )
    }

    func testRememberedNameIdentifiesSavedIPhoneBeforeDiscovery() {
        XCTAssertEqual(
            RenewalIPhoneNamePolicy.resolve(
                discoveredName: nil,
                rememberedName: "My iPhone",
                deviceIdentifier: "00008120-001C2D123456A1B2"
            ),
            "My iPhone"
        )
    }

    func testIdentifierSuffixDistinguishesAnUnnamedSavedIPhone() {
        XCTAssertEqual(
            RenewalIPhoneNamePolicy.resolve(
                discoveredName: nil,
                rememberedName: nil,
                deviceIdentifier: "00008120-001C2D123456A1B2"
            ),
            "iPhone · A1B2"
        )
    }
}
