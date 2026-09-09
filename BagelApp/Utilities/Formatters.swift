import Foundation

enum Formatters {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()
}
