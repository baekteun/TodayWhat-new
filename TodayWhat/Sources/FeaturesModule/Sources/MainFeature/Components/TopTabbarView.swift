import SwiftUI
import TWColor

struct TopTabbarView: View {
    @Binding var currentTab: Int
    let items: [String]
    @Namespace var tabAnimation

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(items.indices, id: \.self) { index in
                    Button {
                        withAnimation {
                            currentTab = index
                        }
                    } label: {
                        VStack {
                            Text(items[index])
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.extraPrimary)

                            if currentTab == index {
                                RoundedRectangle(cornerRadius: 17)
                                    .fill(Color.extraPrimary)
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "TAB", in: tabAnimation)
                            } else {
                                Color.clear
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background {
                            Color.background
                        }
                        .padding(.horizontal, 16)
                    }

                }
            }

            LinearGradient(colors: [.background, .darkGray.opacity(0.08)], startPoint: .bottom, endPoint: .top)
                   .frame(height: 8)
                   .opacity(0.8)
        }
    }
}
