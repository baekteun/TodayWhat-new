import AllergySettingFeature
import ComposableArchitecture
import SchoolSettingFeature
import UserDefaultsClient

public struct SettingsCore: ReducerProtocol {
    public init() {}

    public struct State: Equatable {
        public var schoolName: String = ""
        public var grade: Int = 0
        public var `class`: Int = 0
        public var isSkipWeekend: Bool = false
        public var schoolSettingCore: SchoolSettingCore.State? = nil
        public var isNavigateSchoolSetting: Bool = false
        public var allergySettingCore: AllergySettingCore.State? = nil
        public var isNavigateAllergySetting: Bool = false
        public var confirmationDialog: ConfirmationDialogState<Action>? = nil
        public var alert: AlertState<Action>? = nil

        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case isSkipWeekendChanged(Bool)
        case schoolBlockButtonDidTap
        case schoolSettingDismissed
        case schoolSettingCore(SchoolSettingCore.Action)
        case allergyBlockButtonDidTap
        case allergySettingDismissed
        case allergySettingCore(AllergySettingCore.Action)
        case consultingButtonDidTap
    }

    @Dependency(\.userDefaultsClient) var userDefaultsClient

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.schoolName = userDefaultsClient.getValue(.school) as? String ?? ""
                state.grade = userDefaultsClient.getValue(.grade) as? Int ?? 0
                state.class = userDefaultsClient.getValue(.class) as? Int ?? 0
                state.isSkipWeekend = userDefaultsClient.getValue(.isSkipWeekend) as? Bool ?? false

            case let .isSkipWeekendChanged(isSkipWeekend):
                state.isSkipWeekend = isSkipWeekend
                userDefaultsClient.setValue(.isSkipWeekend, isSkipWeekend)

            case .schoolBlockButtonDidTap:
                state.schoolSettingCore = .init()
                state.isNavigateSchoolSetting = true

            case .schoolSettingDismissed:
                state.schoolSettingCore = nil
                state.isNavigateSchoolSetting = false

            case .allergyBlockButtonDidTap:
                state.allergySettingCore = .init()
                state.isNavigateAllergySetting = true

            case .allergySettingDismissed:
                state.allergySettingCore = .init()
                state.isNavigateAllergySetting = false

            case .consultingButtonDidTap:
                break

            default:
                return .none
            }
            
            return .none
        }
        .ifLet(\.schoolSettingCore, action: /Action.schoolSettingCore) {
            SchoolSettingCore()
        }
        .ifLet(\.allergySettingCore, action: /Action.allergySettingCore) {
            AllergySettingCore()
        }
    }
}
