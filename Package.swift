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
        .library(name: "KikiCommerce", targets: ["KikiCommerce"]),
        .library(name: "KikiOverlay", targets: ["KikiOverlay"]),
        .library(name: "KikiTriggerCorner", targets: ["KikiTriggerCorner"]),
        .library(name: "KikiAuthorization", targets: ["KikiAuthorization"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/Feng6611/RevenueCatCommerceKit.git",
            exact: "0.1.0"
        )
    ],
    targets: [
        .target(name: "KikiCore"),
        .target(name: "KikiDesign"),
        .target(name: "KikiWindow", dependencies: ["KikiCore"]),
        .target(name: "KikiSettings", dependencies: ["KikiCore", "KikiDesign"]),
        .target(name: "KikiMenuBar", dependencies: ["KikiCore"]),
        .target(name: "KikiPaywall", dependencies: ["KikiDesign", "KikiWindow"]),
        .target(
            name: "KikiCommerce",
            dependencies: [
                "KikiPaywall",
                .product(name: "RevenueCatCommerceKit", package: "RevenueCatCommerceKit")
            ]
        ),
        .target(name: "KikiOverlay", dependencies: ["KikiDesign"]),
        .target(name: "KikiTriggerCorner"),
        .target(name: "KikiAuthorization"),
        .testTarget(name: "KikiDesignTests", dependencies: ["KikiDesign"]),
        .testTarget(name: "KikiWindowTests", dependencies: ["KikiWindow"]),
        .testTarget(name: "KikiSettingsTests", dependencies: ["KikiSettings"]),
        .testTarget(name: "KikiMenuBarTests", dependencies: ["KikiMenuBar"]),
        .testTarget(name: "KikiPaywallTests", dependencies: ["KikiPaywall"]),
        .testTarget(
            name: "KikiCommerceTests",
            dependencies: [
                "KikiCommerce",
                .product(name: "RevenueCatCommerceKit", package: "RevenueCatCommerceKit")
            ]
        ),
        .testTarget(name: "KikiOverlayTests", dependencies: ["KikiOverlay"]),
        .testTarget(name: "KikiTriggerCornerTests", dependencies: ["KikiTriggerCorner"]),
        .testTarget(name: "KikiAuthorizationTests", dependencies: ["KikiAuthorization"])
    ]
)
