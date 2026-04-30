import Foundation

@MainActor
final class StatsState: ObservableObject {
    @Published var snapshot: StatsSnapshot

    init(snapshot: StatsSnapshot = .placeholder) {
        self.snapshot = snapshot
    }
}
