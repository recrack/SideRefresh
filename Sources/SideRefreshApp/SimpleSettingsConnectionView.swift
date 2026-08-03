import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsConnectionView: View {
    @ObservedObject var model: SideRefreshViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("iPhone 연결", systemImage: "network")
                .font(.headline)
            Text(
                SideRefreshLocalization.string(
                    "실제 갱신은 항상 Xcode/CoreDevice가"
                        + " 선택한 iPhone을 사용합니다."
                        + " 원격 주소는 연결 준비를 돕는 정보입니다."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            Divider()
            routeEditor
        }
        .simpleWorkspaceCard()
        .accessibilityIdentifier("simple.settings.connection")
    }

    @ViewBuilder
    private var routeEditor: some View {
        if model.connectionRoute == .custom {
            customRouteEditor
        } else {
            Picker(
                "원격 주소 준비 · 선택",
                selection: $model.connectionRoute
            ) {
                Text("추가 주소 없음")
                    .tag(DeviceConnectionRoute.automatic)
                Text("Tailscale · 실험적")
                    .tag(DeviceConnectionRoute.tailnet)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("simple.settings.connection-route")
        }

        SimpleSettingsXcodeConnectionView(model: model)
        if model.connectionRoute == .tailnet {
            SimpleSettingsTailnetConnectionView(model: model)
        } else if model.connectionRoute == .automatic {
            Button("IP/DNS 직접 입력은 고급 설정에서…") {
                openAdvancedSettings()
            }
        }
    }

    private var customRouteEditor: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(
                "직접 IP/DNS 주소를 사용 중입니다.",
                systemImage: "network.badge.shield.half.filled"
            )
            Text(
                "직접 사용할 주소는 고급 설정에서 확인합니다."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            HStack {
                Button("추가 주소 사용 안 함") {
                    model.connectionRoute = .automatic
                }
                Button("고급 설정…") {
                    openAdvancedSettings()
                }
            }
        }
    }

    private func openAdvancedSettings() {
        SettingsWindowPresenter.shared.show(
            model: model,
            destination: .advancedSettings
        )
    }
}
