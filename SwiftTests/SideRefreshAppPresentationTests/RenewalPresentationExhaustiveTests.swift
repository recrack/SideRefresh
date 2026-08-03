@testable import SideRefreshAppPresentation
import XCTest

final class RenewalPresentationExhaustiveTests: XCTestCase {
    func testEveryConditionHasItsCanonicalAction() {
        for condition in RenewalCondition.allCases {
            let scenario = RenewalConditionFixture.scenario(
                for: condition
            )
            let result = RenewalPresentationResolver.resolve(
                scenario.input
            )

            XCTAssertEqual(result.condition, condition)
            XCTAssertEqual(result.nextAction, scenario.action)
        }
    }
}
