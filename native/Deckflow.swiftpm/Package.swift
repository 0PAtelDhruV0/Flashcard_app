// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Deckflow",
    platforms: [.iOS("17.0")],
    products: [
        .iOSApplication(
            name: "Deckflow",
            targets: ["AppModule"],
            bundleIdentifier: "com.deckflow.flashcards",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .pencil),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeLeft,
                .landscapeRight,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(name: "AppModule", path: "AppModule")
    ],
    swiftLanguageVersions: [.v5]
)