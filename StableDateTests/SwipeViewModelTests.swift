import Foundation
import Testing
@testable import stable_date

@MainActor
@Suite("SwipeViewModel")
struct SwipeViewModelTests {

    private func makeVM(_ result: Result<[Horse], any Error>) -> SwipeViewModel {
        SwipeViewModel(service: MockHorseService(result: result))
    }

    @Test func offlineShowsErrorNotInfiniteSpinner() async {
        let vm = makeVM(.failure(URLError(.notConnectedToInternet)))

        await vm.load()

        #expect(vm.state == .failed(Copy.errorTitle))
    }

    @Test func emptyResponseShowsEmptyState() async {
        let vm = makeVM(.success([]))

        await vm.load()

        #expect(vm.state == .empty)
    }

    @Test func likingAHorseThatLikesYouBackIsAMatch() async throws {
        let vm = makeVM(.success(Horse.samples))
        await vm.load()
        let crush = try #require(Horse.samples.first { $0.likesYouBack })

        let isMatch = vm.swipe(crush, liked: true)

        #expect(isMatch)
        #expect(vm.matches == [crush])
    }

    @Test func likingAHorseThatDoesNotLikeYouBackIsNotAMatch() async throws {
        let vm = makeVM(.success(Horse.samples))
        await vm.load()
        let stranger = try #require(Horse.samples.first { !$0.likesYouBack })

        let isMatch = vm.swipe(stranger, liked: true)

        #expect(!isMatch)
        #expect(vm.matches.isEmpty)
    }

    @Test func nopingNeverMatches() async throws {
        let vm = makeVM(.success(Horse.samples))
        await vm.load()
        let crush = try #require(Horse.samples.first { $0.likesYouBack })

        let isMatch = vm.swipe(crush, liked: false)

        #expect(!isMatch)
        #expect(vm.matches.isEmpty)
    }

    @Test func swipingTheLastHorseShowsEmptyState() async {
        let only = Horse.samples[0]
        let vm = makeVM(.success([only]))
        await vm.load()

        vm.swipe(only, liked: false)

        #expect(vm.state == .empty)
        #expect(vm.hasSwiped)
    }

    @Test func retryAfterFailureLoadsHorses() async {
        let vm = SwipeViewModel(service: FlakyHorseService(horses: Horse.samples))

        await vm.load()
        #expect(vm.state == .failed(Copy.errorTitle))

        await vm.load()
        #expect(vm.state == .loaded(Horse.samples))
    }

    @Test func samplesMatchJSON() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()          // StableDateTests/
            .deletingLastPathComponent()          // repo root
            .appending(path: "Data/horses.json")
        let decoded = try JSONDecoder().decode([Horse].self, from: Data(contentsOf: url))
        #expect(decoded == Horse.samples)
    }
}

/// Fails on the first call, succeeds after. Lives only in the test target.
private actor FlakyHorseService: HorseService {
    private var calls = 0
    private let horses: [Horse]

    init(horses: [Horse]) { self.horses = horses }

    func fetchHorses() async throws -> [Horse] {
        calls += 1
        if calls == 1 { throw URLError(.timedOut) }
        return horses
    }
}
