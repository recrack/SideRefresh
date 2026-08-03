import SwiftUI

struct SimpleWorkspacePageHeader<Accessory: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    private let accessory: Accessory

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 24) {
                copy
                Spacer(minLength: 20)
                accessory
            }
            VStack(alignment: .leading, spacing: 12) {
                copy
                accessory
            }
        }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension SimpleWorkspacePageHeader where Accessory == EmptyView {
    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey
    ) {
        self.init(title: title, subtitle: subtitle) {
            EmptyView()
        }
    }
}
