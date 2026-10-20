import SwiftUI

/// A shimmering card-shaped placeholder, a rose spinner, and the copy.
struct LoadingView: View {
    @State private var shimmer = false

    var body: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(Color.blush.opacity(0.7))
            .aspectRatio(3/4, contentMode: .fit)
            .overlay {
                LinearGradient(colors: [.clear, .white.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing)
                    .rotationEffect(.degrees(20))
                    .offset(x: shimmer ? 400 : -400)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            }
            .overlay {
                VStack(spacing: 20) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(Color.rose)
                    Text("Rounding up horses...")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.ink)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxHeight: .infinity, alignment: .top)
            .onAppear {
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) { shimmer = true }
            }
    }
}

#Preview { LoadingView().background(Color.appBackground) }
