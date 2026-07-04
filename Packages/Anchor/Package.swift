// swift-tools-version: 6.0
import PackageDescription

// Dependency direction (design spec §3):
//   AnchorCore depends on nothing.
//   AnchorDesign / AnchorPersistence / AnchorPlatform depend on AnchorCore only.
//   Feature targets depend on AnchorCore + AnchorDesign only.
//   SwiftData is imported nowhere outside AnchorPersistence.
let package = Package(
    name: "Anchor",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AnchorCore", targets: ["AnchorCore"]),
        .library(name: "AnchorDesign", targets: ["AnchorDesign"]),
        .library(name: "AnchorPersistence", targets: ["AnchorPersistence"]),
        .library(name: "AnchorPlatform", targets: ["AnchorPlatform"]),
        .library(name: "FeatureToday", targets: ["FeatureToday"]),
        .library(name: "FeatureTimeline", targets: ["FeatureTimeline"]),
        .library(name: "FeatureGoals", targets: ["FeatureGoals"]),
        .library(name: "FeatureReflect", targets: ["FeatureReflect"]),
        .library(name: "FeatureCoping", targets: ["FeatureCoping"]),
        .library(name: "FeatureSettings", targets: ["FeatureSettings"]),
        .library(name: "FeatureOnboarding", targets: ["FeatureOnboarding"])
    ],
    targets: [
        .target(name: "AnchorCore"),
        .target(name: "AnchorDesign", dependencies: ["AnchorCore"]),
        .target(name: "AnchorPersistence", dependencies: ["AnchorCore"]),
        .target(name: "AnchorPlatform", dependencies: ["AnchorCore"]),
        .target(name: "FeatureToday", dependencies: ["AnchorCore", "AnchorDesign"]),
        .target(name: "FeatureTimeline", dependencies: ["AnchorCore", "AnchorDesign"]),
        .target(name: "FeatureGoals", dependencies: ["AnchorCore", "AnchorDesign"]),
        .target(name: "FeatureReflect", dependencies: ["AnchorCore", "AnchorDesign"]),
        .target(name: "FeatureCoping", dependencies: ["AnchorCore", "AnchorDesign"]),
        .target(name: "FeatureSettings", dependencies: ["AnchorCore", "AnchorDesign"]),
        .target(name: "FeatureOnboarding", dependencies: ["AnchorCore", "AnchorDesign"]),
        .testTarget(name: "AnchorCoreTests", dependencies: ["AnchorCore"]),
        .testTarget(name: "AnchorDesignTests", dependencies: ["AnchorDesign", "AnchorCore"]),
        .testTarget(name: "AnchorPersistenceTests", dependencies: ["AnchorPersistence", "AnchorCore"]),
        .testTarget(name: "FeatureTodayTests", dependencies: ["FeatureToday", "AnchorCore"]),
        .testTarget(name: "FeatureTimelineTests", dependencies: ["FeatureTimeline", "AnchorCore"]),
        .testTarget(name: "FeatureGoalsTests", dependencies: ["FeatureGoals", "AnchorCore"]),
        .testTarget(name: "FeatureReflectTests", dependencies: ["FeatureReflect", "AnchorCore"]),
        .testTarget(name: "FeatureCopingTests", dependencies: ["FeatureCoping", "AnchorCore"])
    ],
    swiftLanguageModes: [.v6]
)
