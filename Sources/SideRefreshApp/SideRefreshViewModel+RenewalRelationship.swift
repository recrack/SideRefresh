import Foundation
import SideRefreshAppPresentation
import SideRefreshCore

extension SideRefreshViewModel {
    var renewalDraftRelationship: RenewalRelationship? {
        RenewalDraftRelationshipPolicy.relationship(
            hasGuidedTarget: hasGuidedTarget,
            containerPath: target.containerPath,
            appName: target.displayName,
            bundleIdentifier: target.bundleIdentifier,
            appVersion: appVersion(for: target),
            appIconURL: appIconURL(for: target),
            iPhoneName: selectedCoreDeviceDisplayLabel,
            iPhoneOperatingSystemVersion:
                selectedCoreDeviceOperatingSystemVersion
        )
    }

    var renewalPresentationRelationship: RenewalRelationship? {
        guard let savedTarget = savedRenewalTarget,
              savedTarget.isComplete
        else {
            return nil
        }
        let discoveredDevice = pairedCoreDevices.first {
            $0.udid == savedTarget.deviceIdentifier
        }
        let usesCurrentSelection =
            savedTarget.deviceIdentifier == target.deviceIdentifier
        let iPhoneName = RenewalIPhoneNamePolicy.resolve(
            discoveredName: discoveredDevice?.name,
            rememberedName: usesCurrentSelection
                ? selectedCoreDeviceDisplayName
                : nil,
            deviceIdentifier: savedTarget.deviceIdentifier,
            discoveredModelName: discoveredDevice?.marketingName,
            rememberedModelName: usesCurrentSelection
                ? selectedCoreDeviceMarketingName
                : nil
        )
        let operatingSystemVersion = normalized(
            discoveredDevice?.operatingSystemVersion
                ?? (usesCurrentSelection
                    ? selectedCoreDeviceOperatingSystemVersion
                    : nil)
        )
        return RenewalRelationship(
            appName: savedTarget.displayName,
            bundleIdentifier: savedTarget.bundleIdentifier,
            appVersion: appVersion(for: savedTarget),
            appIconURL: appIconURL(for: savedTarget),
            iPhoneName: iPhoneName,
            iPhoneOperatingSystemVersion: operatingSystemVersion
        )
    }

    private func appVersion(for target: RenewalTargetDraft) -> String? {
        AppIdentifierPresentation.appVersion(
            marketingVersion: target.sourceMarketingVersion
        )
    }

    private func appIconURL(
        for target: RenewalTargetDraft
    ) -> URL? {
        guard let candidate = discoveredXcodeContainers.first(
            where: { $0.id == target.containerPath }
        ) else {
            return nil
        }
        return candidate.applications.first {
            $0.bundleIdentifier == target.bundleIdentifier
        }?.iconURL
    }

    private func normalized(_ value: String?) -> String? {
        let value = value?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        return value.isEmpty ? nil : value
    }
}
