import SideRefreshAppPresentation
import SwiftUI

struct SimpleWorkspaceRelationshipView: View {
    let relationship: RenewalRelationship?
    let focus: FocusState<SimpleWorkspaceControl?>.Binding
    let accessibilityFocus:
        AccessibilityFocusState<
            SimpleWorkspaceAccessibilityFocus?
        >.Binding
    let onRoute: (AppPresentationRoute, SimpleWorkspaceControl) -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                SimpleWorkspaceEndpoint(
                    title: "내 앱",
                    name: relationship?.appName
                        ?? SideRefreshLocalization.string("앱 미설정"),
                    detail: AppIdentifierPresentation.appDetail(
                        bundleIdentifier: relationship?.bundleIdentifier,
                        appVersion: relationship?.appVersion
                    ),
                    showsCompletionCheck: relationship != nil,
                    systemImage: "app.badge"
                )
                VStack(spacing: 5) {
                    Image(systemName: "arrow.right")
                    Text("빌드 · 서명 · 설치")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(SimpleWorkspacePalette.blue)
                .accessibilityHidden(true)
                SimpleWorkspaceEndpoint(
                    title: "내 iPhone",
                    name: relationship?.iPhoneName
                        ?? SideRefreshLocalization.string("iPhone 미선택"),
                    detail: AppIdentifierPresentation.iPhoneDetail(
                        operatingSystemVersion:
                            relationship?
                                .iPhoneOperatingSystemVersion
                    ),
                    showsCompletionCheck:
                        relationship?.iPhoneIsSelected == true,
                    systemImage: "iphone.gen3"
                )
            }
            HStack {
                Button {
                    onRoute(.destination(.setup), .selectApp)
                } label: {
                    Text(
                        SideRefreshLocalization.string(
                            relationship == nil
                                ? "앱 선택"
                                : "앱 변경"
                        )
                    )
                }
                .focused(focus, equals: .selectApp)
                .accessibilityFocused(
                    accessibilityFocus,
                    equals: .control(.selectApp)
                )
                .accessibilityIdentifier(
                    SimpleWorkspaceControl.selectApp.rawValue
                )
                Spacer()
                Button {
                    onRoute(.destination(.setup), .selectIPhone)
                } label: {
                    Text(
                        SideRefreshLocalization.string(
                            relationship?.iPhoneIsSelected == true
                                ? "iPhone 변경"
                                : "iPhone 찾기"
                        )
                    )
                }
                .focused(focus, equals: .selectIPhone)
                .accessibilityFocused(
                    accessibilityFocus,
                    equals: .control(.selectIPhone)
                )
                .accessibilityIdentifier(
                    SimpleWorkspaceControl.selectIPhone.rawValue
                )
            }
        }
        .simpleWorkspaceCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            relationship?.simpleWorkspaceAccessibilityLabel
                ?? SideRefreshLocalization.string(
                    "갱신 대상이 아직 설정되지 않았습니다."
                )
        )
        .accessibilityIdentifier(
            SimpleWorkspaceRegion.relationship.rawValue
        )
    }

}
