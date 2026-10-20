import Foundation

/// Fetches horses from the internet. The only type in the app that knows a URL exists.
struct LiveHorseService: HorseService {
    static var defaultURL: URL {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["STABLE_DATE_URL"],
           let url = URL(string: override) {
            return url
        }
        #endif
        return URL(string: "https://raw.githubusercontent.com/revaprasetya/stable-date/main/Data/horses.json")!
    }

    var url: URL = Self.defaultURL
    var session: URLSession = .shared

    func fetchHorses() async throws -> [Horse] {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([Horse].self, from: data)
    }
}
