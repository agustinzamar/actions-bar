import Foundation
import ServiceManagement

protocol LaunchAtLoginControlling {
    var isRegistered: Bool { get }
    func register() throws
    func unregister() throws
}

struct SMAppServiceLaunchAtLogin: LaunchAtLoginControlling {
    var isRegistered: Bool { SMAppService.mainApp.status == .enabled }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
}

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            try? isEnabled ? service.register() : service.unregister()
        }
    }

    private let service: LaunchAtLoginControlling

    init(service: LaunchAtLoginControlling = SMAppServiceLaunchAtLogin()) {
        self.service = service
        isEnabled = service.isRegistered
    }
}
