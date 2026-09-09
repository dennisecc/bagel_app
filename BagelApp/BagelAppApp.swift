import SwiftUI
import SwiftData

@main
struct BagelAppApp: App {
    let modelContainer = ModelContainerFactory.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(modelContainer)
    }
}
