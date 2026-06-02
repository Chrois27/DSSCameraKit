import XCTest
@testable import DSSCameraKit

private let server = URL(string: "https://camera.example.com")!

private func body(of request: URLRequest?) -> [String: Any]? {
    guard let data = request?.httpBody else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
}

final class DSSRequestFactoryTests: XCTestCase {

    func testPTZDirectRequest() {
        let req = DSSRequestFactory.ptzDirect(server: server, token: "TKN", channelId: "ch7",
                                              direction: .left, action: .start)
        XCTAssertEqual(req?.url?.path, "/brms/api/v1.0/DMS/Ptz/OperateDirect")
        XCTAssertEqual(req?.httpMethod, "POST")
        XCTAssertEqual(req?.value(forHTTPHeaderField: "X-Subject-Token"), "TKN")
        XCTAssertEqual(req?.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=UTF-8")

        let data = body(of: req)?["data"] as? [String: Any]
        XCTAssertEqual(data?["direct"] as? String, "3")   // .left
        XCTAssertEqual(data?["command"] as? String, "1")  // .start
        XCTAssertEqual(data?["channelId"] as? String, "ch7")
    }

    func testPTZZoomRequest() {
        let req = DSSRequestFactory.ptzZoom(server: server, token: "TKN", channelId: "ch1",
                                            zoom: .tele, action: .stop)
        XCTAssertEqual(req?.url?.path, "/brms/api/v1.0/DMS/Ptz/OperateCamera")
        let data = body(of: req)?["data"] as? [String: Any]
        XCTAssertEqual(data?["direct"] as? String, "1")   // .tele
        XCTAssertEqual(data?["command"] as? String, "0")  // .stop
        XCTAssertEqual(data?["operateType"] as? String, "1")
    }

    func testKeepAliveRequest() {
        let req = DSSRequestFactory.keepAlive(server: server, token: "ABC")
        XCTAssertEqual(req?.url?.path, "/brms/api/v1.0/accounts/keepalive")
        XCTAssertEqual(req?.httpMethod, "PUT")
        XCTAssertEqual(req?.value(forHTTPHeaderField: "X-Subject-Token"), "ABC")
        XCTAssertEqual(body(of: req)?["token"] as? String, "ABC")
    }
}

final class DSSResponseMapperTests: XCTestCase {

    func testPTZSuccess() {
        XCTAssertEqual(DSSResponseMapper.mapPTZ(["code": 1000]), .success)
        XCTAssertEqual(DSSResponseMapper.mapPTZ(["code": 1000, "data": ["result": "1"]]), .success)
    }

    func testPTZLockedByAnotherOperator() {
        let json: [String: Any] = ["code": 1000, "data": ["result": "0", "lockUser": ["userName": "operator-2"]]]
        XCTAssertEqual(DSSResponseMapper.mapPTZ(json), .locked(lockUser: "operator-2"))
    }

    func testPTZErrorCodes() {
        XCTAssertEqual(DSSResponseMapper.mapPTZ(["code": 7000]), .authFailed)
        XCTAssertEqual(DSSResponseMapper.mapPTZ(["code": 1103]), .unauthorized)
        XCTAssertEqual(DSSResponseMapper.mapPTZ(["code": 1004]), .parameterError)
        XCTAssertEqual(DSSResponseMapper.mapPTZ(["code": 10004]), .channelNotFound)
        XCTAssertEqual(DSSResponseMapper.mapPTZ(["code": 42, "desc": "x"]), .unknown(code: 42, desc: "x"))
    }

    func testKeepAlive() {
        XCTAssertEqual(DSSResponseMapper.mapKeepAlive(["code": 1000]), .success(refreshedToken: nil))
        XCTAssertEqual(DSSResponseMapper.mapKeepAlive(["code": 1000, "data": ["token": "NEW"]]),
                       .success(refreshedToken: "NEW"))
        XCTAssertEqual(DSSResponseMapper.mapKeepAlive(["code": 1000, "data": ["token": ""]]),
                       .success(refreshedToken: nil))
        XCTAssertEqual(DSSResponseMapper.mapKeepAlive(["code": 7000]), .expired)
    }
}

final class DSSSessionStoreTests: XCTestCase {

    func testKeepAliveIntervalIsTwoThirdsOfDuration() {
        let store = DSSSessionStore(serverURL: server, channelId: "c", token: "t", durationSeconds: 30)
        XCTAssertEqual(store.keepAliveInterval, 20, accuracy: 0.001)
    }

    func testKeepAliveIntervalFloor() {
        let store = DSSSessionStore(serverURL: server, channelId: "c", token: "t", durationSeconds: 3)
        XCTAssertEqual(store.keepAliveInterval, 10, accuracy: 0.001)
    }

    func testTrustedHost() {
        let store = DSSSessionStore(serverURL: server, channelId: "c", token: "t")
        XCTAssertEqual(store.trustedHost, "camera.example.com")
    }

    func testTokenUpdateIgnoresEmpty() {
        let store = DSSSessionStore(serverURL: server, channelId: "c", token: "original")
        store.update(token: "")
        XCTAssertEqual(store.token, "original")
        store.update(token: "rotated")
        XCTAssertEqual(store.token, "rotated")
    }
}
