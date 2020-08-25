// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftGUIDemoApp",
    products: [
        .executable(
            name: "DemoApp",
            targets: ["DemoApp"]),
        .executable(
            name: "StatefulWidgetResearchApp",
            targets: ["StatefulWidgetResearchApp"]),
        .executable(
            name: "PropertyBindingsResearchApp",
            targets: ["PropertyBindingsResearchApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/Path.swift.git", .branch("master")),
        .package(name: "GL", url: "https://github.com/UnGast/swift-opengl.git", .branch("master")),
        .package(name: "Swim", url: "https://github.com/t-ae/swim.git", .branch("master")),
        .package(url: "https://github.com/UnGast/Cnanovg.git", .branch("master")),
        .package(url: "https://github.com/wickwirew/Runtime.git", from: "2.1.1")
    ],
    targets: [
        .systemLibrary(
            name: "CSDL2",
            pkgConfig: "sdl2",
            providers: [
                .brew(["sdl2"]),
                .apt(["libsdl2-dev"])
        ]),
        .target(name: "CustomGraphicsMath"),
        .target(name: "GLGraphicsMath", dependencies: ["GL", "CustomGraphicsMath"]),
        .target(
            name: "VisualAppBase", dependencies: ["CSDL2", "CustomGraphicsMath", "Swim"]
        ),
        .target(
                // TODO: maybe rename to SwiftApplicationFramework or so...? or split to SwiftApplicationFramework and SwiftUIFramework
                name: "WidgetGUI",
                dependencies: ["VisualAppBase", "CustomGraphicsMath", "Runtime"],
                resources: [.process("Resources")]
        ),
        .target(
            name: "VisualAppBaseImplSDL2OpenGL3NanoVG",
            dependencies: ["WidgetGUI", "CSDL2", "GL", "Swim", .product(name: "CnanovgGL3", package: "Cnanovg"), "CustomGraphicsMath", "GLGraphicsMath", .product(name: "Path", package: "Path.swift")],
            resources: [.process("Resources")]),
        .target(name: "DemoApp", dependencies: ["WidgetGUI", "VisualAppBase", "VisualAppBaseImplSDL2OpenGL3NanoVG"]),
        .target(
            name: "DemoGameApp",
            dependencies: ["WidgetGUI", "VisualAppBase", "VisualAppBaseImplSDL2OpenGL3NanoVG"],
            resources: [.process("Resources")]),
        .target(name: "StatefulWidgetResearchApp", dependencies: ["WidgetGUI", "VisualAppBase", "VisualAppBaseImplSDL2OpenGL3NanoVG"]),
        .target(name: "PropertyBindingsResearchApp", dependencies: ["WidgetGUI", "VisualAppBase", "VisualAppBaseImplSDL2OpenGL3NanoVG"]),
        .target(
            name: "FlexExperiments",
            dependencies: ["WidgetGUI", "VisualAppBase", "VisualAppBaseImplSDL2OpenGL3NanoVG", "Swim"],
            resources: [.copy("Resources")]),
        .testTarget(name: "VisualAppBaseTests", dependencies: ["VisualAppBase"])
    ]
)
