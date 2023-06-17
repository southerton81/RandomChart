import Foundation
import SwiftUI

struct MainTabView<ChartView: View, ProfileView: View>: View {
    private let chartView: ChartView
    private let leaderboardView: LeaderboardView
    private let profileView: ProfileView
    
    init(_ chartView: ChartView, _ leaderboardView: LeaderboardView, _ profileView: ProfileView) {
        self.chartView = chartView
        self.leaderboardView = leaderboardView
        self.profileView = profileView
    }
    
    var body: some View {
        TabView {
            VStack {
                self.chartView
            }
            .tabItem {
                Image(systemName: "chart.xyaxis.line")
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
        }.onAppear {
            if #available(iOS 15.0, *) {
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithDefaultBackground()
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
}
