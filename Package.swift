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
        .library(name: "KikiPaywall", targets: ["KikiPaywall"]),
        .library(name: "KikiOverlay", targets: ["KikiOverlay"]),
        .library(name: "KikiTriggerCorner", targets: ["KikiTriggerCorner"])
    ],
    targets: [
        .target(name: "KikiCore"),
        .target(name: "KikiDesign"),
        .target(name: "KikiWindow", dependencies: ["KikiCore"]),
        .target(name: "KikiSettings", dependencies: ["KikiCore"]),
        .target(name: "KikiMenuBar", dependencies: ["KikiCore"]),
        .target(name: "KikiPaywall", dependencies: ["KikiDesign", "KikiWindow"]),
        .target(name: "KikiOverlay", dependencies: ["KikiDesign"]),
        .target(name: "KikiTriggerCorner"),
        .testTarget(name: "KikiDesignTests", dependencies: ["KikiDesign"]),
        .testTarget(name: "KikiWindowTests", dependencies: ["KikiWindow"]),
        .testTarget(name: "KikiSettingsTests", dependencies: ["KikiSettings"]),
        .testTarget(name: "KikiMenuBarTests", dependencies: ["KikiMenuBar"]),
        .testTarget(name: "KikiPaywallTests", dependencies: ["KikiPaywall"]),
        .testTarget(name: "KikiOverlayTests", dependencies: ["KikiOverlay"]),
        .testTarget(name: "KikiTriggerCornerTests", dependencies: ["KikiTriggerCorner"])
    ]
)
