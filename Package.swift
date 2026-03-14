// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "NetCore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "NetCore",
            targets: ["NetCore"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire.git",
            from: "5.11.1"
        )
    ],
    targets: [
        .target(
            name: "NetCore",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ]
        )
    ]
)
