import SwiftUI

@main
struct MiniCookpadApp: App {
    @State private var store = RecipeStore(
        client: ProcessInfo.processInfo.useStubAPIClient
            ? StubAPIClient() : MiniCookpadAPIClient()
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RecipeListView(store: store)
            }
            .tint(.orange)
        }
    }
}
