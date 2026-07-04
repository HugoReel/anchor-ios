// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Anchor",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AnchorCore", targets: ["AnchorCore"])
    ],
    targets: [
        .target(name: "AnchorCore"),
        .testTarget(name: "AnchorCoreTests", dependencies: ["AnchorCore"])
    ],
    swiftLanguageModes: [.v6]
)
