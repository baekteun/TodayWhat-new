import ComposableArchitecture
import UserDefaultsClient
import MealFeature
import TimeTableFeature
import NoticeClient
import NoticeFeature
import SettingsFeature
import Entity
import UIKit

public struct MainCore: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        public var school = ""
        public var grade = ""
        public var `class` = ""
        public var displayDate = Date()
        public var currentTab = 0
        public var mealCore: MealCore.State? = nil
        public var timeTableCore: TimeTableCore.State? = nil
        public var settingsCore: SettingsCore.State? = nil
        public var noticeCore: NoticeCore.State? = nil
        public var notice: EmegencyNotice? = nil
        public var isInitial: Bool = true
        public var isNavigateSettings = false
        public var isExistNewVersion: Bool = false

        public init() {}
    }

    public enum Action {
        case onAppear
        case tabChanged(Int)
        case mealCore(MealCore.Action)
        case timeTableCore(TimeTableCore.Action)
        case settingButtonDidTap
        case settingsCore(SettingsCore.Action)
        case noticeCore(NoticeCore.Action)
        case settingsDismissed
        case checkVersion(TaskResult<String>)
        case fetchEmergencyNotice(TaskResult<EmegencyNotice?>)
        case noticeToastDismissed
        case noticeButtonDidTap
        case noticeDismissed
    }

    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.iTunesClient) var iTunesClient
    @Dependency(\.noticeClient) var noticeClient

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if userDefaultsClient.getValue(.isSkipWeekend) as? Bool == true {
                    if state.displayDate.weekday == 7 {
                        state.displayDate = state.displayDate.adding(by: .day, value: 2)
                    } else if state.displayDate.weekday == 1 {
                        state.displayDate = state.displayDate.adding(by: .day, value: 1)
                    }
                }
                state.school = userDefaultsClient.getValue(.school) as? String ?? ""
                state.grade = "\(userDefaultsClient.getValue(.grade) as? Int ?? 1)"
                state.class = "\(userDefaultsClient.getValue(.class) as? Int ?? 1)"
                if state.mealCore == nil {
                    state.mealCore = .init()
                }
                if state.timeTableCore == nil {
                    state.timeTableCore = .init()
                }
                return .merge(
                    .run { send in
                        let checkVersion = await Action.checkVersion(
                            TaskResult {
                                try await iTunesClient.fetchCurrentVersion(.ios)
                            }
                        )
                        await send(checkVersion)
                    },
                    .run { send in
                        let fetchEmergencyNotice = await Action.fetchEmergencyNotice(
                            TaskResult {
                                try await noticeClient.fetchEmergencyNotice()
                            }
                        )
                        await send(fetchEmergencyNotice)
                    }
                )

            case .mealCore(.refresh), .timeTableCore(.refresh):
                state.displayDate = Date()
                if userDefaultsClient.getValue(.isSkipWeekend) as? Bool == true {
                    if state.displayDate.weekday == 7 {
                        state.displayDate = state.displayDate.adding(by: .day, value: 2)
                    } else if state.displayDate.weekday == 1 {
                        state.displayDate = state.displayDate.adding(by: .day, value: 1)
                    }
                }

            case let .tabChanged(tab):
                state.currentTab = tab

            case .settingButtonDidTap:
                state.settingsCore = .init()
                state.isNavigateSettings = true

            case .mealCore(.settingsButtonDidTap):
                state.settingsCore = .init()
                state.isNavigateSettings = true

            case .settingsDismissed:
                state.settingsCore = nil
                state.isNavigateSettings = false

            case .settingsCore(.allergySettingCore(.saveButtonDidTap)):
                state.settingsCore = nil
                state.isNavigateSettings = false

            case .settingsCore(.schoolSettingCore(.schoolSettingFinished)):
                state.settingsCore = nil
                state.isNavigateSettings = false

            case let .checkVersion(.success(latestVersion)):
                guard !latestVersion.isEmpty else { break }
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                state.isExistNewVersion = currentVersion != latestVersion

            case let .fetchEmergencyNotice(.success(notice)):
                guard let notice, state.isInitial else { break }
                state.notice = notice
                state.isInitial = false

            case .noticeToastDismissed:
                state.notice = nil
                return .none

            case .noticeButtonDidTap:
                guard let notice = state.notice else { break }
                state.noticeCore = .init(emegencyNotice: notice)
                return .none

            case .noticeDismissed:
                state.notice = nil
                state.noticeCore = nil

            default:
                return .none
            }
            return .none
        }
        .ifLet(\.mealCore, action: /Action.mealCore) {
            MealCore()
        }
        .ifLet(\.timeTableCore, action: /Action.timeTableCore) {
            TimeTableCore()
        }
        .ifLet(\.settingsCore, action: /Action.settingsCore) {
            SettingsCore()
        }
        .ifLet(\.noticeCore, action: /Action.noticeCore) {
            NoticeCore()
        }
    }
}
