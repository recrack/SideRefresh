import SideRefreshAppPresentation
import SideRefreshCore
import SwiftUI

struct SimpleSettingsRenewalView: View {
    @ObservedObject var model: SideRefreshViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                "갱신 방법",
                systemImage: "arrow.triangle.2.circlepath"
            )
            .font(.headline)
            Toggle("실제로 빌드하고 iPhone에 다시 설치", isOn: executes)
            Divider()
            HStack {
                Text("갱신 간격")
                Spacer()
                Stepper(
                    value: $model.renewEveryHours,
                    in: RenewalInterval.supportedHours
                ) {
                    Text(verbatim: intervalText)
                }
            }
            Picker("앱 버전", selection: $model.versionPolicy) {
                Text("현재 버전 유지")
                    .tag(IOSAppVersionPolicy.keep)
                Text("갱신할 때 다음 버전")
                    .tag(IOSAppVersionPolicy.automatic)
            }
            .pickerStyle(.segmented)
            Text("무료 Personal Team 만료 전에 다시 설치하도록 144시간(6일)을 권장합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .simpleWorkspaceCard()
    }

    private var executes: Binding<Bool> {
        Binding(
            get: { model.renewalMode == .execute },
            set: {
                model.renewalMode = $0 ? .execute : .dryRun
            }
        )
    }

    private var intervalText: String {
        let hours = model.renewEveryHours
        return hours.isMultiple(of: 24)
            ? SideRefreshLocalization.format(
                "%ld시간 (%ld일)",
                hours,
                hours / 24
            )
            : SideRefreshLocalization.format("%ld시간", hours)
    }
}
