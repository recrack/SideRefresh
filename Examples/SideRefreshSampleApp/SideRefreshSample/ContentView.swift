import SwiftUI

struct ContentView: View {
    @AppStorage("launchCount") private var verificationCount = 0
    @AppStorage("lastVerifiedAt") private var lastVerifiedTimestamp = 0.0
    @AppStorage("lastSideRefreshInstallIdentifier")
    private var lastInstallIdentifier = ""
    @AppStorage("previousSideRefreshInstallIdentifier")
    private var previousInstallIdentifier = ""
    @AppStorage("sideRefreshBuildFirstOpenedAt")
    private var buildFirstOpenedTimestamp = 0.0
    @AppStorage("lastSideRefreshInstallWasUpdate")
    private var lastInstallWasUpdate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var confirmationPulse = false

    private let bundledEvidence = BundledRenewalEvidence()

    private var version: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String
        return "\(version ?? "1.0") (\(build ?? "1"))"
    }

    private var lastVerifiedText: String {
        guard lastVerifiedTimestamp > 0 else {
            return "아직 없음"
        }
        return Date(timeIntervalSince1970: lastVerifiedTimestamp)
            .formatted(date: .abbreviated, time: .shortened)
    }

    private var firstOpenedText: String {
        guard buildFirstOpenedTimestamp > 0 else {
            return "아직 없음"
        }
        return Date(timeIntervalSince1970: buildFirstOpenedTimestamp)
            .formatted(date: .abbreviated, time: .shortened)
    }

    private var renewalStatus: RenewalDisplayStatus {
        guard bundledEvidence.identifier != nil else {
            return .xcodeBuild
        }
        return lastInstallWasUpdate ? .updated : .firstInstall
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                ambientBackground

                ScrollView {
                    VStack(spacing: 24) {
                        hero
                        renewalStatusCard
                        verificationCard
                        verifyButton
                        explanation
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 36)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("SideRefresh Sample")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Label("개발용", systemImage: "hammer.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .sensoryFeedback(.success, trigger: verificationCount)
            .onAppear(perform: recordBundledRenewal)
        }
    }

    private var ambientBackground: some View {
        GeometryReader { proxy in
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 2)
                .offset(
                    x: proxy.size.width * 0.48,
                    y: -proxy.size.height * 0.08
                )

            Circle()
                .fill(Color.mint.opacity(0.12))
                .frame(width: 220, height: 220)
                .offset(
                    x: -proxy.size.width * 0.25,
                    y: proxy.size.height * 0.62
                )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var hero: some View {
        VStack(spacing: 16) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(
                    color: Color.blue.opacity(0.22),
                    radius: 24,
                    y: 12
                )
                .scaleEffect(confirmationPulse ? 1.06 : 1)
            .frame(width: 104, height: 104)
            .accessibilityHidden(true)

            VStack(spacing: 7) {
                Text("설치가 살아 있어요")
                    .font(.largeTitle.bold())
                    .tracking(-0.6)
                    .multilineTextAlignment(.center)

                Text("SideRefresh가 갱신한 앱이 정상적으로 열리고 데이터를 유지하는지 확인합니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 330)
            }
        }
        .padding(.top, 10)
    }

    private var verificationCard: some View {
        VStack(spacing: 0) {
            VerificationMetric(
                title: "설치 버전",
                value: version,
                systemImage: "shippingbox.fill",
                tint: .blue
            )
            Divider().padding(.leading, 48)
            VerificationMetric(
                title: "마지막 확인",
                value: lastVerifiedText,
                systemImage: "clock.fill",
                tint: .indigo
            )
            Divider().padding(.leading, 48)
            VerificationMetric(
                title: "누적 확인",
                value: "\(verificationCount)회",
                systemImage: "checkmark.seal.fill",
                tint: .mint
            )
        }
        .padding(.horizontal, 16)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.45))
        }
        .shadow(color: .black.opacity(0.055), radius: 18, y: 8)
    }

    private var renewalStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: renewalStatus.systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(renewalStatus.tint)
                    .frame(width: 42, height: 42)
                    .background(
                        renewalStatus.tint.opacity(0.13),
                        in: RoundedRectangle(
                            cornerRadius: 13,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(renewalStatus.title)
                        .font(.headline)
                    Text(renewalStatus.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            RenewalEvidenceRow(
                title: "현재 갱신 ID",
                value: bundledEvidence.identifier ?? "없음"
            )
            RenewalEvidenceRow(
                title: "이전 갱신 ID",
                value: previousInstallIdentifier.isEmpty
                    ? "이전 기록 없음" : previousInstallIdentifier
            )
            RenewalEvidenceRow(
                title: "갱신 빌드 시각",
                value: bundledEvidence.renewedAtText
            )
            RenewalEvidenceRow(
                title: "이 빌드 첫 실행",
                value: firstOpenedText
            )
        }
        .padding(18)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(renewalStatus.tint.opacity(0.22))
        }
        .shadow(color: .black.opacity(0.055), radius: 18, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(renewalStatus.title)
    }

    private var verifyButton: some View {
        Button {
            verificationCount += 1
            lastVerifiedTimestamp = Date().timeIntervalSince1970
            confirmationPulse = true
            withAnimation(
                reduceMotion
                    ? .easeOut(duration: 0.15)
                    : .spring(response: 0.34, dampingFraction: 0.72)
            ) {
                confirmationPulse = false
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text("설치 확인 기록")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 14))
        .controlSize(.large)
        .tint(
            LinearGradient(
                colors: [.blue, .teal],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .accessibilityHint("확인 횟수와 현재 시각을 기기에 저장합니다.")
    }

    private var explanation: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.secondary)
            Text(
                "현재 갱신 ID가 자동으로 바뀌면 새 앱 번들이 설치된 것입니다. "
                    + "누적 확인은 기존 앱 데이터가 유지됐는지 보는 별도 기록입니다."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineSpacing(3)
        }
        .padding(.horizontal, 6)
    }

    private func recordBundledRenewal() {
        guard let identifier = bundledEvidence.identifier else {
            return
        }
        guard identifier != lastInstallIdentifier else {
            return
        }

        previousInstallIdentifier = lastInstallIdentifier
        lastInstallWasUpdate = !lastInstallIdentifier.isEmpty
        lastInstallIdentifier = identifier
        buildFirstOpenedTimestamp = Date().timeIntervalSince1970
    }
}

