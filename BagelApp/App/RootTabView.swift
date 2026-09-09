import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem { Label("Capture", systemImage: "doc.text.viewfinder") }

            ExpenseListView()
                .tabItem { Label("Expenses", systemImage: "receipt") }

            BalancesView()
                .tabItem { Label("Balances", systemImage: "arrow.left.arrow.right") }

            InsightsDashboardView()
                .tabItem { Label("Insights", systemImage: "chart.pie") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
