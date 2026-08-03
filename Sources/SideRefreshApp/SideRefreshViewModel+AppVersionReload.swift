import Foundation
import SideRefreshAppPresentation

extension SideRefreshViewModel {
    func handleAppVersionIdentityChange(
        from previousTarget: RenewalTargetDraft
    ) {
        guard !isLoadingConfiguration else {
            return
        }
        let previous = appVersionResolutionRequest(
            for: previousTarget
        )
        let current = appVersionResolutionRequest(for: target)
        switch AppVersionReloadPolicy.action(
            previous: previous,
            current: current
        ) {
        case .keep:
            return
        case .clear:
            clearTargetAppVersion()
            cancelPendingAppVersionReload()
            invalidateConfiguredXcodeContainerLoad()
        case let .clearAndResolve(request):
            clearTargetAppVersion()
            scheduleAppVersionReload(request)
        }
    }

    func cancelPendingAppVersionReload() {
        appVersionReloadDebounceTask?.cancel()
        appVersionReloadDebounceTask = nil
    }

    private func clearTargetAppVersion() {
        target.sourceMarketingVersion = ""
        target.sourceBuildVersion = ""
    }

    private func scheduleAppVersionReload(
        _ request: AppVersionResolutionRequest
    ) {
        cancelPendingAppVersionReload()
        appVersionReloadDebounceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(400))
            } catch {
                return
            }
            guard let self,
                  self.appVersionResolutionRequest(for: self.target)
                    == request
            else {
                return
            }
            self.appVersionReloadDebounceTask = nil
            self.loadConfiguredXcodeContainer(
                request.query.containerURL
            )
        }
    }
}
