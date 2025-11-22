//
//  WelcomeView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - Welcome View
// หน้าแรกสุดของแอป (Landing Page) สำหรับผู้ใช้ที่ยังไม่ได้ล็อกอิน
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. Background กราฟิก (ใช้ Style 1 สีฟ้าสดใส)
                DynamicBackground(style: .style1)
                
                VStack(spacing: 0) {
                    // ---------------------------------------
                    // ส่วนบน: Logo และ พื้นที่ว่าง
                    // ---------------------------------------
                    Spacer()
                    
                    ZStack {
                        // วงกลมตกแต่งพื้นหลังโลโก้
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 180, height: 180)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 150, height: 150)
                            .shadow(radius: 10)
                        
                        // ไอคอนโลโก้
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color.Theme.primary)
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                    
                    // ---------------------------------------
                    // ส่วนล่าง: Card สีขาวพร้อมข้อความต้อนรับ
                    // ---------------------------------------
                    ZStack {
                        // สร้าง Shape โค้งด้านล่าง (เหมือนคลื่น)
                        WaveShapeBottomCard()
                            .fill(Color.white) // พื้นหลังสีขาว
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                        
                        VStack(spacing: 20) {
                            // Text Content
                            VStack(spacing: 8) {
                                Text("SWU Services")
                                    .font(.system(size: 32, weight: .heavy)) // Font หนาพิเศษ
                                    .foregroundColor(Color.Theme.primary)
                                
                                Text("มหาวิทยาลัยศรีนครินทรวิโรฒ")
                                    .font(.headline)
                                    .foregroundColor(Color.gray)
                                
                                Text("แหล่งรวมบริการนักศึกษาครบวงจร\nใช้งานง่าย สะดวก รวดเร็ว")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.gray)
                                    .padding(.top, 10)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 60) // ดันลงมาจากยอดคลื่น
                            
                            Spacer()
                            
                            // ปุ่ม Sign In (นำทางไป LoginView)
                            NavigationLink(destination: LoginView().environmentObject(appState)) {
                                Text("Sign In")
                            }
                            .buttonStyle(BluePillButtonStyle()) // ใช้ปุ่มมาตรฐานของแอป
                            .padding(.horizontal, 30)
                            .padding(.bottom, 10)
                            
                            Text("Powered by SWU")
                                .font(.caption)
                                .foregroundColor(Color.gray.opacity(0.6))
                                .padding(.bottom, 40)
                        }
                    }
                    .frame(height: 380) // ความสูงของ Card ด้านล่าง
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .navigationBarHidden(true) // ซ่อน Navigation Bar
        }
        .navigationViewStyle(.stack) // บังคับใช้ Stack Style เพื่อให้แสดงผลถูกต้องบน iPad
    }
}

// MARK: - Helper Shape
// Shape สำหรับส่วนโค้งด้านล่าง (Wave Effect)
struct WaveShapeBottomCard: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 60)) // เริ่มต้นทางซ้าย ต่ำลงมาหน่อย
        
        // วาดโค้งขึ้นไปตรงกลาง
        path.addCurve(
            to: CGPoint(x: rect.width, y: 0), // ไปจบขวาบนสุด
            control1: CGPoint(x: rect.width * 0.3, y: 60), // จุดดัด 1
            control2: CGPoint(x: rect.width * 0.6, y: -30) // จุดดัด 2 (ดึงขึ้น)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppState())
    }
}
