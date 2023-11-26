
import SwiftUI

@main
struct ChartApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView(CoreDataInventory.instance, MainTabView(
                ChartView().environment(\.managedObjectContext, CoreDataInventory.instance.viewContext),
                LeaderboardView(),
                ProfileView().environment(\.managedObjectContext, CoreDataInventory.instance.viewContext)
            )).onAppear {
                UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont.systemFont(ofSize: 28, weight: .bold)]
            }
        }
    }
}
