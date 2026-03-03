import Foundation
import Testing
@testable import VaultMailFeature

@Suite("BackgroundExecutionArbiter")
struct BackgroundExecutionArbiterTests {
    @Test("Helper should poll when no heartbeat is present")
    func noHeartbeatPolls() {
        #expect(BackgroundExecutionArbiter.shouldHelperPoll(mainAppHeartbeatAt: nil))
    }

    @Test("Helper should not poll when heartbeat is fresh")
    func freshHeartbeatSuppressesPoll() {
        let now = Date()
        let heartbeat = now.addingTimeInterval(-30)
        #expect(!BackgroundExecutionArbiter.shouldHelperPoll(mainAppHeartbeatAt: heartbeat, now: now))
    }
}
