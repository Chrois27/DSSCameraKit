//
//  PTZModels.swift
//  DSSCameraKit
//
//  Created by Chris Choi.
//

import Foundation

/// Pan/Tilt direction. Raw values match the VMS HTTP API wire format.
public enum PTZDirection: String {
    case up    = "1"
    case down  = "2"
    case left  = "3"
    case right = "4"
}

/// Optical zoom direction.
public enum PTZZoom: String {
    case tele = "1"   // zoom in
    case wide = "2"   // zoom out
}

/// Continuous-move lifecycle: `.start` on touch-down, `.stop` on touch-up.
public enum PTZAction: String {
    case start = "1"
    case stop  = "0"
}

/// Outcome of a PTZ request, mapped from the API's numeric `code`.
public enum PTZResult: Equatable {
    case success
    case locked(lockUser: String?)   // another operator holds the PTZ lock
    case authFailed                  // 7000
    case unauthorized                // 1103
    case parameterError              // 1004
    case channelNotFound             // 10004
    case networkError(String)
    case unknown(code: Int, desc: String?)
}

/// Outcome of a session keep-alive request.
public enum KeepAliveResult: Equatable {
    case success(refreshedToken: String?)
    case expired                     // 7000 — token no longer valid
    case networkError(String)
    case unknown(code: Int, desc: String?)
}
