//
//  DSSRequestFactory.swift
//  DSSCameraKit
//
//  Created by Chris Choi.
//

import Foundation

/// Pure builders for the VMS HTTP API requests. Side-effect free and fully
/// unit-testable without a network.
public enum DSSRequestFactory {

    public static let basePath = "/brms/api/v1.0"

    /// `PUT /accounts/keepalive` — refreshes the session token.
    public static func keepAlive(server: URL, token: String) -> URLRequest? {
        guard let body = try? JSONSerialization.data(withJSONObject: ["token": token]) else { return nil }
        return request(server: server, path: "\(basePath)/accounts/keepalive", method: "PUT", token: token, body: body)
    }

    /// `POST /DMS/Ptz/OperateDirect` — pan/tilt move.
    public static func ptzDirect(server: URL,
                                 token: String,
                                 channelId: String,
                                 direction: PTZDirection,
                                 action: PTZAction,
                                 acceptLanguage: String = "en") -> URLRequest? {
        let body: [String: Any] = ["data": [
            "stepX": "8",
            "stepY": "8",
            "extend": "",
            "direct": direction.rawValue,
            "command": action.rawValue,
            "channelId": channelId
        ]]
        return jsonRequest(server: server, path: "\(basePath)/DMS/Ptz/OperateDirect",
                           token: token, acceptLanguage: acceptLanguage, body: body)
    }

    /// `POST /DMS/Ptz/OperateCamera` — optical zoom.
    public static func ptzZoom(server: URL,
                               token: String,
                               channelId: String,
                               zoom: PTZZoom,
                               action: PTZAction,
                               acceptLanguage: String = "en") -> URLRequest? {
        let body: [String: Any] = ["data": [
            "step": "8",
            "extend": "",
            "operateType": "1",
            "direct": zoom.rawValue,
            "command": action.rawValue,
            "channelId": channelId
        ]]
        return jsonRequest(server: server, path: "\(basePath)/DMS/Ptz/OperateCamera",
                           token: token, acceptLanguage: acceptLanguage, body: body)
    }

    // MARK: - Private

    private static func jsonRequest(server: URL, path: String, token: String,
                                    acceptLanguage: String, body: [String: Any]) -> URLRequest? {
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        return request(server: server, path: path, method: "POST", token: token,
                       body: data, acceptLanguage: acceptLanguage)
    }

    private static func request(server: URL, path: String, method: String, token: String,
                                body: Data, acceptLanguage: String? = nil) -> URLRequest? {
        guard let url = URL(string: server.absoluteString + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        req.setValue(token, forHTTPHeaderField: "X-Subject-Token")
        if let acceptLanguage { req.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language") }
        req.httpBody = body
        return req
    }
}
