import Foundation

/// Be a horse.
struct Horse: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let age: Int
    let breed: String
    let bio: String
    let lookingFor: String
    let imageName: String
    let likesYouBack: Bool
}
