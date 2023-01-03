// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "DeviceAuthority",
    platforms: [
        .iOS(.v9),
        .macOS(.v12),
    ],
    products: [
        .library(name: "DeviceAuthority", targets: ["DeviceAuthority"]),
        .executable(name: "swift-device-authority", targets: ["CommandLine"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/console-kit.git", from: "4.5.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.3.0"),
    ],
    targets: [
        .target(
            name: "DeviceAuthority",
            dependencies: []
        ),
        
        .testTarget(
            name: "DeviceAuthorityTests",
            dependencies: ["DeviceAuthority"]
        ),
        
        .executableTarget(
            name: "CommandLine",
            dependencies: [
                .product(name: "ConsoleKit", package: "console-kit"),
                .product(name: "ShellOut", package: "ShellOut"),
            ]
        ),
    ]
)
