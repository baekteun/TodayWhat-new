import Foundation

public enum DisplayInfoPart: Equatable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case timeTable
}

public extension DisplayInfoPart {
    var display: String {
        switch self {
        case .breakfast:
            return "🥞 아침"
        case .lunch:
            return "🍱 점심"
        case .dinner:
            return "🍛 저녁"
        case .timeTable:
            return "⏰ 시간표"
        }
    }
}
