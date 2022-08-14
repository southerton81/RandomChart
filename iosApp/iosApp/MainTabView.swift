import Foundation
import SwiftUI

struct MainTabView<ChartView: View>: View {
    
    private let chartView: ChartView
    private let leaderboardView: LeaderboardView
    
    init(_ chartView: ChartView, _ leaderboardView: LeaderboardView) {
        self.chartView = chartView
        self.leaderboardView = leaderboardView
    }
    
    var body: some View {
        TabView {
            VStack {
                self.chartView
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Chart")
            }
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
            Text("Nearby Screen")
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("More")
                }
        }.onAppear {
            if #available(iOS 15.0, *) {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithDefaultBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
    
}
