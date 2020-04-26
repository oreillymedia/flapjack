// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Flapjack",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v11),
        .tvOS(.v11)
    ],
    products: [
        .library(name: "Flapjack", targets: ["Flapjack"]),
        // .library(name: "FlapjackCoreData", targets: ["FlapjackCoreData"]),
        // .library(name: "FlapjackUIKit", targets: ["FlapjackUIKit"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Flapjack", dependencies: [], path: "Flapjack/Core"),
        // .target(name: "FlapjackCoreData", dependencies: ["Flapjack"], path: "Flapjack/CoreData"),
        // .target(name: "FlapjackUIKit", dependencies: ["Flapjack"], path: "Flapjack/UIKit"),
    ]
)
