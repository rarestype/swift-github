// swift-tools-version:6.2
import PackageDescription
import CompilerPluginSupport

var Cryptography: String { "Cryptography" }

let package: Package = .init(
    name: "swift-github",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .watchOS(.v11), .visionOS(.v2)],
    products: [
        .library(name: "GitHubAPI", targets: ["GitHubAPI"]),
        .library(name: "GitHubClient", targets: ["GitHubClient"]),
        .library(name: "GitHubRSA", targets: ["GitHubRSA"]),
        .library(name: "SHA1_JSON", targets: ["SHA1_JSON"]),
    ],
    traits: [
        .trait(name: Cryptography),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/dollup", from: "1.0.1"),

        .package(url: "https://github.com/rarestype/h", from: "1.0.1"),
        .package(url: "https://github.com/rarestype/servit", from: "1.1.0"),
        .package(url: "https://github.com/rarestype/swift-cryptography", from: "0.2.0"),
        .package(url: "https://github.com/rarestype/swift-json", from: "2.3.2"),
        .package(url: "https://github.com/rarestype/swift-jwt", from: "0.1.0"),
        .package(url: "https://github.com/rarestype/u", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "GitHubAPI",
            dependencies: [
                .target(name: "SHA1_JSON"),
                .product(name: "UnixTime", package: "u"),
            ]
        ),

        .target(
            name: "GitHubClient",
            dependencies: [
                .target(name: "GitHubAPI"),

                .product(name: "HTTPClient", package: "servit"),
                .product(name: "Base64", package: "h"),
            ]
        ),

        .target(
            name: "GitHubRSA",
            dependencies: [
                .target(name: "GitHubAPI"),
                .product(
                    name: "Cryptography",
                    package: "swift-cryptography",
                    condition: .when(platforms: [.linux], traits: [Cryptography])
                ),
                .product(name: "JWT", package: "swift-jwt"),
            ],

        ),

        .target(
            name: "SHA1_JSON",
            dependencies: [
                .product(name: "JSON", package: "swift-json"),
                .product(name: "SHA1", package: "h"),
            ]
        ),
    ]
)

for target: Target in package.targets {
    {
        var settings: [SwiftSetting] = $0 ?? []

        settings.append(.enableUpcomingFeature("ExistentialAny"))
        settings.append(.enableUpcomingFeature("InternalImportsByDefault"))
        settings.append(.enableExperimentalFeature("StrictConcurrency"))
        settings.append(.treatWarning("ExistentialAny", as: .error))
        settings.append(.treatWarning("MutableGlobalVariable", as: .error))
        settings.append(.define("DEBUG", .when(configuration: .debug)))

        $0 = settings
    } (&target.swiftSettings)
}
