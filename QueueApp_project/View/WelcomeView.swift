//
//  WelcomeView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1. Background กราฟิก
                DynamicBackground(style: .style1)
                
                VStack(spacing: 0) {
                    // ---------------------------------------
                    // ส่วนบน: Logo และ พื้นที่ว่าง
                    // ---------------------------------------
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 180, height: 180)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 150, height: 150)
                            .shadow(radius: 10)
                        
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color.Theme.primary)
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                    
                    // ---------------------------------------
                    // ส่วนล่าง: การ์ดสีฟ้าเข้มขึ้น หรือ พื้นที่โค้งๆ
                    // ---------------------------------------
                    ZStack {
                        // สร้าง Shape โค้งด้านล่าง (เหมือนคลื่นในรูป)
                        WaveShapeBottomCard()
                            .fill(Color.white) // เปลี่ยนเป็นสีขาวเพื่อให้ Text อ่านง่าย
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                        
                        VStack(spacing: 20) {
                            // Text Content
                            VStack(spacing: 8) {
                                Text("SWU Services")
                                    .font(.system(size: 32, weight: .heavy)) // Font หนาๆ
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
                            
                            // ปุ่ม Sign In (สไตล์ขาว)
                            NavigationLink(destination: LoginView().environmentObject(appState)) {
                                Text("Sign In")
                            }
                            .buttonStyle(BluePillButtonStyle()) // ใช้ Style ใหม่แต่อาจจะกลืนกับพื้นขาว
                            .padding(.horizontal, 30)
                            .padding(.bottom, 10)
                            // *ถ้าพื้นหลังเป็นขาว ปุ่มขาวจะมองไม่เห็น ให้ Override สีปุ่มตรงนี้*
//                            .overlay(
//                                Capsule()
//                                    .stroke(Color.Theme.primary, lineWidth: 2) // ใส่ขอบแทน หรือเปลี่ยนเป็นปุ่มสีฟ้า
//                            )
                            
                            // ** หรือถ้าอยากได้ปุ่มทึบสีฟ้าบนพื้นขาว ให้ใช้ Code นี้แทนปุ่มข้างบน **
                            /*
                            NavigationLink(destination: LoginView().environmentObject(appState)) {
                                Text("Sign In")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.Theme.primary)
                                    .clipShape(Capsule())
                                    .padding(.horizontal, 30)
                            }
                            */
                            
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
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

// Shape สำหรับส่วนโค้งด้านล่าง
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
