//
//  ServiceView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - Service View (Main Dashboard)
// หน้าหลักของแอป (Dashboard) แสดงรายการบริการต่างๆ
// ผู้ใช้ทั้งแบบ Guest และ Logged-in จะเห็นหน้านี้ แต่จะเข้าถึงฟีเจอร์ได้ต่างกัน
struct ServiceView: View {
    // MARK: - SYSTEM LOGIC (DO NOT CHANGE)
    @EnvironmentObject var appState: AppState
    @StateObject var socialVM = SocialViewModel()
    
    @State private var showBookingSpace = false // State สำหรับเปิดหน้าจอง (เฉพาะ Logged-in)
    @State private var showSocialBoard = false  // State สำหรับเปิดหน้า Social (เฉพาะ Logged-in)
    
    @State private var showingLoginAlert = false // Alert แจ้งเตือนให้ล็อกอิน
    @State private var navigateToLoginFromAlert = false // Trigger นำทางไปหน้า Login จาก Alert

    var body: some View {
        ZStack {
            // 1. Background (ใช้กราฟิกแบบสุ่มเหมือนเดิม)
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // ---------------------------------------
                // HEADER SECTION
                // ส่วนหัวแสดงปุ่ม Login/Logout และข้อความต้อนรับ
                // ---------------------------------------
                VStack(alignment: .leading, spacing: 10) {
                    // Top Toolbar (Logout / Login)
                    HStack {
                        Spacer()
                        if appState.isLoggedIn {
                            // ปุ่ม Logout (แสดงเมื่อล็อกอินแล้ว)
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
                            // ปุ่ม Login (แสดงเมื่อเป็น Guest)
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
                // ส่วนเมนูบริการ (Grid 2 คอลัมน์)
                // ---------------------------------------
                ZStack {
                    Color.Theme.white
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
                                
                                // 1. Activity / Event Button (เข้าได้ทุกคน แต่เนื้อหาข้างในต่างกัน)
                                NavigationLink(destination: destinationForActivity()) {
                                    ServiceCardNew(
                                        icon: "calendar.badge.clock",
                                        title: "Activity",
                                        subtitle: "กิจกรรม / อีเว้นท์",
                                        color: Color.Theme.primary
                                    )
                                }
                                
                                // 2. Booking Space Button (ต้องล็อกอิน)
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
                                
                                // 3. Campus Map Button (เข้าได้ทุกคน)
                                NavigationLink(destination: CampusMapView()) {
                                    ServiceCardNew(
                                        icon: "map.fill",
                                        title: "Campus Map",
                                        subtitle: "แผนที่มหาลัย",
                                        color: Color.green
                                    )
                                }
                                
                                // 4. SWU Board Button (Social - ต้องล็อกอิน)
                                Button(action: {
                                    if appState.isLoggedIn {
                                        showSocialBoard = true // สั่งให้เปลี่ยนหน้า
                                    } else {
                                        showingLoginAlert = true
                                    }
                                }) {
                                    ServiceCardNew(
                                        icon: "bubble.left.and.bubble.right.fill",
                                        title: "SWU Board",
                                        subtitle: "พูดคุย/ข่าวสาร",
                                        color: Color.purple
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 50)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom) // ให้ Card ชิดขอบล่าง
            
            // --- Hidden Navigation Links ---
            // ใช้สำหรับ Programmatic Navigation (สั่งเปลี่ยนหน้าด้วย Code)
            NavigationLink(destination: LoginView().environmentObject(appState), isActive: $navigateToLoginFromAlert) { EmptyView() }
            NavigationLink(destination: BookingView().environmentObject(appState), isActive: $showBookingSpace) { EmptyView() }
            NavigationLink(destination: destinationForSocial(), isActive: $showSocialBoard) { EmptyView() }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("ServiceView ปรากฏขึ้น. isLoggedIn: \(appState.isLoggedIn)")
            socialVM.checkAdminStatus() // สั่งเช็คสิทธิ์ Admin ทุกครั้งที่หน้านี้โผล่มา
        }
        .alert("เข้าสู่ระบบ", isPresented: $showingLoginAlert) {
            Button("ตกลง", role: .cancel) {
                navigateToLoginFromAlert = true // เพิ่มให้กดตกลงแล้วไปหน้า Login เลย
            }
        } message: {
            Text("คุณต้องเข้าสู่ระบบก่อนจึงจะสามารถใช้งานฟีเจอร์นี้ได้")
        }
    }
    
    // MARK: - Navigation Logic
    
    // Logic เลือกปลายทาง Activity (Student vs Guest)
    @ViewBuilder
    func destinationForActivity() -> some View {
        if appState.isLoggedIn {
            StudentActivityListView().environmentObject(appState)
        } else {
            GuestActivityListView().environmentObject(appState)
        }
    }
    
    // Logic เลือกปลายทาง Social Board (Admin vs Student)
    @ViewBuilder
    func destinationForSocial() -> some View {
        if socialVM.isAdmin {
            AdminSocialBoardView() // ไปหน้า Admin
        } else {
            SocialBoardView()      // ไปหน้านิสิต
        }
    }
}

// MARK: - NEW SERVICE CARD COMPONENT
// การ์ดเมนูบริการ (Reusable Component)
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
        .background(Color.Theme.white)
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
