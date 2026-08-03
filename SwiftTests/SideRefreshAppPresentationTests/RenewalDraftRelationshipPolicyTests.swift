@testable import SideRefreshAppPresentation
import XCTest

final class RenewalDraftRelationshipPolicyTests: XCTestCase {
    func testSelectedAppIconIsPartOfTheRelationship() {
        let iconURL = URL(fileURLWithPath: "/tmp/AppIcon.png")
        let relationship = RenewalDraftRelationshipPolicy.relationship(
            hasGuidedTarget: true,
            containerPath: "/tmp/SideRefreshSample.xcodeproj",
            appName: "SideRefreshSample",
            bundleIdentifier: "io.github.siderefresh.sample",
            appVersion: "1.4.0 (42)",
            appIconURL: iconURL,
            iPhoneName: "My iPhone"
        )

        XCTAssertEqual(relationship?.appIconURL, iconURL)
    }

    func testSelectedAppAppearsBeforeIPhoneIsSelected() {
        let relationship = RenewalDraftRelationshipPolicy.relationship(
            hasGuidedTarget: true,
            containerPath: "/tmp/SideRefreshSample.xcodeproj",
            appName: "SideRefreshSample",
            bundleIdentifier: "io.github.siderefresh.sample",
            appVersion: "1.4.0 (42)",
            iPhoneName: nil,
            iPhoneOperatingSystemVersion: nil
        )

        XCTAssertEqual(
            relationship,
            RenewalRelationship(
                appName: "SideRefreshSample",
                bundleIdentifier: "io.github.siderefresh.sample",
                appVersion: "1.4.0 (42)",
                iPhoneName: "iPhone 미선택",
                iPhoneIsSelected: false
            )
        )
    }

    func testRelationshipProjectsConfiguredIPhoneVersion() {
        let relationship = RenewalDraftRelationshipPolicy.relationship(
            hasGuidedTarget: true,
            containerPath: "/tmp/SideRefreshSample.xcodeproj",
            appName: "SideRefreshSample",
            bundleIdentifier: "io.github.siderefresh.sample",
            appVersion: "1.4.0 (42)",
            iPhoneName: "My iPhone · iPhone 13 Pro Max",
            iPhoneOperatingSystemVersion: "26.5"
        )

        XCTAssertEqual(relationship?.appVersion, "1.4.0 (42)")
        XCTAssertEqual(
            relationship?.iPhoneOperatingSystemVersion,
            "26.5"
        )
        XCTAssertEqual(relationship?.iPhoneIsSelected, true)
    }

    func testEmptyAppSelectionHasNoDraftRelationship() {
        XCTAssertNil(
            RenewalDraftRelationshipPolicy.relationship(
                hasGuidedTarget: true,
                containerPath: "",
                appName: "",
                bundleIdentifier: "",
                appVersion: nil,
                iPhoneName: nil,
                iPhoneOperatingSystemVersion: nil
            )
        )
    }
}
