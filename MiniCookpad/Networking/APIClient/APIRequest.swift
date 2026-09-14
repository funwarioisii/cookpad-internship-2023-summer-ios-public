import Foundation

protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable
    var url: URL { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    func makeBody() throws -> Data?
    func makeURLRequest() throws -> URLRequest
    func makeResponse(from data: Data, urlResponse: HTTPURLResponse) throws -> Response
}

enum APIRequestError: Error {
    case serializationError(Error)
    case invalidURL(description: String)
    case unknownError(Error)
}

extension APIRequest {
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem] { [] }
    func makeBody() throws -> Data? { nil }

    func makeURLRequest() throws -> URLRequest {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw APIRequestError.invalidURL(description: "Invalid URL")
        }
        if method.prefersQueryParameters && !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIRequestError.invalidURL(description: "Invalid query parameters")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if !method.prefersQueryParameters {
            do {
                request.httpBody = try makeBody()
            } catch {
                throw APIRequestError.serializationError(error)
            }
            if request.httpBody != nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        return request
    }

    func makeResponse(from data: Data, urlResponse: HTTPURLResponse) throws -> Response {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Response.self, from: data)
    }
}
