// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FITRepairStudio",
    defaultLocalization: "cs",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FITRepairStudio", targets: ["FITRepairStudio"])
    ],
    targets: [
        .executableTarget(
            name: "FITRepairStudio",
            path: "Sources/FITRepairStudio",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
