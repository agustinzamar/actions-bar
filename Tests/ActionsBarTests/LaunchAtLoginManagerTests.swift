@testable import ActionsBar
import XCTest

final class FakeLaunchAtLoginService: LaunchAtLoginControlling {
    var isRegistered = false
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0

    func register() throws {
        registerCallCount += 1
        isRegistered = true
    }

    func unregister() throws {
        unregisterCallCount += 1
        isRegistered = false
    }
}

@MainActor
final class LaunchAtLoginManagerTests: XCTestCase {
    func test_reflectsServiceStateOnInit() {
        let fake = FakeLaunchAtLoginService()
        fake.isRegistered = true
        let manager = LaunchAtLoginManager(service: fake)
        XCTAssertTrue(manager.isEnabled)
    }

    func test_enablingRegistersService() {
        let fake = FakeLaunchAtLoginService()
        let manager = LaunchAtLoginManager(service: fake)
        manager.isEnabled = true
        XCTAssertEqual(fake.registerCallCount, 1)
        XCTAssertEqual(fake.unregisterCallCount, 0)
    }

    func test_disablingUnregistersService() {
        let fake = FakeLaunchAtLoginService()
        fake.isRegistered = true
        let manager = LaunchAtLoginManager(service: fake)
        manager.isEnabled = false
        XCTAssertEqual(fake.unregisterCallCount, 1)
    }

    func test_settingSameValueDoesNotReRegister() {
        let fake = FakeLaunchAtLoginService()
        let manager = LaunchAtLoginManager(service: fake)
        manager.isEnabled = false
        XCTAssertEqual(fake.registerCallCount, 0)
        XCTAssertEqual(fake.unregisterCallCount, 0)
    }
}
