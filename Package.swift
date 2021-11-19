// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Reflection",
    products: [
        .library(name: "Reflection", targets: ["Reflection"]),
    ],
    targets: [
        .target(name: "Reflection", dependencies: []),
        .testTarget(name: "ReflectionTests", dependencies: ["Reflection"]),
    ]
)
