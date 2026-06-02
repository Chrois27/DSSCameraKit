//
//  DSSSessionStore.swift
//  DSSCameraKit
//
//  Created by Chris Choi.
//

import Foundation

/// Shared, mutable connection state for a single camera channel.
///
/// The token is rotated by the keep-alive loop and read by PTZ requests, so both
/// clients are constructed with the *same* store instance. Access is expected on
/// the main thread (timers and completion handlers hop back to main).
public final class DSSSessionStore {

    public let serverURL: URL
    public let channelId: String
    public private(set) var token: String

    /// Server-advertised token lifetime (seconds).
    public var durationSeconds: Int

    public init(serverURL: URL, channelId: String, token: String, durationSeconds: Int = 30) {
        self.serverURL = serverURL
        self.channelId = channelId
        self.token = token
        self.durationSeconds = durationSeconds > 0 ? durationSeconds : 30
    }

    public func update(token: String) {
        guard !token.isEmpty else { return }
        self.token = token
    }

    /// Refresh cadence: ~2/3 of the token lifetime, floored at 10s.
    public var keepAliveInterval: TimeInterval {
        max(TimeInterval(durationSeconds) * 2.0 / 3.0, 10)
    }

    /// Host whose self-signed certificate the client is allowed to trust.
    public var trustedHost: String? { serverURL.host }
}
