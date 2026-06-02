//
//  DSSResponseMapper.swift
//  DSSCameraKit
//
//  Created by Chris Choi.
//

import Foundation

/// Pure mappers from the API's JSON envelope (`{ code, desc, data }`) to typed
/// results. Kept side-effect free so every branch is unit-testable.
public enum DSSResponseMapper {

    public static func mapPTZ(_ json: [String: Any]) -> PTZResult {
        guard let code = json["code"] as? Int else {
            return .networkError("Invalid response")
        }
        let desc = json["desc"] as? String

        switch code {
        case 1000:
            guard let data = json["data"] as? [String: Any] else { return .success }
            let result = data["result"] as? String ?? "1"
            if result == "1" {
                return .success
            }
            let lockUser = (data["lockUser"] as? [String: Any])?["userName"] as? String
            return .locked(lockUser: lockUser)
        case 7000:  return .authFailed
        case 1103:  return .unauthorized
        case 1004:  return .parameterError
        case 10004: return .channelNotFound
        default:    return .unknown(code: code, desc: desc)
        }
    }

    public static func mapKeepAlive(_ json: [String: Any]) -> KeepAliveResult {
        guard let code = json["code"] as? Int else {
            return .networkError("Invalid response")
        }

        switch code {
        case 1000:
            let newToken = (json["data"] as? [String: Any])?["token"] as? String
            let refreshed = (newToken?.isEmpty == false) ? newToken : nil
            return .success(refreshedToken: refreshed)
        case 7000:
            return .expired
        default:
            return .unknown(code: code, desc: json["desc"] as? String)
        }
    }
}
