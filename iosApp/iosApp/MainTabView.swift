import Foundation
import SwiftUI

struct MainTabView<Chart: View>: View {
    
    let chartView: Chart
    
    init(_ chartView: Chart) {
        self.chartView = chartView
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
            LeaderboardView()
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
