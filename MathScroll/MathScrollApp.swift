import SwiftUI
import SwiftData

@main
struct MathScrollApp: App {
    var body: some Scene {
        WindowGroup {
            Text("MathScroll bootstrapping…")
        }
        .modelContainer(for: [], inMemory: true)
    }
}
