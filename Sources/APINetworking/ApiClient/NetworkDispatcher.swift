import Combine
import Foundation

/// A client to dispatch network request to URLSession
public struct NetworkDispatcher {
    var urlSession: () -> URLSession

    public init(urlSession: @escaping () -> URLSession) {
        self.urlSession = urlSession
    }

    /// Dispatches a URLRequest and returns a Combine publisher
    public func dispatch(request: URLRequest) -> AnyPublisher<Data, NetworkRequestError> {
        return urlSession()
            .dataTaskPublisher(for: request)
            .tryMap { data, response in
                // Check for HTTP errors
                if let response = response as? HTTPURLResponse,
                   !(200...299).contains(response.statusCode) {
                    throw httpError(response.statusCode)
                }
                return data
            }
            .mapError { error in handleError(error) }
            .eraseToAnyPublisher()
    }

    /// Dispatches a URLRequest asynchronously using async/await
   public func dispatchAsync(request: URLRequest) async throws -> Data {
        let (data, response) = try await urlSession().data(for: request)

        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw httpError(httpResponse.statusCode)
        }

        return data
    }
}

public extension NetworkDispatcher {
    /// Dispatches a URLRequest and bridges to Combine using Future
    @MainActor func dispatchWithCombine(request: URLRequest) -> AnyPublisher<Data, NetworkRequestError> {
        Future { promise in
            Task {
                do {
                    let data = try await self.dispatchAsync(request: request)
                    promise(.success(data))
                } catch let error as NetworkRequestError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknownError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension NetworkDispatcher {
  /// Parses a HTTP StatusCode and returns a proper error
  /// - Parameter statusCode: HTTP status code
  /// - Returns: Mapped Error
  private func httpError(_ statusCode: Int) -> NetworkRequestError {
    switch statusCode {
    case 400: return .badRequest
    case 403: return .forbidden
    case 404: return .notFound
    case 402, 405...499: return .error4xx(statusCode)
    case 500: return .serverError
    case 501...599: return .error5xx(statusCode)
    default: return .unknownError
    }
  }
  /// Parses URLSession Publisher errors and return proper ones
  /// - Parameter error: URLSession publisher error
  /// - Returns: Readable NetworkRequestError
  private func handleError(_ error: Error) -> NetworkRequestError {
    switch error {
    case is Swift.DecodingError:
      return .decodingError
    case let urlError as URLError:
      return .urlSessionFailed(urlError)
    case let error as NetworkRequestError:
      return error
    default:
      return .unknownError
    }
  }
}

