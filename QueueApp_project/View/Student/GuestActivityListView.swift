//
//  GuestActivityListView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


// GuestActivityListView.swift

import SwiftUI

struct GuestActivityListView: View {
    @EnvironmentObject var appState: AppState
    
    // ✅ State สำหรับควบคุมการแสดง Alert
    @State private var showLoginAlert = false
    
    // SWU Colors (From LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)
    
    var body: some View {
        ZStack {
                        // Background
                        LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                            .edgesIgnoringSafeArea(.all)

                        // Shape Background
                        GeometryReader { geometry in
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.24, green: 0.27, blue: 0.68, alpha: 1)), Color(#colorLiteral(red: 0.14, green: 0.64, blue: 0.96, alpha: 1))]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 200, height: 200)
                                .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.1)

                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.97, green: 0.32, blue: 0.18, alpha: 1)), Color(#colorLiteral(red: 0.94, green: 0.59, blue: 0.1, alpha: 1))]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 200, height: 200)
                                .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.9)
                        }
            VStack {
                // ✅ Top Bar (สำหรับ Guest)
                HStack {
                    // Guest Icon and Greeting
                    HStack {
                        Image(systemName: "person.circle") // Guest icon
                            .font(.title2)
                            .foregroundColor(swuGray) // ใช้สีเทา
                        Text("Guest User")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                    
                    // Login Button (ปุ่มนี้จะทำให้ย้อนกลับไปหน้า Login)
//                    Button(action: {
//                        print("GuestActivityListView: ปุ่ม Login ที่ Top Bar ถูกกด.")
//                        // เราจะใช้ .popToRoot หรือวิธีการที่เหมาะสม
//                        // ใน Flow ปัจจุบัน การเซ็ตค่านี้อาจไม่ทำงาน
//                        // เราควรใช้ NavigationLink หรือ Environment .dismiss
//                        
//                        // *** หมายเหตุ: Logic ปุ่มนี้ อาจจะต้องปรับปรุง ***
//                        // ถ้า GuestActivityListView อยู่ใน NavigationStack
//                        // เราอาจจะต้องใช้ @Environment(\.dismiss)
//                        
//                        // ลองใช้ Logic เดิมไปก่อน
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            appState.isBrowsingAsGuest = false
//                        }
//                    })
//                    {
//                        Text("Login")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 6)
//                    }
                    .background(swuRed) // ใช้สีแดง SWU
                    .cornerRadius(8)
                }
                .padding()
                .background(.white.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Activities List
                if appState.activities.isEmpty {
                    // "No Activities" Message (เหมือนเดิม)
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("ยังไม่มีกิจกรรมให้เข้าร่วม")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Activities List (using ScrollView and LazyVStack)
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(appState.activities.indices, id: \.self) { index in
                                let activity = appState.activities[index]
                                
                                // ✅ เปลี่ยนจาก NavigationLink เป็น Button
                                Button(action: {
                                    // เมื่อกด จะแสดง Alert แทนการนำทาง
                                    self.showLoginAlert = true
                                }) {
                                    HStack {
                                        Text(activity.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.black)
                                        Spacer()
                                        // ✅ แสดงจำนวนคิวเหมือนเดิม
                                        QueueCountBadge(activity: activity)
                                    }
                                    .padding()
                                    .background(.white)
                                    .cornerRadius(12)
                                    .shadow(radius: 3)
                                }
                                .buttonStyle(PlainButtonStyle()) // Remove button styling
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer() // Push content to the top
            }
            .contentShape(Rectangle())
            .background(.clear)
        }
        .navigationTitle("กิจกรรม")
        .navigationBarTitleDisplayMode(.inline)
        
        // --- ( ⭐️ ส่วนที่แก้ไข ⭐️ ) ---
        // ✅ .alert ที่แก้ไขแล้ว (มีปุ่ม "ตกลง" ปุ่มเดียว)
        .alert(isPresented: $showLoginAlert) {
            Alert(
                title: Text("กรุณา Login ก่อน"),
                message: Text("คุณต้องเข้าสู่ระบบเพื่อเข้าร่วมคิว"),
                dismissButton: .default(Text("ตกลง")) // <-- ปุ่ม "ตกลง" ปุ่มเดียว
            )
        }
        // --- ( ⭐️ สิ้นสุดส่วนที่แก้ไข ⭐️ ) ---
        
        // Moved .onAppear here, chained with the NavigationView modifiers
        .onAppear {
            appState.loadActivities()
            print("GuestActivityListView ปรากฏขึ้น. isBrowsingAsGuest: \(appState.isBrowsingAsGuest), isLoggedIn: \(appState.isLoggedIn)")
        }
    }
}

// (คุณต้องมี QueueCountBadge struct อยู่ในโปรเจกต์)
// struct QueueCountBadge: View { ... }

//#Preview {
//    GuestActivityListView()
//}
