import XCTest
@testable import ActionsBar

@MainActor
final class AppSettingsPrefsTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "appearance")
        UserDefaults.standard.removeObject(forKey: "showMenuBarIcon")
    }

    func test_appearanceDefaultsToSystem() {
        let settings = AppSettings()
        XCTAssertEqual(settings.appearance, .system)
    }

    func test_appearancePersistsAcrossInstances() {
        let settings = AppSettings()
        settings.appearance = .dark
        let reloaded = AppSettings()
        XCTAssertEqual(reloaded.appearance, .dark)
    }

    func test_showMenuBarIconDefaultsToTrue() {
        let settings = AppSettings()
        XCTAssertTrue(settings.showMenuBarIcon)
    }

    func test_showMenuBarIconPersistsAcrossInstances() {
        let settings = AppSettings()
        settings.showMenuBarIcon = false
        let reloaded = AppSettings()
        XCTAssertFalse(reloaded.showMenuBarIcon)
    }
}
