// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Kiki_mackit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "KikiDesign", targets: ["KikiDesign"]),
        .library(name: "KikiWindow", targets: ["KikiWindow"]),
        .library(name: "KikiSettings", targets: ["KikiSettings"]),
        .library(name: "KikiMenuBar", targets: ["KikiMenuBar"]),
        .library(name: "KikiPaywall", targets: ["KikiPaywall"])
    ],
    targets: [
        .target(name: "KikiDesign"),
        .target(name: "KikiWindow"),
        .target(name: "KikiSettings"),
        .target(name: "KikiMenuBar"),
        .target(name: "KikiPaywall", dependencies: ["KikiDesign", "KikiWindow"]),
        .testTarget(name: "KikiDesignTests", dependencies: ["KikiDesign"]),
        .testTarget(name: "KikiWindowTests", dependencies: ["KikiWindow"]),
        .testTarget(name: "KikiSettingsTests", dependencies: ["KikiSettings"]),
        .testTarget(name: "KikiMenuBarTests", dependencies: ["KikiMenuBar"]),
        .testTarget(name: "KikiPaywallTests", dependencies: ["KikiPaywall"])
    ]
)
