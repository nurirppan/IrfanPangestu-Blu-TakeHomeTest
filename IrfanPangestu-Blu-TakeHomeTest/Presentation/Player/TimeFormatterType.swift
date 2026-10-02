import Foundation

/// Formats seconds as m:ss for the player's time labels.
enum TimeFormatterType {
    static func string(from seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else {
            return "0:00"
        }
        let totalSeconds = Int(seconds)
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
