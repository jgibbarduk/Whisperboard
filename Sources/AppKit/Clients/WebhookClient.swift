import Common
import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - WebhookClient

struct WebhookClient {
  var send: @Sendable (URL, Transcription) async throws -> Void
}

// MARK: DependencyKey

extension WebhookClient: DependencyKey {
  static let liveValue = WebhookClient(
    send: { url, transcription in
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      request.httpBody = try encoder.encode(transcription)
      let (_, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw WebhookClientError.invalidResponse
      }
      guard (200 ..< 300).contains(httpResponse.statusCode) else {
        throw WebhookClientError.invalidStatusCode(httpResponse.statusCode)
      }
    }
  )

  static let testValue = WebhookClient(
    send: unimplemented(#"@Dependency(\.webhookClient).send"#)
  )
}

// MARK: - WebhookClientError

enum WebhookClientError: Error, LocalizedError {
  case invalidStatusCode(Int)
  case invalidResponse

  var errorDescription: String? {
    switch self {
    case let .invalidStatusCode(code):
      "Webhook returned HTTP \(code). Please check the URL and server configuration."
    case .invalidResponse:
      "Webhook returned an unexpected response. Please check the URL and try again."
    }
  }
}

// MARK: - DependencyValues

extension DependencyValues {
  var webhookClient: WebhookClient {
    get { self[WebhookClient.self] }
    set { self[WebhookClient.self] = newValue }
  }
}
