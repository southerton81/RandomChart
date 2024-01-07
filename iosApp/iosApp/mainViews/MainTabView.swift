import Foundation
import SwiftUI

struct MainTabView<ChartView: View, ProfileView: View>: View {
    @EnvironmentObject var chartObservable: ChartObservableObject
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    
    private let chartView: ChartView
    private let leaderboardView: LeaderboardView
    private let profileView: ProfileView
    @State var tabSelection = 1
    
    init(_ chartView: ChartView, _ leaderboardView: LeaderboardView, _ profileView: ProfileView) {
        self.chartView = chartView
        self.leaderboardView = leaderboardView
        self.profileView = profileView
    }
    
    var body: some View {
        ZStack {
            if self.positionsObservable.endSessionCondition != nil {
                SessionResultView(tabSelection: $tabSelection)
                    .environmentObject(self.chartObservable)
                    .environmentObject(self.positionsObservable)
                    .zIndex(2)
                    .deferredRendering(seconds: 1.0)
            }
            TabView(selection: $tabSelection) {
                VStack {
                    self.chartView
                }
                .tabItem {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Chart")
                }
                .tag(1)
                
                self.leaderboardView
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottom
                    )
                    .tabItem {
                        Image(systemName: "person.3.fill")
                        Text("Leaderboard")
                    }
                    .tag(2)
                
                self.profileView
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottom
                    )
                    .tabItem {
                        Image(systemName: "list.dash")
                        Text("History")
                    }
                    .tag(3)
            }.onAppear {
                if #available(iOS 15.0, *) {
                    let tabBarAppearance = UITabBarAppearance()
                    tabBarAppearance.configureWithDefaultBackground()
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
            }
            .zIndex(1)
        }
        .animation(.easeInOut)
    }
}
