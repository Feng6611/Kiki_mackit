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
        .library(name: "KikiTriggerCorner", targets: ["KikiTriggerCorner"]),
        .library(name: "KikiAuthorization", targets: ["KikiAuthorization"]),
        .library(name: "KikiOnboarding", targets: ["KikiOnboarding"]),
        .library(name: "KikiActivation", targets: ["KikiActivation"])
    ],
    targets: [
        .target(name: "KikiCore"),
        .target(name: "KikiDesign"),
        .target(name: "KikiWindow", dependencies: ["KikiCore"]),
        .target(name: "KikiSettings", dependencies: ["KikiCore", "KikiDesign"]),
        .target(name: "KikiMenuBar", dependencies: ["KikiCore"]),
        .target(name: "KikiPaywall", dependencies: ["KikiDesign", "KikiWindow"]),
        .target(name: "KikiOverlay", dependencies: ["KikiDesign"]),
        .target(name: "KikiTriggerCorner"),
        .target(name: "KikiAuthorization"),
        .target(
            name: "KikiOnboarding",
            dependencies: ["KikiAuthorization", "KikiWindow", "KikiDesign"]
        ),
        .target(name: "KikiActivation", dependencies: ["KikiCore"]),
        .testTarget(name: "KikiDesignTests", dependencies: ["KikiDesign"]),
        .testTarget(name: "KikiWindowTests", dependencies: ["KikiWindow"]),
        .testTarget(name: "KikiSettingsTests", dependencies: ["KikiSettings"]),
        .testTarget(name: "KikiMenuBarTests", dependencies: ["KikiMenuBar"]),
        .testTarget(name: "KikiPaywallTests", dependencies: ["KikiPaywall"]),
        .testTarget(name: "KikiOverlayTests", dependencies: ["KikiOverlay"]),
        .testTarget(name: "KikiTriggerCornerTests", dependencies: ["KikiTriggerCorner"]),
        .testTarget(name: "KikiAuthorizationTests", dependencies: ["KikiAuthorization"]),
        .testTarget(name: "KikiOnboardingTests", dependencies: ["KikiOnboarding"]),
        .testTarget(name: "KikiActivationTests", dependencies: ["KikiActivation"])
    ]
)
