import XCTest
@testable import SideRefreshCore

final class RenewalScheduleTests: XCTestCase {
    func testNewInstallationIsDueImmediately() {
        let schedule = RenewalSchedule()
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let status = schedule.status(lastSuccessfulRenewal: nil, now: now)

        XCTAssertTrue(status.isDue)
        XCTAssertNil(status.lastSuccessfulRenewal)
        XCTAssertNil(status.nextDue)
    }

    func testRenewalBecomesDueAtTheSixDayBoundary() {
        let schedule = RenewalSchedule()
        let lastSuccess = Date(timeIntervalSince1970: 1_700_000_000)

        let beforeBoundary = schedule.status(
            lastSuccessfulRenewal: lastSuccess,
            now: lastSuccess.addingTimeInterval((144 * 60 * 60) - 1)
        )
        let atBoundary = schedule.status(
            lastSuccessfulRenewal: lastSuccess,
            now: lastSuccess.addingTimeInterval(144 * 60 * 60)
        )

        XCTAssertFalse(beforeBoundary.isDue)
        XCTAssertTrue(atBoundary.isDue)
        XCTAssertEqual(
            atBoundary.nextDue,
            Date(timeIntervalSince1970: 1_700_518_400)
        )
    }

    func testProfileExpirationMovesRenewalToOneDayBeforeExpiry() {
        let schedule = RenewalSchedule()
        let lastSuccess = Date(timeIntervalSince1970: 1_700_000_000)
        let expiration = lastSuccess.addingTimeInterval(5 * 24 * 60 * 60)

        let status = schedule.status(
            lastSuccessfulRenewal: lastSuccess,
            provisioningExpirationDate: expiration,
            now: lastSuccess
        )

        XCTAssertEqual(
            status.nextDue,
            expiration.addingTimeInterval(-24 * 60 * 60)
        )
        XCTAssertEqual(
            status.provisioningExpirationDate,
            expiration
        )
    }
}
