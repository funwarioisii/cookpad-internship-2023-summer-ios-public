import Foundation
import Testing
@testable import MiniCookpad

@MainActor
struct MiniCookpadTests {
    @Test(arguments: [
        ("　＃夕食　#簡単\n", "#夕食 #簡単"),
        ("\n #朝食 \n", "#朝食"),
        ("　\n ", ""),
        ("#そのまま", "#そのまま")
    ])
    func normalizesInput(input: String, expected: String) {
        #expect(AddRecipeHashtagsViewModel.normalize(input) == expected)
    }

    @Test func encodesTypedPostBody() throws {
        let request = try PostRecipeHashtagsRequest(recipeID: 42, value: "#夕食").makeURLRequest()
        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["recipe_id"] as? Int == 42)
        #expect(json["value"] as? String == "#夕食")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func joinsTagsByIDAndKeepsRecipesWithoutTags() async {
        let client = TestClient()
        client.recipes = [recipe(1), recipe(2), recipe(3)]
        client.tags = [.init(recipeId: 2, hashtags: [.init(id: 20, name: "二")]),
                       .init(recipeId: 1, hashtags: [.init(id: 10, name: "一")])]
        let model = RecipeListViewModel(store: RecipeStore(client: client))
        await model.request()
        #expect(model.items.map(\.id) == [1, 2, 3])
        #expect(model.items.map { $0.hashtags.map(\.name) } == [["一"], ["二"], []])
    }

    @Test func emptyListDoesNotRequestTags() async {
        let client = TestClient()
        client.recipes = []
        let model = RecipeListViewModel(store: RecipeStore(client: client))
        await model.request()
        #expect(client.tagRequests == 0)
        #expect(model.hasLoaded && model.items.isEmpty)
        #expect(model.errorMessage == nil)
    }

    @Test func failedLoadCanBeRetried() async {
        let client = TestClient()
        let model = RecipeListViewModel(store: RecipeStore(client: client))
        client.shouldFail = true
        await model.request()
        #expect(model.errorMessage != nil)
        #expect(!model.isLoading)
        client.shouldFail = false
        await model.request()
        #expect(model.errorMessage == nil)
        #expect(model.items.count == 1)
    }

    @Test func cancelledLoadDoesNotPublishLateResults() async {
        let client = TestClient()
        let gate = Gate()
        client.getGate = gate
        let model = RecipeListViewModel(store: RecipeStore(client: client))
        let task = Task { await model.request() }
        await gate.waitUntilEntered()
        task.cancel()
        // キャンセルを無視して応答するAPIでも、Storeが結果の適用を防ぐ。
        gate.release()
        await task.value
        #expect(model.items.isEmpty)
        #expect(model.errorMessage == nil)
        #expect(!model.isLoading)
    }

    @Test func savingUpdatesListAndDetailWithoutRefetching() async throws {
        let client = TestClient()
        let store = RecipeStore(client: client)
        let list = RecipeListViewModel(store: store)
        let detail = RecipeDetailViewModel(recipeID: 1, store: store)
        await list.request()
        await detail.request()
        let requestsBefore = client.tagRequests
        try await store.addHashtags(recipeID: 1, value: "#新規")
        try await store.addHashtags(recipeID: 1, value: "#新規")
        #expect(list.items.first?.hashtags.map(\.name) == ["既存", "新規"])
        #expect(detail.recipeDetailItem?.hashtags.map(\.name) == ["既存", "新規"])
        #expect(client.tagRequests == requestsBefore)
    }

    @Test func staleGetCannotOverwriteSuccessfulPost() async throws {
        let client = TestClient()
        let store = RecipeStore(client: client)
        _ = try await store.loadRecipes()
        let gate = Gate()
        client.getGate = gate
        let load = Task { try await store.loadRecipes() }
        await gate.waitUntilEntered()
        try await store.addHashtags(recipeID: 1, value: "#新規")
        gate.release()
        _ = try await load.value
        #expect(store.hashtagsByRecipeID[1]?.map(\.name) == ["既存", "新規"])
    }

    @Test func savePreventsDoubleSubmissionAndPreservesFailedInput() async {
        let client = TestClient()
        let model = AddRecipeHashtagsViewModel(recipeID: 1, store: RecipeStore(client: client))
        model.text = "　＃新規　"
        let gate = Gate()
        client.postGate = gate
        let first = Task { await model.save() }
        await gate.waitUntilEntered()
        #expect(model.isSaving && !model.canSave)
        let second = await model.save()
        #expect(!second)
        #expect(client.postRequests == 1)
        gate.release()
        #expect(await first.value)
        client.postGate = nil
        client.shouldFail = true
        let failed = await model.save()
        #expect(!failed)
        #expect(model.text == "　＃新規　")
        #expect(model.errorMessage != nil)
        #expect(model.canSave)
        client.shouldFail = false
        #expect(await model.save())
    }

    @Test func blankInputDoesNotSendPost() async {
        let client = TestClient()
        let model = AddRecipeHashtagsViewModel(recipeID: 1, store: RecipeStore(client: client))
        model.text = "　\n"
        #expect(!model.canSave)
        #expect(await model.save() == false)
        #expect(client.postRequests == 0)
    }

    @Test func stubRoundTripKeepsRecipeIdentityAndTags() async throws {
        let store = RecipeStore(client: StubAPIClient(delay: .zero))
        let recipes = try await store.loadRecipes()
        let id = try #require(recipes.first?.id)
        let detail = try await store.loadRecipe(id: id)
        #expect(detail.id == id)
        #expect(detail.title == recipes.first?.title)
        try await store.addHashtags(recipeID: id, value: "#テスト追加")
        _ = try await store.loadRecipe(id: id)
        #expect(store.hashtagsByRecipeID[id]?.contains(where: { $0.name == "テスト追加" }) == true)
    }
}

