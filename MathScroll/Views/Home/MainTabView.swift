import SwiftUI

struct MainTabView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        TabView {
            NavigationStack { HomeView(profile: profile) }
                .tabItem { Label("Home", systemImage: "doc.text.fill") }
            NavigationStack { StatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            NavigationStack { UnlockTimerView() }
                .tabItem { Label("Unlock", systemImage: "lock.open.fill") }
            NavigationStack { SettingsView(profile: profile) }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .toolbarBackground(.regularMaterial, for: .tabBar)
    }
}
