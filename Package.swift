// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Flapjack",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(name: "Flapjack", targets: ["Flapjack"]),
        .library(name: "FlapjackCoreData", targets: ["FlapjackCoreData"]),
        .library(name: "FlapjackUIKit", targets: ["FlapjackUIKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Flapjack",
            path: "Sources/Core",
            exclude: ["Supporting Files/Info.plist"]),
        .target(
            name: "FlapjackCoreData",
            dependencies: ["Flapjack"],
            path: "Sources/CoreData",
            linkerSettings: [
                .linkedFramework("CoreData")
            ]
        ),
        .target(
            name: "FlapjackUIKit",
            dependencies: ["Flapjack"],
            path: "Sources/UIKit",
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS]))
            ]
        ),
        .testTarget(
            name: "FlapjackTests",
            dependencies: ["Flapjack"],
            path: "Tests/Core"
        ),
        .testTarget(
            name: "FlapjackCoreDataTests",
            dependencies: ["Flapjack", "FlapjackCoreData"],
            path: "Tests/CoreData",
            resources: [.process("Resources")]
        )
    ]
)
