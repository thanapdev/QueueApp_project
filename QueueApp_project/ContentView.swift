import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        
        Group {
            if appState.isLoggedIn {
                // --- 1. ผู้ใช้ Login แล้ว ---
                loggedInDestinationView()
                    .environmentObject(appState)
                
            } else {
                // --- 2. สถานะเริ่มต้น (ยังไม่ Login) ---
                // ให้เริ่มที่ WelcomeView เสมอ
                // WelcomeView จะมี NavigationStack ของตัวเอง
                // เพื่อจัดการ Flow ของ Guest (Welcome -> Login -> Service)
                WelcomeView()
                    .environmentObject(appState)
            }
        }
        .transition(.opacity) // แอนิเมชันตอนสลับหน้าจอ
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
    }
    
    // Helper ViewBuilder สำหรับแยก Logic ของคน Login แล้ว
    @ViewBuilder
    private func loggedInDestinationView() -> some View {
        // ตรวจสอบ currentUser เผื่อไว้
        if let user = appState.currentUser {
            if user.role == .admin {
                // Admin: ไปหน้า Activity List
                NavigationStack {
                    ActivityListView() // <--- ต้องมี View นี้
                        .environmentObject(appState)
                }
            } else {
                // Student: ไปหน้า ServiceView
                NavigationStack {
                    ServiceView()
                        .environmentObject(appState)
                }
            }
        } else {
            // กรณี Error (ไม่ควรเกิด)
            // อาจจะแสดงหน้า Loading หรือ LoginView ไปเลยก็ได้
            Text("Error: Logged in but no user data.")
        }
    }
}
