// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DSSCameraKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(name: "DSSCameraKit", targets: ["DSSCameraKit"])
    ],
    targets: [
        .target(
            name: "DSSCameraKit",
            path: "Sources/DSSCameraKit"
        ),
        .testTarget(
            name: "DSSCameraKitTests",
            dependencies: ["DSSCameraKit"],
            path: "Tests/DSSCameraKitTests"
        )
    ]
)
