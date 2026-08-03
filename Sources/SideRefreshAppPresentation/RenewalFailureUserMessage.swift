public enum RenewalFailureUserMessage {
    public static func message(for output: String) -> String? {
        if output.contains("No Accounts:") {
            return "Xcode에 Apple Account가 없어 서명 프로필을 만들 수 없습니다. Xcode → Settings → Accounts에서 무료 Apple Account를 추가한 뒤, 앱 Target의 Signing & Capabilities에서 Personal Team을 선택하고 iPhone에서 한 번 실행하세요."
        }
        if output.contains("No profiles for") {
            return "이 앱의 iOS Development 프로필이 없습니다. Xcode에서 Automatically manage signing과 Personal Team을 선택한 뒤 iPhone에서 한 번 실행해 프로필을 만드세요."
        }
        return nil
    }
}
