import Combine
import Foundation

public struct APIClient {
    var networkDispatcher: () -> NetworkDispatcher

    public init(networkDispatcher: @escaping () -> NetworkDispatcher) {
        self.networkDispatcher = networkDispatcher
    }

    /// Dispatches a Request and returns a Combine publisher
    public func dispatch<R: APIRequest>(_ request: R) -> AnyPublisher<Data, NetworkRequestError> {
        guard let urlRequest = try? request.makeRequest() else {
            return Fail(
                outputType: Data.self,
                failure: NetworkRequestError.badRequest
            )
            .eraseToAnyPublisher()
        }
        return networkDispatcher()
            .dispatch(request: urlRequest)
            .eraseToAnyPublisher()
    }

    /// Dispatches a Request asynchronously using async/await
    public func dispatchAsync<R: APIRequest>(_ request: R) async throws -> Data {
        guard let urlRequest = try? request.makeRequest() else {
            throw NetworkRequestError.badRequest
        }
        return try await networkDispatcher()
            .dispatchAsync(request: urlRequest)
    }
}
