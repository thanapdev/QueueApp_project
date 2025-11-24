import SwiftUI
import FirebaseCore
import FirebaseFirestore

// MARK: - App Delegate
// คลาสสำหรับจัดการ Lifecycle ของแอปพลิเคชัน และการตั้งค่าเริ่มต้น (เช่น Firebase)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // เริ่มต้นการทำงานของ Firebase เมื่อแอปเปิดขึ้นมา
        FirebaseApp.configure()
        return true
    }
}

@main
struct QueueApp_projectApp: App {
    // เชื่อมต่อ AppDelegate เข้ากับ SwiftUI App Lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // สร้าง AppState (Global State) เพียงตัวเดียวและส่งต่อให้ทุก View ในแอป
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            // เริ่มต้นที่ ContentView และส่ง environmentObject 'appState' ไปให้
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}
