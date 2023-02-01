import ComposableArchitecture
import Entity
import Foundation
import TimeTableClient

public struct TimeTableCore: ReducerProtocol {
    public init() {}
    public struct State: Equatable {
        public var timeTableList: [TimeTable] = []
        public var isLoading = false
        public var isError = false
        public var errorMessage = ""
        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case refresh
        case timeTableResponse(TaskResult<[TimeTable]>)
    }

    @Dependency(\.timeTableClient) var timeTableClient

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear, .refresh:
                state.isLoading = true
                return .task {
                    .timeTableResponse(
                        await TaskResult {
                            try await timeTableClient.fetchTimeTable(Date())
                        }
                    )
                }

            case let .timeTableResponse(.success(timeTableList)):
                state.isError = false
                state.isLoading = false
                state.timeTableList = timeTableList

            case let .timeTableResponse(.failure(error)):
                state.isError = true
                state.errorMessage = error.localizedDescription
                state.isLoading = false
            }
            return .none
        }
    }
}
