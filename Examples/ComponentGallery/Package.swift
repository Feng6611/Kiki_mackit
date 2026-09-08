// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KikiComponentGallery",
    platforms: [.macOS(.v13)],
    dependencies: [.package(path: "../..")],
    targets: [.executableTarget(
        name: "KikiComponentGallery",
        dependencies: [
            .product(name: "KikiSettings", package: "Kiki_mackit"),
            .product(name: "KikiReview", package: "Kiki_mackit"),
            .product(name: "KikiOnboarding", package: "Kiki_mackit")
        ]
    )]
)
