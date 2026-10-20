import SwiftUI

/// No horses: either the server sent none, or you swiped them all.
struct EmptyDeckView: View {
    let exhausted: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image("horse-02")
                .resizable()
                .scaledToFill()
                .frame(width: 180, height: 180)
                .background(Color.photoLavender)
                .clipShape(Circle())
                .accessibilityHidden(true)
                .padding(.bottom, 8)
            Text(exhausted ? Copy.emptyExhaustedTitle : Copy.emptyNoDataTitle)
                .font(.title.bold())
                .foregroundStyle(Color.ink)
            Text(exhausted ? Copy.emptyExhaustedBody : Copy.emptyNoDataBody)
                .font(.title3)
                .foregroundStyle(Color.inkSecondary)
            Button(action: onRetry) {
                Text(exhausted ? Copy.emptyExhaustedButton : Copy.emptyNoDataButton)
                    .font(.headline)
                    .foregroundStyle(Color.rose)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(Color.blush, in: Capsule())
                    .overlay { Capsule().strokeBorder(Color.rose.opacity(0.35), lineWidth: 1) }
            }
            .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }
}

#Preview("No data")   { EmptyDeckView(exhausted: false) {} }
#Preview("Exhausted") { EmptyDeckView(exhausted: true) {} }
