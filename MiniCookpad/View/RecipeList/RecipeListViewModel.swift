import Observation

@MainActor
@Observable
final class RecipeListViewModel {
    let store: RecipeStore
    private var recipes: [GetRecipeListResponse.Recipe] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    var items: [RecipeListItem] {
        recipes.map { .init(recipe: $0, hashtags: store.hashtagsByRecipeID[$0.id, default: []]) }
    }

    init(store: RecipeStore) { self.store = store }

    func request() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            recipes = try await store.loadRecipes()
            hasLoaded = true
        } catch {
            guard !(error is CancellationError), !Task.isCancelled else { return }
            errorMessage = "レシピを取得できませんでした。もう一度お試しください。"
        }
    }
}
