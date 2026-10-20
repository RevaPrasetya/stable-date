import Foundation
import Observation

@MainActor @Observable
final class SwipeViewModel {
    var horses: [Horse] = []
    var isLoading = true
    var errorMessage: String?               // 👀 remember these three
    private(set) var matches: [Horse] = []

    private let service = LiveHorseService() // 👀 remember this too

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            horses = try await service.fetchHorses()
        } catch {
            errorMessage = "The horses ran away. 🐎💨"
        }
        isLoading = false
    }

    /// Returns true if it's a match.
    func swipe(_ horse: Horse, liked: Bool) -> Bool {
        horses.removeAll { $0.id == horse.id }
        guard liked, horse.likesYouBack else { return false }
        matches.append(horse)
        return true
    }
}