private struct VerificationMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(
                    tint.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )

            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 14)
    }
}

private struct RenewalEvidenceRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

private struct BundledRenewalEvidence {
    let identifier: String?
    let renewedAt: Date?

    init(bundle: Bundle = .main) {
        let rawIdentifier = bundle.object(
            forInfoDictionaryKey: "SideRefreshInstallIdentifier"
        ) as? String
        if let rawIdentifier,
           !rawIdentifier.isEmpty,
           rawIdentifier != "XCODE-LOCAL",
           !rawIdentifier.contains("$(")
        {
            identifier = rawIdentifier
        } else {
            identifier = nil
        }

        let rawRenewedAt = bundle.object(
            forInfoDictionaryKey: "SideRefreshRenewedAt"
        ) as? String
        renewedAt = rawRenewedAt.flatMap {
            ISO8601DateFormatter().date(from: $0)
        }
    }

    var renewedAtText: String {
        guard let renewedAt else {
            return "없음"
        }
        return renewedAt.formatted(
            date: .abbreviated,
            time: .standard
        )
    }
}

private enum RenewalDisplayStatus {
    case xcodeBuild
    case firstInstall
    case updated

    var title: String {
        switch self {
        case .xcodeBuild:
            return "SideRefresh 갱신 대기 중"
        case .firstInstall:
            return "SideRefresh 설치 확인됨"
        case .updated:
            return "새 갱신 설치 확인됨"
        }
    }

    var subtitle: String {
        switch self {
        case .xcodeBuild:
            return "일반 Xcode 빌드에는 갱신 ID가 없습니다."
        case .firstInstall:
            return "이 기기에서 첫 갱신 ID를 확인했습니다."
        case .updated:
            return "이전과 다른 갱신 ID가 자동으로 감지됐습니다."
        }
    }

    var systemImage: String {
        switch self {
        case .xcodeBuild:
            return "hourglass"
        case .firstInstall:
            return "checkmark.seal.fill"
        case .updated:
            return "arrow.triangle.2.circlepath.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .xcodeBuild:
            return .orange
        case .firstInstall:
            return .blue
        case .updated:
            return .mint
        }
    }
}

#Preview {
    ContentView()
}
