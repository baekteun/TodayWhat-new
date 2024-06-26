import ComposableArchitecture
import Entity
import Foundation
import ITunesClient
import LocalDatabaseClient
import SchoolClient
import UserDefaultsClient

struct SettingsCore: Reducer {
    enum FocusState: Hashable {
        case school
        case grade
        case `class`
    }

    struct State: Equatable {
        var focusState: FocusState? = nil
        var schoolText = ""
        var gradeText = ""
        var classText = ""
        var majorText: String = ""
        var schoolList: [School] = []
        var schoolMajorList: [String] = []
        var isLoading = false
        var isSkipWeekend = false
        var isSkipAfterDinner = true
        var isNewVersionExist = false
    }

    enum Action: Equatable {
        case onAppear
        case setFocusState(FocusState?)
        case setSchoolText(String)
        case setGradeText(String)
        case setClassText(String)
        case setIsSkipWeekend(Bool)
        case setIsSkipAfterDinner(Bool)
        case schoolListResponse(TaskResult<[School]>)
        case schoolMajorListResponse(TaskResult<[String]>)
        case versionCheck(TaskResult<String>)
        case schoolDidSelect(School)
        case majorDidSelect(String)
    }

    @Dependency(\.userDefaultsClient) var userDefaultsClient
    @Dependency(\.schoolClient) var schoolClient
    @Dependency(\.localDatabaseClient) var localDatabaseClient
    @Dependency(\.iTunesClient) var iTunesClient

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            guard
                let school = userDefaultsClient.getValue(.school) as? String,
                let grade = userDefaultsClient.getValue(.grade) as? Int,
                let `class` = userDefaultsClient.getValue(.class) as? Int
            else {
                break
            }
            state.schoolText = school
            state.gradeText = "\(grade)"
            state.classText = "\(`class`)"
            state.isSkipWeekend = userDefaultsClient.getValue(.isSkipWeekend) as? Bool ?? false
            state.isSkipAfterDinner = userDefaultsClient.getValue(.isSkipAfterDinner) as? Bool ?? true
            state.majorText = userDefaultsClient.getValue(.major) as? String ?? ""
            let majorList = try? localDatabaseClient.readRecords(as: SchoolMajorLocalEntity.self)
                .map(\.major)
            state.schoolMajorList = majorList ?? []
            return .run { send in
                let action = await Action.versionCheck(
                    TaskResult {
                        try await iTunesClient.fetchCurrentVersion(.macos)
                    }
                )
                await send(action)
            }

        case let .setFocusState(focusState):
            state.focusState = focusState

        case let .setSchoolText(school):
            state.schoolText = school
            state.isLoading = true
            return .run { send in
                let action = await Action.schoolListResponse(
                    TaskResult {
                        try await schoolClient.fetchSchoolList(school)
                    }
                )
                await send(action)
            }

        case let .setGradeText(grade):
            state.gradeText = grade
            if !grade.isEmpty {
                userDefaultsClient.setValue(.grade, Int(grade) ?? 1)
            }

        case let .setClassText(`class`):
            state.classText = `class`
            if !`class`.isEmpty {
                userDefaultsClient.setValue(.class, Int(`class`) ?? 1)
            }

        case let .setIsSkipWeekend(isSkipWeekend):
            state.isSkipWeekend = isSkipWeekend
            userDefaultsClient.setValue(.isSkipWeekend, isSkipWeekend)

        case let .setIsSkipAfterDinner(isSkipAfterDinner):
            state.isSkipAfterDinner = isSkipAfterDinner
            userDefaultsClient.setValue(.isSkipAfterDinner, isSkipAfterDinner)

        case let .schoolListResponse(.success(schoolList)):
            state.schoolList = schoolList
            state.isLoading = false

        case .schoolListResponse(.failure(_)):
            state.isLoading = false

        case let .schoolMajorListResponse(.success(majorList)):
            var majorList = majorList
            majorList.insert("", at: 0)
            state.schoolMajorList = majorList
            try? localDatabaseClient.deleteAll(record: SchoolMajorLocalEntity.self)
            try? localDatabaseClient.save(records: majorList.map { SchoolMajorLocalEntity(major: $0) })
            state.isLoading = false

        case .schoolMajorListResponse(.failure(_)):
            state.isLoading = false

        case let .versionCheck(.success(latestVersion)):
            guard !latestVersion.isEmpty else { break }
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            state.isNewVersionExist = latestVersion != currentVersion

        case let .schoolDidSelect(school):
            state.schoolText = school.name
            state.majorText = ""
            state.focusState = nil
            userDefaultsClient.setValue(.orgCode, school.orgCode)
            userDefaultsClient.setValue(.schoolType, school.schoolType.rawValue)
            userDefaultsClient.setValue(.schoolCode, school.schoolCode)
            userDefaultsClient.setValue(.school, school.name)
            return .run { [orgCode = school.orgCode, schoolCode = school.schoolCode] send in
                let action = await Action.schoolMajorListResponse(
                    TaskResult {
                        try await schoolClient.fetchSchoolsMajorList(orgCode, schoolCode)
                    }
                )
                await send(action)
            }

        case let .majorDidSelect(major):
            state.majorText = major == "선택안함" ? "" : major
            userDefaultsClient.setValue(.major, major == "선택안함" ? nil : major)

        default:
            return .none
        }

        return .none
    }
}
