// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SideRefresh",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "SideRefreshCore", targets: ["SideRefreshCore"]),
        .executable(name: "side-refresh", targets: ["SideRefreshCLI"]),
        .executable(name: "siderefresh-mcp", targets: ["SideRefreshMCP"]),
        .executable(name: "SideRefreshAgent", targets: ["SideRefreshAgent"]),
        .executable(name: "SideRefresh", targets: ["SideRefreshApp"]),
        .executable(
            name: "SideRefreshIOSRenewal",
            targets: ["SideRefreshIOSRenewal"]
        ),
    ],
    targets: [
        .target(name: "SideRefreshCore"),
        .target(
            name: "SideRefreshAppPresentation",
            dependencies: ["SideRefreshCore"]
        ),
        .executableTarget(
            name: "SideRefreshCLI",
            dependencies: ["SideRefreshCore"]
        ),
        .target(
            name: "SideRefreshMCPServer",
            dependencies: ["SideRefreshCore"]
        ),
        .executableTarget(
            name: "SideRefreshMCP",
            dependencies: [
                "SideRefreshCore",
                "SideRefreshMCPServer",
            ]
        ),
        .executableTarget(
            name: "SideRefreshAgent",
            dependencies: ["SideRefreshCore"]
        ),
        .executableTarget(
            name: "SideRefreshApp",
            dependencies: [
                "SideRefreshCore",
                "SideRefreshAppPresentation",
            ],
            linkerSettings: [
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .executableTarget(
            name: "SideRefreshIOSRenewal",
            dependencies: ["SideRefreshCore"]
        ),
        .testTarget(
            name: "SideRefreshCoreTests",
            dependencies: ["SideRefreshCore"],
            path: "SwiftTests/SideRefreshCoreTests"
        ),
        .testTarget(
            name: "SideRefreshMCPServerTests",
            dependencies: [
                "SideRefreshMCPServer",
                "SideRefreshCore",
            ],
            path: "SwiftTests/SideRefreshMCPServerTests"
        ),
        .testTarget(
            name: "SideRefreshAppPresentationTests",
            dependencies: [
                "SideRefreshAppPresentation",
                "SideRefreshCore",
            ],
            path: "SwiftTests/SideRefreshAppPresentationTests"
        ),
    ]
)
