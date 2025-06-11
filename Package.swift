// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MQQComponents",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "MQQComponents",
            targets: ["MQQComponents"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "MQQComponents",
            path: "MQQComponents.xcframework"
        )
    ]
) 