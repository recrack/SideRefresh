import SideRefreshAppPresentation
import SwiftUI

struct SimpleSettingsIPhoneEmptyState: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.gen3.slash")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text(
                SideRefreshLocalization.string(
                    isSearching
                        ? "Xcode에서 iPhone을 찾는 중…"
                        : "선택할 수 있는 iPhone이 없습니다"
                )
            )
                .font(.headline)
            Text("iPhone을 잠금 해제하고 Xcode에서 먼저 페어링하세요.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
