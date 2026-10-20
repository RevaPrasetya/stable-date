import SwiftUI

@main
struct StableDateApp: App {
    var body: some Scene {
        WindowGroup {
            SwipeView(viewModel: SwipeViewModel(service: Self.makeService()))
        }
    }

    /// The composition root: the only place in the app that knows which `HorseService` is real.
    /// Launch arguments let rehearsals and screenshot scripts pick a fake without touching any other file.
    private static func makeService() -> any HorseService {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--mock-loaded")  { return MockHorseService(result: .success(Horse.samples)) }
        if args.contains("--mock-empty")   { return MockHorseService(result: .success([])) }
        if args.contains("--mock-failed")  { return MockHorseService(result: .failure(URLError(.notConnectedToInternet))) }
        if args.contains("--mock-loading") { return MockHorseService(result: .success([]), delay: .seconds(999)) }
        return LiveHorseService()
    }
}
