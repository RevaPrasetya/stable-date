import SwiftUI

/// The horses ran away. One button to round them up again.
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("🐎")
                .font(.system(size: 88))
                .frame(width: 180, height: 180)
                .background(Color.photoPeach, in: Circle())
                .accessibilityHidden(true)
                .padding(.bottom, 8)
            Text(message)
                .font(.title.bold())
                .foregroundStyle(Color.ink)
            Text("Check your connection and we'll round them up again.")
                .font(.title3)
                .foregroundStyle(Color.inkSecondary)
            Button(action: onRetry) {
                Text("Try again")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(Color.rose, in: Capsule())
            }
            .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }
}

#Preview { ErrorView(message: "The horses ran away. 🐎💨") {} }
