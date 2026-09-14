import Observation

@MainActor
@Observable
final class RecipeDetailViewModel {
    let store: RecipeStore
    let recipeID: Int64
    private var recipe: GetRecipeDetailResponse.Recipe?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var recipeDetailItem: RecipeDetailItem? {
        recipe.map { .init(recipe: $0, hashtags: store.hashtagsByRecipeID[recipeID, default: []]) }
    }

    init(recipeID: Int64, store: RecipeStore) {
        self.recipeID = recipeID
        self.store = store
    }

    func request() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            recipe = try await store.loadRecipe(id: recipeID)
        } catch {
            guard !(error is CancellationError), !Task.isCancelled else { return }
            errorMessage = "レシピを取得できませんでした。もう一度お試しください。"
        }
    }
}
