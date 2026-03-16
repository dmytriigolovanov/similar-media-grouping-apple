// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SimilarMediaKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SimilarMediaKit",
            targets: ["SimilarMediaKit"]
        ),
    ],
    targets: [
        .target(
            name: "SimilarMediaKit",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("Photos"),
                .linkedFramework("Vision"),
                .linkedFramework("SwiftData"),
                .linkedFramework("CoreGraphics")
            ]
        ),

    ]
)
