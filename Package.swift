// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "AutoScreenshooter",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(
            name: "AutoScreenshooter",
            targets: ["AutoScreenshooter"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AutoScreenshooter",
            dependencies: [],
            resources: [.process("Resources")]
        )
    ]
)
