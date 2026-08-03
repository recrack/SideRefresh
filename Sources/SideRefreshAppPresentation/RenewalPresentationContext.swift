import Foundation
import SideRefreshCore

public struct LastVerifiedEvidence: Equatable, Sendable {
    public let installedAt: Date
    public let expiresAt: Date

    public init(installedAt: Date, expiresAt: Date) {
        self.installedAt = installedAt
        self.expiresAt = expiresAt
    }
}

public struct RenewalRelationship: Equatable, Sendable {
    public let appName: String
    public let bundleIdentifier: String?
    public let appVersion: String?
    public let appIconURL: URL?
    public let iPhoneName: String
    public let iPhoneOperatingSystemVersion: String?
    public let iPhoneIsSelected: Bool

    public init(
        appName: String,
        bundleIdentifier: String? = nil,
        appVersion: String? = nil,
        appIconURL: URL? = nil,
        iPhoneName: String,
        iPhoneOperatingSystemVersion: String? = nil,
        iPhoneIsSelected: Bool = true
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.appVersion = appVersion
        self.appIconURL = appIconURL
        self.iPhoneName = iPhoneName
        self.iPhoneOperatingSystemVersion =
            iPhoneOperatingSystemVersion
        self.iPhoneIsSelected = iPhoneIsSelected
    }
}

public struct RenewalPresentationProgress: Equatable, Sendable {
    public let phase: RenewalProgressPhase
    public let message: String

    public init(phase: RenewalProgressPhase, message: String) {
        self.phase = phase
        self.message = message
    }
}

public struct RenewalRecentResult: Equatable, Sendable {
    public let outcome: RenewalRecentOutcome
    public let completedAt: Date
    public let summary: String

    public init(
        outcome: RenewalRecentOutcome,
        completedAt: Date,
        summary: String
    ) {
        self.outcome = outcome
        self.completedAt = completedAt
        self.summary = summary
    }
}
