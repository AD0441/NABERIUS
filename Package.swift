// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "Naberius", defaultLocalization: "es", platforms: [.macOS(.v14)], products: [.library(name: "NaberiusCore", targets: ["NaberiusCore"]), .executable(name: "Naberius", targets: ["Naberius"])], targets: [
    .target(name: "NaberiusCore", resources: [.copy("Resources"), .process("Localization")], swiftSettings: [.swiftLanguageMode(.v6), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
    .executableTarget(name: "Naberius", dependencies: ["NaberiusCore"], swiftSettings: [.swiftLanguageMode(.v6), .defaultIsolation(MainActor.self), .enableUpcomingFeature("NonisolatedNonsendingByDefault")]),
    .testTarget(name: "NaberiusCoreTests", dependencies: ["NaberiusCore"], swiftSettings: [.swiftLanguageMode(.v6)]),
    .testTarget(name: "NaberiusAppTests", dependencies: ["Naberius", "NaberiusCore"], swiftSettings: [.swiftLanguageMode(.v6), .defaultIsolation(MainActor.self)])
])
