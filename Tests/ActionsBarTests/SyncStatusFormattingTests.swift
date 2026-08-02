@testable import ActionsBar
import XCTest

final class SyncStatusFormattingTests: XCTestCase {
    func test_neverSyncedWhenDateIsNil() {
        XCTAssertEqual(relativeSyncLabel(from: nil, to: Date()), "Never synced")
    }

    func test_justNowForSubMinuteGap() {
        let now = Date()
        let synced = now.addingTimeInterval(-10)
        XCTAssertEqual(relativeSyncLabel(from: synced, to: now), "Last synced just now")
    }

    func test_minutesAgoForSingleMinute() {
        let now = Date()
        let synced = now.addingTimeInterval(-60)
        XCTAssertEqual(relativeSyncLabel(from: synced, to: now), "Last synced 1 minute ago")
    }

    func test_minutesAgoForMultipleMinutes() {
        let now = Date()
        let synced = now.addingTimeInterval(-120)
        XCTAssertEqual(relativeSyncLabel(from: synced, to: now), "Last synced 2 minutes ago")
    }

    func test_hoursAgoForOverAnHour() {
        let now = Date()
        let synced = now.addingTimeInterval(-3600 * 2)
        XCTAssertEqual(relativeSyncLabel(from: synced, to: now), "Last synced 2 hours ago")
    }
}
