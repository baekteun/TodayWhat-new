import DependencyPlugin
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.module(
    name: ModulePaths.Shared.DeviceClient.rawValue,
    targets: [
        .implements(module: .shared(.DeviceClient), dependencies: [
            .shared(target: .ComposableArchitectureWrapper),
            .shared(target: .DeviceUtil)
        ])
    ]
)
