import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("People") { PeopleListView() }
                NavigationLink("Categories") { ManageCategoriesView() }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
