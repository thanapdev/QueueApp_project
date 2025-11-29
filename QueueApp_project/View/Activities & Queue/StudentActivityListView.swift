//
//  StudentActivityListView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - Student Activity List View
// หน้ารายการกิจกรรมสำหรับนิสิต (Legacy Queue System)
// ทำหน้าที่:
// 1. แสดงรายการกิจกรรมทั้งหมดแบบ Real-time
// 2. แสดงจำนวนคนรอคิว (queueCount)
// 3. นำทางไปหน้าต่อคิว (StudentQueueJoinView)
struct StudentActivityListView: View {
    @EnvironmentObject var appState: AppState               // Global state
    @Environment(\.presentationMode) var presentationMode   // ใช้สำหรับปิดหน้านี้
    
    let gridColumns = [                                     // Grid 2 คอลัมน์สำหรับการ์ดกิจกรรม
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ZStack {
            // Background Theme
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        // ปุ่ม Back แบบไม่ใช้ Navigation Link เพื่อความสวยงาม
                        Button(action: {
                            // เช็กก่อนว่ามีให้ Dismiss ไหม ถ้าไม่มี (เช่นเป็น Root view) ก็ไม่ทำอะไร
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline).foregroundColor(.white)
                            .padding(.vertical, 8).padding(.horizontal, 12)
                            .background(Color.white.opacity(0.2)).clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        // User Profile Badge
                        HStack(spacing: 8) {
                            Text(appState.currentUser?.name ?? "Student")
                                .font(.subheadline).fontWeight(.bold).foregroundColor(Color.Theme.primary)
                            Image(systemName: "person.fill").foregroundColor(Color.Theme.primary)
                        }
                        .padding(.vertical, 6).padding(.horizontal, 12)
                        .background(Color.white).clipShape(Capsule()).shadow(radius: 5)
                    }
                    .padding(.top, 50)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Student Activities")
                            .font(.system(size: 32, weight: .bold)).foregroundColor(.white)
                        Text("เลือกกิจกรรมที่ต้องการเข้าร่วม")
                            .font(.body).foregroundColor(Color.white.opacity(0.9))
                    }
                    .padding(.top, 15)
                }
                .padding(.horizontal, 30).padding(.bottom, 30)
                
                // List Content (White Sheet)
                ZStack {
                    Color.Theme.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    if appState.activities.isEmpty {
                        // Empty State
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 60)).foregroundColor(Color.gray.opacity(0.3))
                            Text("ยังไม่มีกิจกรรมให้เข้าร่วมในขณะนี้")
                                .font(.headline).foregroundColor(Color.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Activities List
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                // ใช้ indices loop เพื่อส่ง activity object ตัวจริงให้ ObservedObject ทำงาน
                                ForEach(appState.activities.indices, id: \.self) { index in
                                    let activity = appState.activities[index]
                                    
                                    NavigationLink(
                                        destination: StudentQueueJoinView(activity: activity).environmentObject(appState)
                                    ) {
                                        ActivityCardView(activity: activity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.top, 30).padding(.horizontal, 30).padding(.bottom, 50)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
    }
}
