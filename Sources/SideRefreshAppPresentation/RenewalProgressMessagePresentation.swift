import Foundation
import SideRefreshCore

public enum RenewalProgressMessagePresentation {
    public static func message(
        for event: RenewalProgressEvent,
        bundle: Bundle = .main
    ) -> String {
        SideRefreshLocalization.string(
            sourceMessage(for: event),
            bundle: bundle
        )
    }

    static func sourceMessage(
        for event: RenewalProgressEvent
    ) -> String {
        switch event.phase {
        case .preparing:
            switch event.state {
            case .started: "저장된 갱신 설정을 읽습니다."
            case .succeeded: "갱신 설정을 확인했습니다."
            case .failed: "갱신 설정을 확인하지 못했습니다."
            }
        case .checkingConnection:
            switch event.state {
            case .started: "iPhone 연결을 확인합니다."
            case .succeeded: "iPhone 연결 준비를 확인했습니다."
            case .failed: "iPhone 연결을 확인하지 못했습니다."
            }
        case .cleaningBuild:
            switch event.state {
            case .started: "이전 빌드 결과를 확인합니다."
            case .succeeded: "빌드 준비를 완료했습니다."
            case .failed: "빌드 준비를 완료하지 못했습니다."
            }
        case .building:
            switch event.state {
            case .started: "Xcode 빌드를 시작합니다."
            case .succeeded: "Xcode 빌드가 완료됐습니다."
            case .failed: "Xcode 빌드를 완료하지 못했습니다."
            }
        case .validatingApp:
            switch event.state {
            case .started: "빌드된 앱의 Bundle ID를 확인합니다."
            case .succeeded: "Bundle ID를 확인했습니다."
            case .failed: "Bundle ID를 확인하지 못했습니다."
            }
        case .readingProfile:
            switch event.state {
            case .started:
                "Apple Development 서명과 만료일을 확인합니다."
            case .succeeded:
                "Apple Development 서명 만료일을 확인했습니다."
            case .failed:
                "Apple Development 서명을 확인하지 못했습니다."
            }
        case .installing:
            switch event.state {
            case .started: "빌드된 앱을 선택한 iPhone에 설치합니다."
            case .succeeded: "iPhone 설치가 완료됐습니다."
            case .failed: "iPhone 설치를 완료하지 못했습니다."
            }
        case .recordingReceipt:
            switch event.state {
            case .started: "설치 결과와 서명 만료일을 기록합니다."
            case .succeeded: "갱신 기록을 저장했습니다."
            case .failed: "서명 만료일을 기록하지 못했습니다."
            }
        case .completed:
            switch event.state {
            case .started: "갱신을 마무리합니다."
            case .succeeded: "앱 빌드·서명·설치를 완료했습니다."
            case .failed: "앱을 바로 갱신하지 못했습니다."
            }
        }
    }
}
