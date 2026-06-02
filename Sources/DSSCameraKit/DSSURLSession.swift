//
//  DSSURLSession.swift
//  DSSCameraKit
//
//  Created by Chris Choi.
//

import Foundation

/// Builds a `URLSession` that trusts the self-signed certificate of **one** host
/// (the on-prem VMS server) while leaving system validation intact for every
/// other host.
///
/// This is a deliberately *scoped* trust override — not a global
/// `NSAllowsArbitraryLoads` — so the app keeps full TLS validation everywhere else.
public enum DSSURLSession {

    public static func make(trustedHost: String?, timeout: TimeInterval = 5) -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        return URLSession(
            configuration: config,
            delegate: ScopedTrustDelegate(trustedHost: trustedHost),
            delegateQueue: nil
        )
    }
}

final class ScopedTrustDelegate: NSObject, URLSessionDelegate {

    private let trustedHost: String?

    init(trustedHost: String?) {
        self.trustedHost = trustedHost
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        if let trustedHost, !trustedHost.isEmpty, challenge.protectionSpace.host == trustedHost {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
