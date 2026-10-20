import SwiftUI

/// "Discover · Ubud, Bali" with two decorative square buttons.
struct DiscoverHeader: View {
    var body: some View {
        HStack {
            HeaderButton(symbol: "chevron.left", label: Copy.backLabel)
            Spacer()
            VStack(spacing: 2) {
                Text(Copy.discoverTitle)
                    .font(.title.bold())
                    .foregroundStyle(Color.ink)
                Text(Copy.discoverLocation)
                    .font(.headline.weight(.regular))
                    .foregroundStyle(Color.inkSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer()
            HeaderButton(symbol: "slider.horizontal.3", label: Copy.filterLabel)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

// MARK: - Subviews

/// Decorative: no action, still has a label for VoiceOver.
private struct HeaderButton: View {
    let symbol: String
    let label: String

    var body: some View {
        Button {} label: {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.rose)
                .frame(width: 56, height: 56)
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.blush, lineWidth: 1)
                }
        }
        .accessibilityLabel(label)
    }
}

#Preview { DiscoverHeader().background(Color.appBackground) }