private func recipe(_ id: Int64) -> GetRecipeListResponse.Recipe {
    .init(id: id, title: "レシピ\(id)", description: "", imageUrl: nil,
          user: .init(name: "作者"), ingredients: [])
}

@MainActor
private final class TestClient: APIClient {
    var recipes = [recipe(1)]
    var tags: [GetRecipeHashtagsResponse.RecipeHashtag] = [
        .init(recipeId: 1, hashtags: [.init(id: 1, name: "既存")])
    ]
    var shouldFail = false
    var tagRequests = 0
    var postRequests = 0
    var getGate: Gate?
    var postGate: Gate?

    func send<Request: APIRequest>(request: Request) async throws -> Request.Response {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        let response: Any
        switch request {
        case is GetRecipeListRequest:
            response = GetRecipeListResponse(recipes: recipes)
        case is GetRecipeHashtagsRequest:
            tagRequests += 1
            response = GetRecipeHashtagsResponse(recipeHashtags: tags)
            await getGate?.pause()
        case is GetRecipeDetailRequest:
            response = GetRecipeDetailResponse(recipe: .mock)
        case is PostRecipeHashtagsRequest:
            postRequests += 1
            await postGate?.pause()
            response = PostRecipeHashtagsResponse(hashtags: [.init(id: 2, name: "新規")])
        default:
            throw URLError(.unsupportedURL)
        }
        return try #require(response as? Request.Response)
    }
}

/// sleepでタイミングを推測せず、テスト側から応答の順番を制御する。
@MainActor
private final class Gate {
    private var entered = false
    private var isOpen = false
    private var entryWaiter: CheckedContinuation<Void, Never>?
    private var waiter: CheckedContinuation<Void, Never>?

    func pause() async {
        entered = true
        entryWaiter?.resume()
        entryWaiter = nil
        if !isOpen { await withCheckedContinuation { waiter = $0 } }
    }

    func waitUntilEntered() async {
        if !entered { await withCheckedContinuation { entryWaiter = $0 } }
    }

    func release() {
        isOpen = true
        waiter?.resume()
        waiter = nil
    }
}
