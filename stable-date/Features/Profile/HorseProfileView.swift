import SwiftUI

/// The detail screen. Takes one Horse and draws it. No service, no ViewModel, no network.
struct HorseProfileView: View {
    let horse: Horse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HorseCardView(horse: horse)
                Text("\(Copy.age(horse.age)) · \(horse.breed)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.inkSecondary)
                Text(horse.bio)
                    .font(.body)
                    .foregroundStyle(Color.ink)
                VStack(alignment: .leading, spacing: 4) {
                    Text(Copy.profileLookingFor)
                        .font(.headline)
                        .foregroundStyle(Color.rose)
                    Text(horse.lookingFor)
                        .font(.body)
                        .foregroundStyle(Color.ink)
                }
            }
            .padding(24)
        }
        .background(Color.appBackground)
        .presentationDragIndicator(.visible)
    }
}

#Preview { HorseProfileView(horse: Horse.samples[0]) }
