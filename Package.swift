// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Kiki_mackit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "KikiSettings", targets: ["KikiSettings"]),
        .library(name: "KikiMenuBar", targets: ["KikiMenuBar"]),
        .library(name: "KikiPaywall", targets: ["KikiPaywall"]),
        .library(name: "RevenueCatCommerceKit", targets: ["RevenueCatCommerceKit"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/RevenueCat/purchases-ios-spm.git",
            exact: "5.67.0"
        )
    ],
    targets: [
        .target(name: "KikiSettings"),
        .target(name: "KikiMenuBar"),
        .target(name: "KikiPaywall"),
        .target(
            name: "RevenueCatCommerceKit",
            dependencies: [
                .product(name: "RevenueCat", package: "purchases-ios-spm")
            ]
        ),
        .testTarget(name: "KikiSettingsTests", dependencies: ["KikiSettings"]),
        .testTarget(name: "KikiMenuBarTests", dependencies: ["KikiMenuBar"]),
        .testTarget(name: "KikiPaywallTests", dependencies: ["KikiPaywall"]),
        .testTarget(
            name: "RevenueCatCommerceKitTests",
            dependencies: [
                "RevenueCatCommerceKit",
                .product(name: "RevenueCat", package: "purchases-ios-spm")
            ]
        )
    ]
)
