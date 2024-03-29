import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct SchoolMajorSheetView: View {
    let store: StoreOf<SchoolMajorSheetCore>
    @ObservedObject var viewStore: ViewStoreOf<SchoolMajorSheetCore>

    public init(store: StoreOf<SchoolMajorSheetCore>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(viewStore.majorList, id: \.self) { major in
                        Button {
                            viewStore.send(.majorRowDidSelect(major), animation: .default)
                        } label: {
                            schoolMajorRowView(major: major)
                        }
                        .padding(.horizontal, 32)
                    }
                }
            }
            .padding(.top, 32)
        }
    }

    @ViewBuilder
    private func schoolMajorRowView(major: String) -> some View {
        HStack {
            Text(major)
                .twFont(.headline4, color: .textPrimary)

            Spacer()

            TWRadioButton(isChecked: viewStore.selectedMajor == major) {
                viewStore.send(.majorRowDidSelect(major), animation: .default)
            }
        }
        .padding(.vertical, 16)
    }
}
