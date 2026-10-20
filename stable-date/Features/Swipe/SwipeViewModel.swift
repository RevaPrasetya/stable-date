import Foundation
import Observation

/// Decides. Owns the screen's one and only state.
@MainActor @Observable
final class SwipeViewModel {

    enum State: Equatable {
        case loading
        case loaded([Horse])
        case empty
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var matches: [Horse] = []
    private(set) var hasSwiped = false

    private let service: any HorseService

    init(service: any HorseService) {
        self.service = service
    }

    func load() async {
        state = .loading
        hasSwiped = false
        do {
            let horses = try await service.fetchHorses()
            state = horses.isEmpty ? .empty : .loaded(horses)
        } catch {
            state = .failed(Copy.errorTitle)
        }
    }

    /// Removes the horse from the deck. Returns `true` if it's a match.
    @discardableResult
    func swipe(_ horse: Horse, liked: Bool) -> Bool {
        guard case .loaded(var deck) = state else { return false }
        deck.removeAll { $0.id == horse.id }
        state = deck.isEmpty ? .empty : .loaded(deck)
        hasSwiped = true

        guard liked, horse.likesYouBack else { return false }
        matches.append(horse)
        return true
    }
}
