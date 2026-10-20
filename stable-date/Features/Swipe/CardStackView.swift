import SwiftUI

/// The deck: top card plus two peeking behind it, and the ✕ ★ ♥ buttons.
struct CardStackView: View {
    let horses: [Horse]
    let onSwipe: (Horse, Bool) -> Void
    let onSuperLike: (Horse) -> Void
    let onTap: (Horse) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isAnimating = false
    @State private var swipeCount = 0

    private var top: Horse? { horses.first }

    var body: some View {
        ZStack {
            ForEach(Array(horses.prefix(3).enumerated()).reversed(), id: \.element.id) { index, horse in
                if index == 0 {
                    HorseCardView(horse: horse)
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width / 50)))
                        .gesture(dragGesture(for: horse))
                        .onTapGesture { onTap(horse) }
                        .accessibilityAddTraits(.isButton)
                } else {
                    HorseCardView(horse: horse)
                        .scaleEffect(1 - CGFloat(index) * 0.04, anchor: .bottom)
                        .offset(y: CGFloat(index) * 8)
                        .accessibilityHidden(true)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 12) {
                SwipeButton(symbol: "xmark", tint: .plum, fill: .white, label: Copy.nopeLabel) {
                    if let top { swipe(top, liked: false) }
                }
                SwipeButton(symbol: "star.fill", tint: .lavender, fill: .lavenderSoft, label: Copy.superLikeLabel) {
                    if let top { swipe(top, liked: true, superLike: true) }
                }
                SwipeButton(symbol: "heart.fill", tint: .white, fill: .rose, label: Copy.likeLabel) {
                    if let top { swipe(top, liked: true) }
                }
            }
            .offset(x: 12, y: -24)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: swipeCount)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Actions

    private func dragGesture(for horse: Horse) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isAnimating else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard !isAnimating else { return }
                if abs(value.translation.width) > 120 {
                    swipe(horse, liked: value.translation.width > 0)
                } else {
                    withAnimation(.spring(duration: 0.3)) { dragOffset = .zero }
                }
            }
    }

    private func swipe(_ horse: Horse, liked: Bool, superLike: Bool = false) {
        guard !isAnimating else { return }
        isAnimating = true
        swipeCount += 1
        withAnimation(.easeOut(duration: 0.35)) {
            dragOffset = CGSize(width: liked ? 600 : -600, height: -40)
        } completion: {
            if superLike { onSuperLike(horse) } else { onSwipe(horse, liked) }
            dragOffset = .zero
            isAnimating = false
        }
    }
}

// MARK: - Subviews

private struct SwipeButton: View {
    let symbol: String
    let tint: Color
    let fill: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 62, height: 62)
                .background {
                    Circle()
                        .fill(fill)
                        .shadow(color: Color.rose.opacity(0.2), radius: 10, y: 4)
                }
        }
        .accessibilityLabel(label)
    }
}

#Preview { CardStackView(horses: Horse.samples, onSwipe: { _, _ in }, onSuperLike: { _ in }, onTap: { _ in }).background(Color.appBackground) }
