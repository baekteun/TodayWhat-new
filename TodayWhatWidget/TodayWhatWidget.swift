import Dependencies
import WidgetKit
import SwiftUI
import Entity
import MealClient
import LocalDatabaseClient
import EnumUtil
import TimeTableClient

struct MealProvider: TimelineProvider {
    typealias Entry = MealEntry

    @Dependency(\.mealClient) var mealClient
    @Dependency(\.localDatabaseClient) var localDatabaseClient

    func placeholder(in context: Context) -> MealEntry {
        return MealEntry.empty()
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (MealEntry) -> ()
    ) {
        Task {
            var currentDate = Date()
            if currentDate.hour >= 20 {
                currentDate = currentDate.adding(by: .day, value: 1)
            }
            do {
                let meal = try await mealClient.fetchMeal(currentDate)
                let allergy = try localDatabaseClient.readRecords(as: AllergyLocalEntity.self)
                    .compactMap { AllergyType(rawValue: $0.allergy) }
                let entry = MealEntry(
                    date: currentDate,
                    meal: meal,
                    mealPartTime: MealPartTime(hour: currentDate),
                    allergyList: allergy
                )
                completion(entry)
            } catch {
                let entry = MealEntry.empty()
                completion(entry)
            }
        }
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<Entry>) -> ()
    ) {
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? .init()
        Task {
            var currentDate = Date()
            if currentDate.hour >= 20 {
                currentDate = currentDate.adding(by: .day, value: 1)
            }
            do {
                let meal = try await mealClient.fetchMeal(currentDate)
                let allergy = try localDatabaseClient.readRecords(as: AllergyLocalEntity.self)
                    .compactMap { AllergyType(rawValue: $0.allergy) }
                let entry = MealEntry(
                    date: currentDate,
                    meal: meal,
                    mealPartTime: MealPartTime(hour: currentDate),
                    allergyList: allergy
                )
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = MealEntry.empty()
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
}

struct TimeTableProvider: TimelineProvider {
    typealias Entry = TimeTableEntry

    @Dependency(\.timeTableClient) var timeTableClient

    func placeholder(in context: Context) -> TimeTableEntry {
        .empty()
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeTableEntry) -> Void) {
        Task {
            var currentDate = Date()
            if currentDate.hour >= 20 {
                currentDate = currentDate.adding(by: .day, value: 1)
            }
            do {
                let timeTable = try await timeTableClient.fetchTimeTable(currentDate).prefix(7)
                let entry = TimeTableEntry(date: currentDate, timeTable: Array(timeTable))
                completion(entry)
            } catch {
                let entry = TimeTableEntry.empty()
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeTableEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? .init()
        Task {
            var currentDate = Date()
            if currentDate.hour >= 20 {
                currentDate = currentDate.adding(by: .day, value: 1)
            }
            do {
                let timeTable = try await timeTableClient.fetchTimeTable(currentDate).prefix(7)
                let entry = TimeTableEntry(date: currentDate, timeTable: Array(timeTable))
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = TimeTableEntry.empty()
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
}

struct MealEntry: TimelineEntry {
    let date: Date
    let meal: Meal
    let mealPartTime: MealPartTime
    let allergyList: [AllergyType]

    static func empty() -> MealEntry {
        MealEntry(
            date: Date(),
            meal: .init(
                breakfast: .init(meals: [], cal: 0),
                lunch: .init(meals: [], cal: 0),
                dinner: .init(meals: [], cal: 0)
            ),
            mealPartTime: .breakfast,
            allergyList: []
        )
    }
}

struct TimeTableEntry: TimelineEntry {
    let date: Date
    let timeTable: [TimeTable]

    static func empty() -> TimeTableEntry {
        TimeTableEntry(
            date: Date(),
            timeTable: []
        )
    }
}

@main
struct TodayWhatWidget: WidgetBundle {
    var body: some Widget {
        TodayWhatMealWidget()
        TodayWhatTimeTableWidget()
    }
}

struct TodayWhatMealWidget: Widget {
    let kind: String = "TodayWhatMealWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MealProvider()) { entry in
            MealWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘 급식 뭐임")
        .description("시간에 따라 아침, 점심, 저녁 급식을 확인해요!")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayWhatTimeTableWidget: Widget {
    let kind: String = "TodayWhatTimeTableWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeTableProvider()) { entry in
            TimeTableWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("오늘 시간표 뭐임")
        .description("오늘 시간표를 확인해요!")
        .supportedFamilies([.systemSmall])
    }
}



struct TodayWhatWidget_Previews: PreviewProvider {
    static var previews: some View {
        MealWidgetEntryView(
            entry: .empty()
        )
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
