import XCTest
@testable import SideRefreshCore

final class FileRenewalStoreTests: XCTestCase {
    func testSuccessfulRenewalCanBeLoadedByANewStoreInstance() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let completedAt = Date(timeIntervalSince1970: 1_700_000_000)

        let writer = FileRenewalStore(fileURL: stateFile)
        try writer.recordSuccess(at: completedAt)
        let reader = FileRenewalStore(fileURL: stateFile)

        XCTAssertEqual(try reader.loadLastSuccessfulRenewal(), completedAt)
    }

    func testSuccessfulRenewalStoresProvisioningExpiration() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let stateFile = directory.appendingPathComponent("renewal-state.json")
        let completedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let expiration = Date(timeIntervalSince1970: 1_700_604_800)
        let store = FileRenewalStore(fileURL: stateFile)

        try store.recordSuccess(
            at: completedAt,
            provisioningExpirationDate: expiration,
            provisioningProfileIdentifier: "PROFILE-UUID"
        )

        XCTAssertEqual(
            try store.loadReceipt(),
            RenewalReceipt(
                completedAt: completedAt,
                provisioningExpirationDate: expiration,
                provisioningProfileIdentifier: "PROFILE-UUID"
            )
        )
    }

}
