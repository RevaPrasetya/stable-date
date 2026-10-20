import Foundation

/// Every user-facing string in Stable Date. The jokes live here.
enum Copy {
    static let appName = "Stable Date"
    static let tagline = "Swipe right on your soulmare."

    static let discoverTitle = "Discover"
    static let discoverLocation = "Ubud, Bali"

    static let loadingTitle = "Rounding up horses..."

    static let emptyNoDataTitle = "No horses nearby."
    static let emptyNoDataBody = "Even horses have standards."
    static let emptyNoDataButton = "Try again"

    static let emptyExhaustedTitle = "You've seen every horse."
    static let emptyExhaustedBody = "Go touch grass. You're a horse, you'll enjoy it."
    static let emptyExhaustedButton = "Start over"

    static let errorTitle = "The horses ran away. 🐎💨"
    static let errorBody = "Check your connection and we'll round them up again."
    static let errorButton = "Try again"

    static let matchCaption = "CONGRATULATIONS"
    static let matchTitle = "It's a match!!"
    /// Markdown: the horse's name is bold.
    static func matchBody(name: String) -> String { "You and **\(name)** are now trotting together." }
    static let sayHelloButton = "Say hello"
    static let matchButton = "Keep trotting"

    static let nopeLabel = "Nope"
    static let superLikeLabel = "Super like"
    static let likeLabel = "Like"
    static let backLabel = "Back"
    static let filterLabel = "Filters"
    static let messagesLabel = "Messages"
    static let profileLabel = "Profile"

    static let profileLookingFor = "Looking for"
    static func age(_ years: Int) -> String { "\(years) years" }
    static func distance(_ km: Int) -> String { "\(km) km" }
    static func matchPercent(_ percent: Int) -> String { "\(percent)%" }
    static func matchesBadge(_ count: Int) -> String { "\(count) matches" }
}
