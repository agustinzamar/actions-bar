import AppKit
import Combine
import Foundation

/// Implements GitHub's OAuth Device Flow.
/// https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps#device-flow
enum DeviceFlowError: Error, LocalizedError {
    case server(String)
    var errorDescription: String? {
        switch self {
        case let .server(body): "GitHub rejected the request: \(body)"
        }
    }
}

struct DeviceCodeInfo: Equatable {
    let userCode: String
    let verificationURL: URL
}

@MainActor
final class DeviceFlowAuth: ObservableObject {
    enum State: Equatable {
        case idle
        case polling
        case success
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    /// Kept separate from `state` so the code stays on screen for the whole
    /// polling phase instead of being replaced the instant polling starts.
    @Published private(set) var codeInfo: DeviceCodeInfo?

    private struct DeviceCodeResponse: Decodable {
        let deviceCode: String
        let userCode: String
        let verificationUri: String
        let expiresIn: Int
        let interval: Int
        enum CodingKeys: String, CodingKey {
            case deviceCode = "device_code"
            case userCode = "user_code"
            case verificationUri = "verification_uri"
            case expiresIn = "expires_in"
            case interval
        }
    }

    private struct TokenResponse: Decodable {
        let accessToken: String?
        let error: String?
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case error
        }
    }

    func start() {
        guard Config.clientID != "REPLACE_WITH_YOUR_CLIENT_ID", !Config.clientID.isEmpty else {
            state = .failed("Set your GitHub OAuth Client ID in Config.swift first")
            return
        }
        state = .idle
        codeInfo = nil
        Task {
            do {
                let device = try await requestDeviceCode()
                guard let url = URL(string: device.verificationUri) else {
                    state = .failed("Bad verification URL")
                    return
                }
                codeInfo = DeviceCodeInfo(userCode: device.userCode, verificationURL: url)
                copyToPasteboard(device.userCode)
                state = .polling
                NSWorkspace.shared.open(url)
                try await poll(deviceCode: device.deviceCode, interval: device.interval, expiresIn: device.expiresIn)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func copyToPasteboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    private func requestDeviceCode() async throws -> DeviceCodeResponse {
        var request = URLRequest(url: URL(string: "https://github.com/login/device/code")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "client_id=\(Config.clientID)&scope=\(Config.oauthScope)".data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw DeviceFlowError.server(body)
        }
        return try JSONDecoder().decode(DeviceCodeResponse.self, from: data)
    }

    private func poll(deviceCode: String, interval: Int, expiresIn: Int) async throws {
        let deadline = Date().addingTimeInterval(TimeInterval(expiresIn))
        var currentInterval = interval

        while Date() < deadline {
            try await Task.sleep(nanoseconds: UInt64(currentInterval) * 1_000_000_000)

            var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            let body = "client_id=\(Config.clientID)&device_code=\(deviceCode)"
                + "&grant_type=urn:ietf:params:oauth:grant-type:device_code"
            request.httpBody = body.data(using: .utf8)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TokenResponse.self, from: data)

            if let token = response.accessToken {
                KeychainStore.save(token: token)
                state = .success
                return
            }

            switch response.error {
            case "authorization_pending":
                continue
            case "slow_down":
                currentInterval += 5
                continue
            default:
                state = .failed(response.error ?? "Unknown error")
                return
            }
        }
        state = .failed("Device code expired, try again")
    }
}
