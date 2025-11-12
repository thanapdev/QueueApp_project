import SwiftUI

@main
struct QueueApp_projectApp: App { // Replace QueueApp_projectApp with your actual app name
    @StateObject var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appState)
        }
    }
}
