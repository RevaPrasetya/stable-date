import SwiftUI

/// Draws one horse. That's it.
struct HorseCardView: View {
    let horse: Horse

    // Decorative chips, computed from age only (never from likesYouBack).
    private var distanceKm: Int { horse.age % 4 + 1 }
    private var matchPercent: Int { 70 + (horse.age * 7) % 29 }

    var body: some View {
        Color.photoPink
            .aspectRatio(3/4, contentMode: .fit)
            .overlay { photo }
            .overlay(alignment: .bottomLeading) { caption }
            .overlay(alignment: .top) { chips }
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Color.rose.opacity(0.18), radius: 20, y: 10)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(horse.name), \(horse.age) years, \(horse.breed)")
            // The card is a photo: it looks the same in light and dark mode.
            .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    private var photo: some View {
        if UIImage(named: horse.imageName) != nil {
            Image(horse.imageName)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "hare")
                .font(.system(size: 96))
                .foregroundStyle(Color.ink.opacity(0.4))
        }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(horse.name), \(horse.age)")
                .font(.title.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text("\(horse.breed) · \(horse.bio)")
                .font(.subheadline)
                .lineLimit(1)
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(.leading, 24)
        .padding(.trailing, 72)
        .padding(.top, 72)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(colors: [.clear, Color.ink.opacity(0.7)], startPoint: .top, endPoint: .bottom)
        }
    }

    private var chips: some View {
        HStack {
            Label("\(distanceKm) km", systemImage: "mappin")
                .foregroundStyle(Color.ink)
            Spacer()
            Label("\(matchPercent)%", systemImage: "heart.fill")
                .foregroundStyle(Color.lavender)
        }
        .font(.subheadline.bold())
        .labelStyle(ChipLabelStyle())
        .padding(16)
    }
}

// MARK: - Subviews

private struct ChipLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon
            configuration.title
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .background(Color.white.opacity(0.5), in: Capsule())
    }
}
