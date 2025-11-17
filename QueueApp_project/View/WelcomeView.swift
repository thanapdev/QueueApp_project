//
//  WelcomeView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


import SwiftUI

struct WelcomeView: View {
    // รับ AppState มาเพื่อส่งต่อไปยัง LoginView
    @EnvironmentObject var appState: AppState

    // SWU Colors (จาก LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)
    
    var body: some View {
        // NavigationView นี้จำเป็นสำหรับการ "push" ไปยัง LoginView
        NavigationView {
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
                // 3. Content (อ้างอิงจากรูปตัวอย่าง)
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Logo (ใช้ SFSymbol แทน)
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 100))
                        .foregroundColor(swuRed) // ใช้สี swuRed
                        .padding(.bottom, 20)
                    
                    // Title
                    Text("SWU Services") // หรือชื่อแอปของคุณ
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    // Description
                    Text("แอปพลิเคชันบริการนักศึกษา")
                        .font(.headline)
                        .foregroundColor(.black.opacity(0.7))
                    
                    Spacer()
                    Spacer()
                    
                    // "GET STARTED" Button
                    // ใช้ NavigationLink เพื่อไปหน้า LoginView
                    NavigationLink(destination: LoginView().environmentObject(appState)) {
                        Text("GET STARTED")
                            .font(.headline)
                            .padding()
                            .frame(width: 250, height: 50)
                            .foregroundColor(.white)
                            .background(swuRed) // ใช้สี swuRed
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    
                    // Bottom text
                    Text("เริ่มต้นใช้งานโดยการเข้าสู่ระบบ")
                        .font(.caption)
                        .foregroundColor(swuGray) // ใช้สี swuGray
                        .padding(.top, 10)
                    
                    Spacer()
                }
                .padding()
                
            }
            .navigationBarHidden(true) // ซ่อน Navigation Bar ที่หน้า Welcome
        }
        .navigationViewStyle(.stack) // ป้องกันปัญหา layout บน iPad
    }
}

// MARK: - Preview
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppState()) // ส่ง AppState จำลอง
    }
}
