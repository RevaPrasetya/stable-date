import Foundation

/// Fake horses. A test double: we decide exactly what it returns.
struct MockHorseService: HorseService {
    var result: Result<[Horse], any Error>
    var delay: Duration = .zero

    func fetchHorses() async throws -> [Horse] {
        if delay > .zero { try await Task.sleep(for: delay) }
        return try result.get()
    }
}
