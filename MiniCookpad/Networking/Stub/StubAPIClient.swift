import Foundation

/// 外部サーバーなしで、取得とタグ追加の往復を試せるインメモリAPI。
@MainActor
final class StubAPIClient: APIClient {
    enum Scenario { case success, empty, failure }
    private let fixtureLoader = FixtureLoader()
    private let scenario: Scenario
    private let delay: Duration
    private var tags: [Int64: [Hashtag]]
    private var nextTagID: Int64 = 100

    init(scenario: Scenario = .success, delay: Duration = .milliseconds(300)) {
        self.scenario = scenario
        self.delay = delay
        let initial: GetRecipeHashtagsResponse = fixtureLoader.decodeObject(fromJSONNamed: "get_recipe_list_hashtags")
        tags = Dictionary(uniqueKeysWithValues: initial.recipeHashtags.map { ($0.recipeId, $0.hashtags) })
    }

    func send<Request: APIRequest>(request: Request) async throws -> Request.Response {
        try await Task.sleep(for: delay)
        if scenario == .failure { throw URLError(.notConnectedToInternet) }
        let response: Any
        switch request {
        case is GetRecipeListRequest:
            let list: GetRecipeListResponse = fixtureLoader.decodeObject(fromJSONNamed: "get_recipe_list")
            response = scenario == .empty ? GetRecipeListResponse(recipes: []) : list
        case let request as GetRecipeHashtagsRequest:
            response = GetRecipeHashtagsResponse(recipeHashtags: request.recipeIds.map {
                .init(recipeId: $0, hashtags: tags[$0, default: []])
            })
        case let request as GetRecipeDetailRequest:
            let template: GetRecipeDetailResponse = fixtureLoader.decodeObject(fromJSONNamed: "get_recipe_detail")
            let list: GetRecipeListResponse = fixtureLoader.decodeObject(fromJSONNamed: "get_recipe_list")
            guard let recipe = list.recipes.first(where: { $0.id == request.recipeId }) else {
                throw URLError(.resourceUnavailable)
            }
            response = GetRecipeDetailResponse(recipe: .init(
                id: recipe.id, title: recipe.title, description: recipe.description,
                imageUrl: recipe.imageUrl, user: .init(name: recipe.user.name, imageUrl: nil),
                ingredients: template.recipe.ingredients, steps: template.recipe.steps
            ))
        case let request as PostRecipeHashtagsRequest:
            var created: [Hashtag] = []
            for word in request.value.split(whereSeparator: { $0.isWhitespace }) {
                let name = String(word.drop(while: { $0 == "#" }))
                guard !name.isEmpty else { continue }
                if let existing = tags[request.recipeID, default: []].first(where: { $0.name == name }) {
                    created.append(existing)
                } else {
                    let tag = Hashtag(id: nextTagID, name: name)
                    nextTagID += 1
                    tags[request.recipeID, default: []].append(tag)
                    created.append(tag)
                }
            }
            response = PostRecipeHashtagsResponse(hashtags: created)
        default:
            throw APIClientError.requestError(.invalidURL(description: "No matching stub"))
        }
        guard let typed = response as? Request.Response else {
            throw APIClientError.requestError(.invalidURL(description: "Stub response type mismatch"))
        }
        return typed
    }
}
