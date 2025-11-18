import SwiftUI

struct ServiceView: View {
    // MARK: - SYSTEM LOGIC (DO NOT CHANGE)
    @EnvironmentObject var appState: AppState
    @State private var showBookingSpace = false // สำหรับ Logged-in user
    @State private var showingLoginAlert = false
    @State private var navigateToLoginFromAlert = false // สำหรับ Alert -> Login

    var body: some View {
        ZStack {
            // 1. Background (ใช้กราฟิกแบบสุ่มเหมือนเดิม)
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // ---------------------------------------
                // HEADER SECTION
                // ---------------------------------------
                VStack(alignment: .leading, spacing: 10) {
                    // Top Toolbar (Logout / Login)
                    HStack {
                        Spacer()
                        if appState.isLoggedIn {
                            Button(action: {
                                appState.logout()
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        } else {
                            Button(action: {
                                navigateToLoginFromAlert = true
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "person.circle.fill")
                                    Text("Login")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 50)
                    
                    // Welcome Text
                    VStack(alignment: .leading, spacing: 5) {
                        Text(appState.isLoggedIn ? "Hello, Student!" : "Hello, Guest!")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("เลือกใช้บริการที่คุณต้องการ")
                            .font(.body)
                            .foregroundColor(Color.white.opacity(0.9))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                // ---------------------------------------
                // SERVICE MENU (White Card Area)
                // ---------------------------------------
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Services")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color.Theme.textDark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 30)
                                .padding(.bottom, 10)
                            
                            // Grid Menu (2 Columns)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                                
                                // 1. Activity / Event Button
                                NavigationLink(destination: destinationForActivity()) {
                                    ServiceCardNew(
                                        icon: "calendar.badge.clock",
                                        title: "Activity",
                                        subtitle: "กิจกรรม / อีเว้นท์",
                                        color: Color.Theme.primary
                                    )
                                }
                                
                                // 2. Booking Space Button
                                Button(action: {
                                    if appState.isLoggedIn {
                                        showBookingSpace = true
                                    } else {
                                        showingLoginAlert = true
                                    }
                                }) {
                                    ServiceCardNew(
                                        icon: "table.furniture",
                                        title: "Booking",
                                        subtitle: "จองพื้นที่",
                                        color: Color.Theme.secondary
                                    )
                                }
                                
                                // (Optional) 3. Map (Example for future)
                                ServiceCardNew(
                                    icon: "map.fill",
                                    title: "Campus Map",
                                    subtitle: "แผนที่มหาลัย",
                                    color: Color.gray.opacity(0.5)
                                )
                                .opacity(0.6) // ทำให้ดูเป็น Disabled
                                
                                // (Optional) 4. Profile (Example)
                                ServiceCardNew(
                                    icon: "person.crop.circle",
                                    title: "Profile",
                                    subtitle: "ข้อมูลส่วนตัว",
                                    color: Color.gray.opacity(0.5)
                                )
                                .opacity(0.6)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 50)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom) // ให้ Card ชิดขอบล่าง
            
            // --- Hidden Navigation Links ---
            NavigationLink(destination: LoginView().environmentObject(appState), isActive: $navigateToLoginFromAlert) { EmptyView() }
            
            // แก้ไข: ต้องมี View ปลายทางจริงๆ (BookingView)
            NavigationLink(destination: BookingView().environmentObject(appState), isActive: $showBookingSpace) { EmptyView() }
//             NavigationLink(destination: Text("Booking View (Coming Soon)"), isActive: $showBookingSpace) { EmptyView() } // Placeholder
        }
        .navigationBarHidden(true)
        .onAppear {
            print("ServiceView ปรากฏขึ้น. isLoggedIn: \(appState.isLoggedIn)")
        }
        .alert("เข้าสู่ระบบ", isPresented: $showingLoginAlert) {
            Button("ตกลง", role: .cancel) { }
        } message: {
            Text("คุณต้องเข้าสู่ระบบก่อนจึงจะสามารถจองพื้นที่ได้")
        }
    }
    
    // Logic เลือกปลายทาง Activity
    @ViewBuilder
    func destinationForActivity() -> some View {
        if appState.isLoggedIn {
             StudentActivityListView().environmentObject(appState) // Uncomment เมื่อมีไฟล์จริง
            /*Text("Student Activity List (Coming Soon)")*/ // Placeholder
        } else {
             GuestActivityListView().environmentObject(appState) // Uncomment เมื่อมีไฟล์จริง
            /*Text("Guest Activity List (Coming Soon)")*/ // Placeholder
        }
    }
}

// MARK: - NEW SERVICE CARD COMPONENT
struct ServiceCardNew: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 15) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
            }
            
            // Text Info
            VStack(spacing: 5) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Theme.textDark)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ServiceView_Previews: PreviewProvider {
    static var previews: some View {
        ServiceView()
            .environmentObject(AppState())
    }
}
