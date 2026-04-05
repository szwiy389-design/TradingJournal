import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }

            TradeListView()
                .tabItem {
                    Label("Trades", systemImage: "list.bullet.rectangle")
                }

            JournalListView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }

            AtlasView()
                .tabItem {
                    Label("Atlas", systemImage: "brain.head.profile")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Trade.self, DailyJournal.self], inMemory: true)
}
