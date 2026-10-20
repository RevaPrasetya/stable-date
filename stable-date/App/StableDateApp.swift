import SwiftUI

@main
struct StableDateApp: App {
    var body: some Scene {
        WindowGroup {
            SwipeView(viewModel: SwipeViewModel())
        }
    }
}
