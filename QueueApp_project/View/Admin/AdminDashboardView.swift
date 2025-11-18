//
//  AdminDashboardView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 18/11/2568 BE.
//


import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack {
                // MARK: - Header
                HStack {
                    // Profile Icon
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                        .clipShape(Circle())
                    
                    // User Name (หรือ Admin User)
                    Text(appState.currentUser?.name ?? "Admin User")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Logout Button (เพิ่มเข้ามาใหม่)
                    Button("Logout") {
                        appState.logout() // เรียกฟังก์ชัน logout จาก AppState
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red) // ใช้สีแดงเพื่อให้เด่นชัด
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // MARK: - Search Bar
//                HStack {
//                    Image(systemName: "magnifyingglass")
//                        .foregroundColor(.gray)
//                    TextField("Search", text: .constant("")) // ตอนนี้เป็น Textfield จำลอง
//                        .padding(.vertical, 8)
//                }
//                .padding(.horizontal)
//                .background(Capsule().fill(Color.gray.opacity(0.1)))
//                .padding()
                
                // MARK: - Admin Dashboard Title
                Text("Admin Dashboard")
                    .font(.headline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .foregroundColor(.gray)
                
                // MARK: - Feature Cards (Activities & Bookings)
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // Card 1: Activities
                        NavigationLink(destination: ActivityListView().environmentObject(appState)) {
                            DashboardCardView(
                                title: "Activities",
                                description: "Manage student queue activities",
                                mainIcon: "list.bullet.rectangle.portrait.fill", // เปลี่ยนเป็นไอคอนที่ดูเกี่ยวกับการจัดการคิว
                                secondaryIcon: "bookmark.fill", // ไอคอนเล็กด้านขวาบน
                                themeColor: Color.blue // สีที่ใช้ใน Card
                            )
                        }
                        
                        // Card 2: Bookings
                        NavigationLink(destination: AdminBookingView().environmentObject(appState)) {
                            DashboardCardView(
                                title: "Bookings",
                                description: "View and manage library bookings",
                                mainIcon: "calendar.badge.checkmark", // เปลี่ยนเป็นไอคอนที่ดูเกี่ยวกับการจอง
                                secondaryIcon: "bookmark.fill", // ไอคอนเล็กด้านขวาบน
                                themeColor: Color.purple // สีที่ใช้ใน Card
                            )
                        }
                        
                        // สามารถเพิ่ม Card อื่นๆ ได้ที่นี่
                        
                    }
                    .padding()
                }
                
                Spacer()
            }
            .background(Color.white.ignoresSafeArea()) // สีพื้นหลังของ Dashboard
            .navigationBarHidden(true) // ซ่อน Navigation Bar เพราะเราทำ Header เอง
        }
    }
}

// MARK: - Helper View: DashboardCardView
// Component สำหรับสร้าง Card แต่ละอัน
struct DashboardCardView: View {
    let title: String
    let description: String
    let mainIcon: String
    let secondaryIcon: String
    let themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Main Icon
                Image(systemName: mainIcon)
                    .font(.system(size: 40))
                    .foregroundColor(themeColor)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(themeColor.opacity(0.1)))
                
                Spacer()
                
                // Secondary Icon (Bookmark)
                Image(systemName: secondaryIcon)
                    .font(.title2)
                    .foregroundColor(themeColor)
            }
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            Spacer()
            
            // Arrow Button
            HStack {
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundColor(themeColor)
                    .padding(8)
                    .background(Circle().fill(themeColor.opacity(0.1)))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 180) // ขยาย Card ให้เต็มความกว้าง
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}


#Preview {
    AdminDashboardView()
        .environmentObject(AppState())
}
