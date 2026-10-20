import SwiftUI

/// The payoff: two tilted photos and "It's a match!!". Both buttons dismiss.
struct MatchOverlayView: View {
    let horse: Horse
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            photos
                .padding(.bottom, 36)
            Text(Copy.matchCaption)
                .font(.subheadline.bold())
                .tracking(4)
                .foregroundStyle(Color.rose)
            Text(Copy.matchTitle)
                .font(.largeTitle.bold())
                .foregroundStyle(Color.ink)
            Text(bodyText(for: horse.name))
                .font(.title3)
                .foregroundStyle(Color.inkSecondary)
            Spacer(minLength: 0)
            Button(Copy.sayHelloButton, action: onDismiss)
                .buttonStyle(MatchButtonStyle(filled: true))
            Button(Copy.matchButton, action: onDismiss)
                .buttonStyle(MatchButtonStyle(filled: false))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(colors: [.appBackground, .blush], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var photos: some View {
        ZStack {
            PhotoCard(imageName: "horse-04", badgeFill: .white, badgeTint: .rose)
                .rotationEffect(.degrees(-9))
                .offset(x: -70, y: -24)
            PhotoCard(imageName: horse.imageName, badgeFill: .rose, badgeTint: .white, badgeAtBottom: true)
                .rotationEffect(.degrees(7))
                .offset(x: 70, y: 24)
        }
        .accessibilityHidden(true)
    }

    /// "You and **name** are now trotting together." with the name in bold ink.
    private func bodyText(for name: String) -> AttributedString {
        var text = (try? AttributedString(markdown: Copy.matchBody(name: name))) ?? AttributedString(Copy.matchBody(name: name))
        if let range = text.range(of: name) {
            text[range].foregroundColor = Color.ink
        }
        return text
    }
}

// MARK: - Subviews

private struct PhotoCard: View {
    let imageName: String
    let badgeFill: Color
    let badgeTint: Color
    var badgeAtBottom = false

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 160, height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white, lineWidth: 6)
            }
            .shadow(color: Color.rose.opacity(0.2), radius: 16, y: 8)
            .overlay(alignment: badgeAtBottom ? .bottomTrailing : .topTrailing) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(badgeTint)
                    .frame(width: 56, height: 56)
                    .background {
                        Circle()
                            .fill(badgeFill)
                            .shadow(color: Color.rose.opacity(0.25), radius: 8, y: 4)
                    }
                    .offset(x: 20, y: badgeAtBottom ? 20 : -20)
            }
    }
}

/// Rose capsule ("Say hello") or white capsule with a blush border ("Keep trotting").
private struct MatchButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundStyle(filled ? Color.white : Color.rose)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(filled ? Color.rose : Color.white, in: Capsule())
            .overlay {
                Capsule().strokeBorder(filled ? Color.clear : Color.blush, lineWidth: 2)
            }
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

#Preview { MatchOverlayView(horse: Horse.samples[0]) {} }
