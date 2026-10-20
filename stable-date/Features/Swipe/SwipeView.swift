import SwiftUI

/// Draws the screen for whatever state the ViewModel is in. Nothing else.
struct SwipeView: View {
    @State private var viewModel: SwipeViewModel
    @State private var presentedHorse: Horse?
    @State private var matchedHorse: Horse?

    init(viewModel: SwipeViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            DiscoverHeader()
            screen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            StableTabBar(matchCount: viewModel.matches.count)
        }
        .background { Color.appBackground.ignoresSafeArea() }
        .task { await viewModel.load() }
        .sheet(item: $presentedHorse) { HorseProfileView(horse: $0) }
        .overlay {
            if let horse = matchedHorse {
                MatchOverlayView(horse: horse) { matchedHorse = nil }
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .animation(.spring(duration: 0.4), value: matchedHorse)
    }

    // MARK: - Screen

    /// One branch per state. The compiler makes sure none is forgotten.
    @ViewBuilder
    private var screen: some View {
        switch viewModel.state {
        case .loading:
            LoadingView()
        case .loaded(let horses):
            CardStackView(horses: horses, onSwipe: { handleSwipe($0, liked: $1) }, onTap: { presentedHorse = $0 })
        case .empty:
            EmptyDeckView(exhausted: viewModel.hasSwiped) { Task { await viewModel.load() } }
        case .failed(let message): ErrorView(message: message) { Task { await viewModel.load() } }
        }
    }

    // MARK: - Actions

    private func handleSwipe(_ horse: Horse, liked: Bool) {
        if viewModel.swipe(horse, liked: liked) {
            matchedHorse = horse
        }
    }
}
