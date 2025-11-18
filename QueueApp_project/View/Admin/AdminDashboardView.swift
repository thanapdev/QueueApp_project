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
            ZStack {
                // 1. Background
                DynamicBackground(style: .random)
                
                VStack(spacing: 0) {
                    // --- HEADER SECTION (Unchanged) ---
                    VStack(spacing: 15) {
                        HStack {
                            // Profile Icon & Name
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 44, height: 44)
                                    .shadow(radius: 2)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(Color.Theme.primary)
                                    .clipShape(Circle())
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.currentUser?.name ?? "Admin")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Administrator")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            // Logout Button
                            Button(action: {
                                appState.logout()
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                }
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Capsule())
                                .shadow(radius: 2)
                            }
                        }
                        
                        // Title
                        HStack {
                            Text("Dashboard")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // --- CONTENT AREA (White Sheet) ---
                    ZStack {
                        Color.white
                            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Overview")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.Theme.textDark)
                                    .padding(.top, 30)
                                
                                // NEW LAYOUT: Full-Width Stack (บน-ล่าง)
                                VStack(spacing: 16) {
                                    
                                    // Card 1: Activities (TOP - Full Width)
                                    NavigationLink(destination: ActivityListView().environmentObject(appState)) {
                                        AdminDashboardCard(
                                            title: "Activities Management",
                                            count: "\(appState.activities.count)",
                                            icon: "list.bullet.rectangle.portrait.fill",
                                            color: .blue
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Card 2: Bookings (BOTTOM - Full Width)
                                    NavigationLink(destination: AdminBookingView().environmentObject(appState)) {
                                        AdminDashboardCard(
                                            title: "Bookings Management",
                                            count: "\(appState.allAdminBookings.count)",
                                            icon: "calendar.badge.clock",
                                            color: .orange
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 50)
                        }
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .navigationBarHidden(true)
        }
        // ✅ FIX: Centralize loading and listening here
        .onAppear {
            // 1. ดึงรายการกิจกรรม (Activities)
            appState.loadActivities()
            // 2. เริ่ม Listener สำหรับการจองทั้งหมด (Bookings)
            appState.listenToAdminBookings()
        }
        .onDisappear {
            // หยุด Listener เมื่อออกจากหน้า Dashboard
            appState.stopListeningToAdminBookings()
        }
    }
}

// MARK: - Helper View: DashboardCardView (Unchanged)
struct AdminDashboardCard: View {
    let title: String
    let count: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            Spacer()
            
            // ตัวเลข Count
            Text(count)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color.Theme.textDark)
            
            // ชื่อเมนู
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
        .padding(16)
        .frame(minHeight: 150)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
            .environmentObject(AppState())
    }
}
