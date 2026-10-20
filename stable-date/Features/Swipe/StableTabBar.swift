import SwiftUI

/// Decorative bottom bar. The only live part is the matches badge on the ♥ tab.
struct StableTabBar: View {
    let matchCount: Int

    var body: some View {
        HStack {
            tab("rectangle.stack.fill", label: "Discover", active: true)
            tab("heart", label: "\(matchCount) matches", active: false)
                .overlay(alignment: .topTrailing) {
                    if matchCount > 0 {
                        Text("\(matchCount)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.rose, in: Capsule())
                            .offset(x: -18, y: 4)
                            .accessibilityHidden(true)
                    }
                }
            tab("bubble.left", label: "Messages", active: false)
            tab("person", label: "Profile", active: false)
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.rose.opacity(0.08), radius: 0, y: -1)
        }
    }

    private func tab(_ symbol: String, label: String, active: Bool) -> some View {
        Image(systemName: symbol)
            .font(.title2)
            .foregroundStyle(active ? Color.rose : Color.inkSecondary.opacity(0.6))
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityLabel(label)
            .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    VStack {
        Spacer()
        StableTabBar(matchCount: 2)
    }
    .background(Color.appBackground)
}
