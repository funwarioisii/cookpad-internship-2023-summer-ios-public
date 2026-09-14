import SwiftUI

struct RecipeListView: View {
    @State private var viewModel: RecipeListViewModel

    init(store: RecipeStore) {
        _viewModel = State(initialValue: RecipeListViewModel(store: store))
    }

    var body: some View {
        List(viewModel.items) { item in
            NavigationLink {
                RecipeDetailView(recipeID: item.id, store: viewModel.store)
            } label: {
                RecipeListRow(item: item)
            }
            .accessibilityIdentifier("recipeRow-\(item.id)")
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.items.isEmpty {
                if viewModel.isLoading {
                    ProgressView("読み込み中")
                } else if let message = viewModel.errorMessage {
                    ContentUnavailableView("取得できませんでした", systemImage: "wifi.exclamationmark",
                                           description: Text(message))
                } else if viewModel.hasLoaded {
                    ContentUnavailableView("レシピがありません", systemImage: "fork.knife")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let message = viewModel.errorMessage {
                VStack {
                    Text(message).font(.callout)
                    Button("再試行") { Task { await viewModel.request() } }
                        .buttonStyle(.bordered)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
            }
        }
        .task { await viewModel.request() }
        .refreshable { await viewModel.request() }
        .navigationTitle("レシピ一覧")
    }
}

#Preview {
    NavigationStack {
        RecipeListView(store: RecipeStore(client: StubAPIClient()))
    }
}
