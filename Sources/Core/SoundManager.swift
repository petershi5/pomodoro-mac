import Foundation
import AppKit

final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    func playCompletionSound() {
        NSSound(named: .init("Glass"))?.play()
    }

    func playFocusStartSound() {
        NSSound(named: .init("Pop"))?.play()
    }

    func playBreakStartSound() {
        NSSound(named: .init("Basso"))?.play()
    }
}
