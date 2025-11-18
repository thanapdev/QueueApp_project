//
//  GuestActivityListView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

struct GuestActivityListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLoginAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline).foregroundColor(.white)
                        .padding(.vertical, 8).padding(.horizontal, 12)
                        .background(Color.white.opacity(0.2)).clipShape(Capsule())
                    }
                    .padding(.top, 50)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Activities").font(.system(size: 34, weight: .bold)).foregroundColor(.white)
                            Text("สำหรับบุคคลทั่วไป (Guest Mode)").font(.body).foregroundColor(Color.white.opacity(0.9))
                        }
                        Spacer()
                        VStack {
                            Image(systemName: "eye.fill").font(.title2)
                            Text("View Only").font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 30).padding(.bottom, 30)
                
                // List Content
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    if appState.activities.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "tray.fill").font(.system(size: 50)).foregroundColor(Color.gray.opacity(0.3))
                            Text("ยังไม่มีกิจกรรมในขณะนี้").font(.headline).foregroundColor(Color.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 15) {
                                // ✅ ใช้ indices loop เช่นกัน
                                ForEach(appState.activities.indices, id: \.self) { index in
                                    let activity = appState.activities[index]
                                    
                                    Button(action: {
                                        self.showLoginAlert = true
                                    }) {
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
        .alert(isPresented: $showLoginAlert) {
            Alert(
                title: Text("Login Required"),
                message: Text("กรุณาเข้าสู่ระบบเพื่อดูรายละเอียดและจองคิว"),
                dismissButton: .default(Text("ตกลง"))
            )
        }
        .onAppear {
            appState.loadActivities()
        }
    }
}
