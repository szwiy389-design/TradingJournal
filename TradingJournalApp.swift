import SwiftUI
import SwiftData

@main
struct TradingJournalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Trade.self, DailyJournal.self])
    }
}
