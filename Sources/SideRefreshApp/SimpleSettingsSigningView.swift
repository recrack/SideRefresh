import SideRefreshAppPresentation
import SideRefreshCore
import SwiftUI

struct SimpleSettingsSigningView: View {
    @ObservedObject var model: SideRefreshViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Apple 서명", systemImage: "person.badge.key.fill")
                    .font(.headline)
                Spacer()
                Button {
                    model.rediscoverPersonalTeam()
                } label: {
                    Text(
                        SideRefreshLocalization.string(
                            model.isDiscoveringPersonalTeam
                                ? "확인 중…"
                                : "Personal Team 찾기"
                        )
                    )
                }
                .disabled(
                    model.isDiscoveringPersonalTeam
                        || model.target.containerPath.isEmpty
                )
            }
            Label {
                Text(
                    SideRefreshLocalization.string(
                        teamIsReady
                            ? "이 Mac의 Personal Team을 사용할 준비가 됐습니다."
                            : "Xcode에 로그인된 무료 Personal Team을 확인하세요."
                    )
                )
            } icon: {
                Image(
                    systemName: teamIsReady
                        ? "checkmark.circle.fill"
                        : "exclamationmark.circle"
                )
            }
            .foregroundStyle(
                teamIsReady
                    ? SimpleWorkspacePalette.mint
                    : SimpleWorkspacePalette.amber
            )
            selectionControl
        }
        .simpleWorkspaceCard()
    }

    @ViewBuilder
    private var selectionControl: some View {
        if let selection = model.personalTeamSelection {
            switch selection {
            case .selected:
                EmptyView()
            case .confirmationRequired(let candidate):
                HStack {
                    Text("Team ID \(candidate.identifier)")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    Spacer()
                    Button("Xcode에서 확인한 팀 사용") {
                        model.usePersonalTeamCandidate(candidate)
                    }
                }
            case .notFound:
                HStack {
                    Text("Xcode에서 Apple ID와 Personal Team을 준비한 뒤 다시 찾으세요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Xcode 열기") {
                        model.openXcode()
                    }
                }
            case .ambiguous(let candidates):
                Menu("사용할 Personal Team 선택") {
                    ForEach(
                        Array(candidates.enumerated()),
                        id: \.element.id
                    ) { index, candidate in
                        Button {
                            model.usePersonalTeamCandidate(candidate)
                        } label: {
                            Text(
                                verbatim: SideRefreshLocalization.format(
                                    "후보 %ld · %@",
                                    index + 1,
                                    candidate.identifier
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    private var teamIsReady: Bool {
        let team = model.target.developmentTeam
        return team.count == 10
            && team.rangeOfCharacter(
                from: CharacterSet.alphanumerics.inverted
            ) == nil
    }
}
