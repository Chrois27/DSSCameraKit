//
//  DSSCameraClient.swift
//  DSSCameraKit
//
//  Created by Chris Choi.
//

import Foundation

/// Issues PTZ (pan/tilt/zoom) commands to a camera channel over the VMS HTTP API.
///
/// Completion handlers are always invoked on the main thread.
public final class DSSCameraClient {

    private let store: DSSSessionStore
    private let session: URLSession
    private let acceptLanguage: String

    public init(store: DSSSessionStore, acceptLanguage: String = "en", session: URLSession? = nil) {
        self.store = store
        self.acceptLanguage = acceptLanguage
        self.session = session ?? DSSURLSession.make(trustedHost: store.trustedHost)
    }

    /// Opens the TCP+TLS connection ahead of the first command so the initial
    /// PTZ tap feels instant. Result is intentionally ignored.
    public func warmUp() {
        var req = URLRequest(url: store.serverURL)
        req.httpMethod = "HEAD"
        session.dataTask(with: req) { _, _, _ in }.resume()
    }

    public func move(_ direction: PTZDirection, _ action: PTZAction, completion: @escaping (PTZResult) -> Void) {
        guard let req = DSSRequestFactory.ptzDirect(
            server: store.serverURL, token: store.token, channelId: store.channelId,
            direction: direction, action: action, acceptLanguage: acceptLanguage
        ) else { return main(completion, .networkError("Invalid request configuration")) }
        perform(req, completion)
    }

    public func zoom(_ zoom: PTZZoom, _ action: PTZAction, completion: @escaping (PTZResult) -> Void) {
        guard let req = DSSRequestFactory.ptzZoom(
            server: store.serverURL, token: store.token, channelId: store.channelId,
            zoom: zoom, action: action, acceptLanguage: acceptLanguage
        ) else { return main(completion, .networkError("Invalid request configuration")) }
        perform(req, completion)
    }

    // MARK: - Private

    private func perform(_ req: URLRequest, _ completion: @escaping (PTZResult) -> Void) {
        session.dataTask(with: req) { data, _, error in
            if let error {
                return self.main(completion, .networkError(error.localizedDescription))
            }
            guard let data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return self.main(completion, .networkError("Invalid response"))
            }
            self.main(completion, DSSResponseMapper.mapPTZ(json))
        }.resume()
    }

    private func main(_ completion: @escaping (PTZResult) -> Void, _ result: PTZResult) {
        DispatchQueue.main.async { completion(result) }
    }
}
