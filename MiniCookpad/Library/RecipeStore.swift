import Foundation
import Observation

/// 一覧・詳細が同じレシピIDのタグを参照する、画面をまたぐ状態の所有者。
@MainActor
@Observable
final class RecipeStore {
    private(set) var hashtagsByRecipeID: [Int64: [Hashtag]] = [:]
    private let client: any APIClient
    @ObservationIgnored private var revisions: [Int64: Int] = [:]

    init(client: any APIClient) {
        self.client = client
    }

    func loadRecipes() async throws -> [GetRecipeListResponse.Recipe] {
        let response = try await client.send(request: GetRecipeListRequest())
        try Task.checkCancellation()
        let ids = response.recipes.map(\.id)
        guard !ids.isEmpty else { return [] }
        let before = revisions
        let tags = try await client.send(request: GetRecipeHashtagsRequest(recipeIds: ids))
        try Task.checkCancellation()
        apply(tags, for: ids, revisionsBeforeRequest: before)
        return response.recipes
    }

    func loadRecipe(id: Int64) async throws -> GetRecipeDetailResponse.Recipe {
        let before = revisions
        // 互いの結果を必要としない2つのGETは、子タスクで並行して待てる。
        async let detail = client.send(request: GetRecipeDetailRequest(recipeId: id))
        async let tags = client.send(request: GetRecipeHashtagsRequest(recipeIds: [id]))
        let (detailResponse, tagsResponse) = try await (detail, tags)
        try Task.checkCancellation()
        apply(tagsResponse, for: [id], revisionsBeforeRequest: before)
        return detailResponse.recipe
    }

    func addHashtags(recipeID: Int64, value: String) async throws {
        let response = try await client.send(
            request: PostRecipeHashtagsRequest(recipeID: recipeID, value: value)
        )
        // POSTが成功したら、画面の寿命によらず共有状態へ反映する。
        var tags = hashtagsByRecipeID[recipeID, default: []]
        for tag in response.hashtags {
            if let index = tags.firstIndex(where: { $0.id == tag.id }) {
                tags[index] = tag
            } else {
                tags.append(tag)
            }
        }
        hashtagsByRecipeID[recipeID] = tags
        revisions[recipeID, default: 0] += 1
    }

    private func apply(
        _ response: GetRecipeHashtagsResponse,
        for ids: [Int64],
        revisionsBeforeRequest: [Int64: Int]
    ) {
        // 返却順や件数に依存せずIDで結合する。欠けたレシピのタグは空として扱う。
        for id in ids {
            // await中にPOSTが成功した場合、その前のGET結果で上書きしない。
            guard revisions[id, default: 0] == revisionsBeforeRequest[id, default: 0] else { continue }
            hashtagsByRecipeID[id] = response.recipeHashtags
                .filter { $0.recipeId == id }.flatMap(\.hashtags)
        }
    }
}
