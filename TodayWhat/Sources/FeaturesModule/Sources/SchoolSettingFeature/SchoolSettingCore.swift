import ComposableArchitecture
import Foundation
import Entity
import SchoolClient
import UserDefaultsClient
import SchoolMajorSheetFeature

public struct SchoolSettingCore: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        public var school = ""
        public var grade = ""
        public var `class` = ""
        public var major = ""
        public var selectedSchool: School?
        public var isFocusedSchool = false
        public var schoolMajorSheetCore: SchoolMajorSheetCore.State?
        public var isPresentedMajorSheet = false
        public var schoolList: [School] = []
        public var schoolMajorList: [String] = []
        public var isError = false
        public var errorMessage = ""
        public var isLoading = false

        public var titleMessage: String {
            if school.isEmpty {
                return "학교 이름을 입력해주세요!"
            } else if grade.isEmpty {
                return "몇학년 이신가요?"
            } else if `class`.isEmpty {
                return "몇반 이신가요?"
            } else if major.isEmpty && !schoolMajorList.isEmpty {
                return "특정 학과에 다니시나요?"
            } else {
                return "입력하신 정보가 정확한가요?"
            }
        }
        public var nextButtonTitle: String {
            if major.isEmpty || schoolMajorList.isEmpty {
                return "이대로하기"
            } else if !major.isEmpty || schoolMajorList.isEmpty {
                return "확인"
            }
            return "다음"
        }

        public init() {}
    }

    public enum Action: Equatable {
        case schoolChanged(String)
        case schoolFocusedChanged(Bool)
        case gradeChanged(String)
        case classChanged(String)
        case majorChanged(String)
        case schoolListResponse(TaskResult<[School]>)
        case schoolMajorListResponse(TaskResult<[String]>)
        case schoolRowDidSelect(School)
        case nextButtonDidTap
        case majorTextFieldDidTap
        case majorSheetDismissed
        case schoolMajorSheetCore(SchoolMajorSheetCore.Action)
        case schoolSettingFinished
    }

    @Dependency(\.schoolClient) var schoolClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    struct SchoolDebounceID: Hashable {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .schoolChanged(school):
                state.school = school
                state.isLoading = true
                return .task { [school = state.school] in
                    .schoolListResponse(
                        await TaskResult {
                            try await schoolClient.fetchSchoolList(school)
                        }
                    )
                }
                .debounce(id: SchoolDebounceID(), for: .milliseconds(150), scheduler: DispatchQueue.main)

            case let .schoolFocusedChanged(focused):
                state.isFocusedSchool = focused

            case let .gradeChanged(grade):
                state.grade = "\(grade)"

            case let .classChanged(`class`):
                state.class = "\(`class`)"

            case let .schoolListResponse(.success(list)):
                state.isLoading = false
                state.schoolList = list

            case let .schoolListResponse(.failure(error)):
                state.isLoading = false
                state.isError = true
                state.errorMessage = error.localizedDescription

            case let .schoolMajorListResponse(.success(majorList)):
                state.schoolMajorList = majorList

            case let .schoolMajorListResponse(.failure(error)):
                state.isError = true
                state.errorMessage = error.localizedDescription

            case let .schoolRowDidSelect(school):
                state.selectedSchool = school
                state.school = school.name
                state.isFocusedSchool = false
                state.major = ""
                return .task {
                    .schoolMajorListResponse(
                        await TaskResult {
                            try await schoolClient.fetchSchoolsMajorList(school.orgCode, school.schoolCode)
                        }
                    )
                }

            case .nextButtonDidTap:
                guard let selectedSchool = state.selectedSchool else { return .none }
                let dict: [(UserDefaultsKeys, Any?)] = [
                    (UserDefaultsKeys.school, state.school),
                    (.orgCode, selectedSchool.orgCode),
                    (.schoolCode, selectedSchool.schoolCode),
                    (.grade, Int(state.grade) ?? 1),
                    (.class, Int(state.class) ?? 1),
                    (.major, state.major.isEmpty ? nil : state.major),
                    (.schoolType, selectedSchool.schoolType.rawValue)
                ]
                dict.forEach {
                    userDefaultsClient.setValue($0.0, $0.1)
                }
                return .run { send in
                    await send(.schoolSettingFinished, animation: .default)
                }

            case .majorTextFieldDidTap:
                state.schoolMajorSheetCore = .init(majorList: state.schoolMajorList, selectedMajor: state.major)
                state.isPresentedMajorSheet = true

            case let .schoolMajorSheetCore(.majorRowDidSelect(major)):
                state.major = String(major)
                state.schoolMajorSheetCore = nil
                state.isPresentedMajorSheet = false

            case .majorSheetDismissed:
                state.schoolMajorSheetCore = nil
                state.isPresentedMajorSheet = false
            
            default:
                return .none
            }
            return .none
        }
        .ifLet(\.schoolMajorSheetCore, action: /Action.schoolMajorSheetCore) {
            SchoolMajorSheetCore()
        }
    }
}
