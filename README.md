# DSSCameraKit

[![CI](https://github.com/Chrois27/DSSCameraKit/actions/workflows/ci.yml/badge.svg)](https://github.com/Chrois27/DSSCameraKit/actions/workflows/ci.yml)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2013+%20%7C%20macOS%2011+-blue.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A dependency-free Swift client for controlling PTZ cameras through a
token-authenticated VMS HTTP API (DSS/ICC-style `/brms/api/v1.0` endpoints).

It handles the three things that make on-prem camera control fiddly:

1. **PTZ control** — pan / tilt / zoom with continuous-move start/stop semantics.
2. **Session liveness** — a keep-alive loop that pings the server and transparently
   rotates the session token when the server issues a new one.
3. **Self-signed TLS** — a *scoped* trust override for the single on-prem server host,
   leaving system certificate validation intact everywhere else.

```
            ┌──────────────────────┐        ┌──────────────────────┐
            │   DSSCameraClient     │        │  DSSKeepAliveClient   │
            │   move() / zoom()     │        │   start() / stop()    │
            │   warmUp()            │        │   fireNow()           │
            └──────────┬───────────┘        └───────────┬──────────┘
                       │      shared, token-rotating     │
                       └──────────►  DSSSessionStore  ◄──┘
                                          │
   pure & testable ─►  DSSRequestFactory  │  DSSResponseMapper
                                          │
                       DSSURLSession (scoped self-signed trust)
```

## Design notes

- **Dependency-injected session** — `DSSSessionStore` holds the server URL, channel id
  and token. The keep-alive client rotates the token; the PTZ client reads it. No globals.
- **Pure, testable core** — request construction (`DSSRequestFactory`) and response
  decoding (`DSSResponseMapper`) are side-effect-free, so every status code and request
  shape is covered by unit tests with **no network required**.
- **Scoped TLS trust** — `DSSURLSession` only bypasses validation for the configured
  on-prem host, never globally. This avoids `NSAllowsArbitraryLoads`.
- **Warm-up** — `warmUp()` pre-establishes the TCP+TLS connection so the first PTZ tap
  isn't penalised by the handshake.
- **No retain cycles** — the keep-alive client invalidates its `URLSession` on `deinit`
  (a delegate-backed session retains its delegate).

## Usage

```swift
import DSSCameraKit

let store = DSSSessionStore(
    serverURL: URL(string: "https://vms.internal.example")!,
    channelId: "1000001$0$0$0",
    token: sessionToken,
    durationSeconds: 30
)

let ptz = DSSCameraClient(store: store)
let keepAlive = DSSKeepAliveClient(store: store)

ptz.warmUp()
keepAlive.start { result in
    if case .expired = result { /* re-authenticate */ }
}

// continuous move while the button is held
ptz.move(.left, .start) { _ in }
// …on release
ptz.move(.left, .stop) { result in
    switch result {
    case .success:            break
    case .locked(let user):   print("PTZ locked by \(user ?? "another operator")")
    default:                  break
    }
}
```

## Build & test

```bash
swift build
swift test      # 11 tests — request shapes, response mapping, session math
```

## Modules

| File | Responsibility |
|------|----------------|
| `PTZModels.swift` | Direction / zoom / action enums, typed results |
| `DSSSessionStore.swift` | Shared, token-rotating connection state |
| `DSSURLSession.swift` | Scoped self-signed-cert trust factory |
| `DSSRequestFactory.swift` | Pure request builders (testable) |
| `DSSResponseMapper.swift` | Pure `code → result` mappers (testable) |
| `DSSCameraClient.swift` | PTZ commands + connection warm-up |
| `DSSKeepAliveClient.swift` | Timer-driven keep-alive + token rotation |

## License

MIT © Chris Choi
