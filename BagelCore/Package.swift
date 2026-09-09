// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BagelCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BagelCore", targets: ["BagelCore"])
    ],
    targets: [
        .target(name: "BagelCore"),
        .testTarget(name: "BagelCoreTests", dependencies: ["BagelCore"])
    ]
)
