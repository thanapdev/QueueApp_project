import SwiftUI

// MARK: - Content View (Root View)
// หน้าจอหลักที่เป็นตัวกำหนดว่าจะแสดงหน้าไหน (Login หรือ หน้าใช้งานจริง)
struct ContentView: View {
    // รับค่า AppState มาจาก @main (QueueApp_projectApp)
    // รับค่า AppState มาจาก @main (QueueApp_projectApp)
    @EnvironmentObject var appState: AppState

    var body: some View {
        
        Group {
            if appState.isLoggedIn {
                // 1. กรณีผู้ใช้ Login แล้ว
                // เรียกฟังก์ชันเพื่อตัดสินใจว่าจะไปหน้า Student หรือ Admin
                loggedInDestinationView()
                    .environmentObject(appState)
                
            } else {
                // 2. สถานะเริ่มต้น (ยังไม่ Login)
                // ให้เริ่มที่ WelcomeView เสมอ
                // WelcomeView จะมี NavigationStack ของตัวเอง
                // เพื่อจัดการ Flow ของ Guest (Welcome -> Login -> Service)
                WelcomeView()
                    .environmentObject(appState)
            }
        }
        .transition(.opacity) // แอนิเมชันตอนสลับหน้าจอ (Fade in/out)
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
    }
    
    // MARK: - Navigation Logic
    // Helper ViewBuilder สำหรับแยก Logic ของคน Login แล้ว
    @ViewBuilder
    private func loggedInDestinationView() -> some View {
        // ตรวจสอบ currentUser ว่ามีข้อมูลหรือไม่
        if let user = appState.currentUser {
            if user.role == .admin {
                // Case: Admin -> ไปหน้า Admin Dashboard
                NavigationStack {
                    AdminDashboardView() 
                        .environmentObject(appState)
                }
            } else {
                // Case: Student -> ไปหน้า ServiceView (หน้าหลักของนิสิต)
                NavigationStack {
                    ServiceView()
                        .environmentObject(appState)
                }
            }
        } else {
            // Case: Error (Login แล้วแต่ไม่มีข้อมูล User)
            // แสดงข้อความ Error หรืออาจจะดีดกลับไปหน้า Login
            Text("Error: Logged in but no user data.")
        }
    }
}
