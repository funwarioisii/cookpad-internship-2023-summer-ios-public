import Foundation

struct PostRecipeHashtagsRequest: APIRequest {
    typealias Response = PostRecipeHashtagsResponse
    let url = URL(string: "https://localhost:3002/hashtags")!
    let method: HTTPMethod = .post
    let recipeID: Int64
    let value: String

    func makeBody() throws -> Data? {
        struct Body: Encodable {
            let recipe_id: Int64
            let value: String
        }
        return try JSONEncoder().encode(Body(recipe_id: recipeID, value: value))
    }
}

struct PostRecipeHashtagsResponse: Decodable, Sendable {
    let hashtags: [Hashtag]
}
