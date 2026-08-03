import SideRefreshAppPresentation
import SideRefreshCore

extension SideRefreshViewModel {
    var renewalPresentationProgress: RenewalPresentationProgress? {
        guard renewalRunPresentationState == .running else {
            return nil
        }
        let event = orderedRenewalProgressEvents.last
        return RenewalPresentationProgress(
            phase: event?.phase ?? .preparing,
            message: event.map {
                RenewalProgressMessagePresentation.message(for: $0)
            }
                ?? SideRefreshLocalization.string(
                    "갱신을 준비하고 있습니다."
                )
        )
    }

    var renewalPresentationFailure: RenewalPresentationFailure? {
        if renewalResultLacksExpirationEvidence
            || (
                renewalRunPresentationState == .succeeded
                    && renewalPresentationEvidence == nil
            )
        {
            return .unverifiedInstallation
        }
        if renewalStatusCheckDidFail {
            return .unknown
        }
        guard renewalRunPresentationState == .failed else {
            return nil
        }
        let failedPhase = orderedRenewalProgressEvents.reversed()
            .first {
                $0.state == .failed && $0.phase != .completed
            }?.phase
        switch failedPhase {
        case .checkingConnection:
            return .connection
        case .cleaningBuild, .building, .validatingApp,
             .readingProfile:
            return .buildOrSigning
        case .installing:
            return .installation
        case .recordingReceipt:
            return .unverifiedInstallation
        case .preparing, .completed, nil:
            return .unknown
        }
    }

    var renewalPresentationRecentResult: RenewalRecentResult? {
        let outcome: RenewalRecentOutcome
        switch renewalRunPresentationState {
        case .idle, .running:
            return nil
        case .succeeded:
            outcome = renewalPresentationFailure.map {
                .failed($0)
            } ?? .verified
        case .failed:
            outcome = .failed(renewalPresentationFailure ?? .unknown)
        }
        guard let completedAt =
                renewalRunCompletedAt ?? lastSuccessfulRenewal
        else {
            return nil
        }
        let summary = orderedRenewalProgressEvents.last.map {
            RenewalProgressMessagePresentation.message(for: $0)
        } ?? SideRefreshLocalization.string(
            "갱신을 시작할 준비가 됐습니다."
        )
        return RenewalRecentResult(
            outcome: outcome,
            completedAt: completedAt,
            summary: summary
        )
    }
}
