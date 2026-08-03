import Foundation
import SideRefreshAppPresentation

extension RenewalPresentation {
    var sideRefreshScheduleSummary: String {
        if let progress {
            return progress.message
        }
        if condition == .healthy, let nextRenewalDate {
            return SideRefreshLocalization.format(
                "다음 갱신 %@",
                SideRefreshLocalization.date(
                    nextRenewalDate,
                    dateStyle: .medium,
                    timeStyle: .short
                )
            )
        }
        return condition.sideRefreshDetail
    }
}
