// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MQQComponents",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "MQQComponents",
            targets: ["MQQComponents"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MQQComponents",
            path: "Sources/MQQComponents",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("MQQFoundation"),
                .headerSearchPath("MQQNetworkInfo"),
                .headerSearchPath("MQQSubstrate"),
                .headerSearchPath("MQQUserDefaults"),
                .headerSearchPath("MQQDatabase"),
                .define("TARGET_OS_IOS", to: "1"),
                .define("TARGET_OS_IPHONE", to: "1"),
                .define("__IPHONE_OS_VERSION_MIN_REQUIRED", to: "90000"),
                .unsafeFlags(["-fno-objc-arc"]),
            ],
            linkerSettings: [
                .linkedFramework("CoreTelephony"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("NetworkExtension"),
                .linkedFramework("Foundation"),
                .linkedFramework("UIKit"),
                .linkedLibrary("sqlite3")
            ]
        )
    ]
) 