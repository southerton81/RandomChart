import SwiftUI

@main
struct ChartApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView(CoreDataInventory.instance, MainTabView(
                ChartView(PositionsView()).environment(\.managedObjectContext, CoreDataInventory.instance.viewContext),
                LeaderboardView(CoreDataInventory.instance)
            )).onAppear {
                UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont.systemFont(ofSize: 28, weight: .bold)]
            }
        }
    }
}
