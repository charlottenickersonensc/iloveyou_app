import Foundation

public protocol CallableFunctionsClient {
    func call<Response: Decodable>(_ name: String, payload: [String: Any]) async throws -> Response
}
