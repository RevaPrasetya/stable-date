/// The promise: give me horses, or throw.
protocol HorseService: Sendable {
    func fetchHorses() async throws -> [Horse]
}
