//
//  DSSKeepAliveClient.swift
//  DSSCameraKit
//
//  Created by Chris Choi.
//

import Foundation

/// Keeps a VMS session alive by periodically pinging `accounts/keepalive`, and
/// rotates the shared token whenever the server issues a new one.
///
/// Lifecycle: `start()` on screen appear, `stop()` on disappear, `fireNow()` on
/// foreground return to verify the token survived backgrounding.
public final class DSSKeepAliveClient {

    private let store: DSSSessionStore
    private let session: URLSession
    private var timer: Timer?
    public private(set) var isRunning = false

    public init(store: DSSSessionStore, session: URLSession? = nil) {
        self.store = store
        self.session = session ?? DSSURLSession.make(trustedHost: store.trustedHost)
    }

    public func start(onResult: @escaping (KeepAliveResult) -> Void) {
        stop()
        isRunning = true
        let timer = Timer(timeInterval: store.keepAliveInterval, repeats: true) { [weak self] _ in
            self?.fire(onResult: onResult)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    /// One-shot ping (e.g. on foreground) outside the timer cadence.
    public func fireNow(onResult: @escaping (KeepAliveResult) -> Void) {
        fire(onResult: onResult)
    }

    // MARK: - Private

    private func fire(onResult: @escaping (KeepAliveResult) -> Void) {
        guard !store.token.isEmpty,
              let req = DSSRequestFactory.keepAlive(server: store.serverURL, token: store.token) else {
            return main(onResult, .networkError("Invalid keep-alive configuration"))
        }

        session.dataTask(with: req) { [weak self] data, _, error in
            guard let self else { return }
            if let error {
                return self.main(onResult, .networkError(error.localizedDescription))
            }
            guard let data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return self.main(onResult, .networkError("Invalid response"))
            }
            let result = DSSResponseMapper.mapKeepAlive(json)
            if case .success(let refreshed) = result, let refreshed {
                DispatchQueue.main.async { self.store.update(token: refreshed) }
            }
            self.main(onResult, result)
        }.resume()
    }

    private func main(_ completion: @escaping (KeepAliveResult) -> Void, _ result: KeepAliveResult) {
        DispatchQueue.main.async { completion(result) }
    }

    deinit {
        stop()
        // URLSession retains its delegate; explicit invalidation breaks the cycle.
        session.invalidateAndCancel()
    }
}
