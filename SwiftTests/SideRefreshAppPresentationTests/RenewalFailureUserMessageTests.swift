@testable import SideRefreshAppPresentation
import XCTest

final class RenewalFailureUserMessageTests: XCTestCase {
    func testMissingXcodeAccountGetsActionableGuidance() {
        let output = """
        error: No Accounts: Add a new account in Accounts settings.
        error: No profiles for 'com.example.app' were found
        """

        XCTAssertEqual(
            RenewalFailureUserMessage.message(for: output),
            "Xcode에 Apple Account가 없어 서명 프로필을 만들 수 없습니다. Xcode → Settings → Accounts에서 무료 Apple Account를 추가한 뒤, 앱 Target의 Signing & Capabilities에서 Personal Team을 선택하고 iPhone에서 한 번 실행하세요."
        )
    }

    func testMissingProfileGetsAutomaticSigningGuidance() {
        let output = """
        error: No profiles for 'com.example.app' were found
        """

        XCTAssertEqual(
            RenewalFailureUserMessage.message(for: output),
            "이 앱의 iOS Development 프로필이 없습니다. Xcode에서 Automatically manage signing과 Personal Team을 선택한 뒤 iPhone에서 한 번 실행해 프로필을 만드세요."
        )
    }

    func testUnrelatedFailureUsesTheExistingFallback() {
        XCTAssertNil(
            RenewalFailureUserMessage.message(
                for: "Swift compilation failed"
            )
        )
    }
}
