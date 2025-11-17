import SwiftUI

struct ServiceView: View {
    @EnvironmentObject var appState: AppState

    // State สำหรับ Navigation
    @State private var showBookingSpace = false // สำหรับ Logged-in user
    
    // State สำหรับ Alert และ Navigation ของ Guest
    @State private var showingLoginAlert = false
    @State private var navigateToLoginFromAlert = false // สำหรับ Alert -> Login

    // SWU Colors
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

            VStack(spacing: 40) {
                Spacer()

                Text("เลือกบริการ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 20)

                // --- (ส่วนที่แก้ไข) ---
                // ปุ่ม Activity / Event (เปลี่ยนเป็น NavigationLink)
                NavigationLink(destination: {
                    // ตรวจสอบว่า Login หรือยัง?
                    if appState.isLoggedIn {
                        // ถ้า Login แล้ว (เป็น Student) -> ไป StudentActivityListView
                        StudentActivityListView() // <--- ต้องมี View นี้
                            .environmentObject(appState)
                    } else {
                        // ถ้ายังไม่ Login (เป็น Guest) -> ไป GuestActivityListView
                        GuestActivityListView() // <--- ต้องมี View นี้
                            .environmentObject(appState)
                    }
                }) {
                    // นี่คือหน้าตาของปุ่ม
                    ServiceCard(title: "Activity / Event", description: "ดูกิจกรรมและอีเว้นท์", backgroundColor: swuRed)
                }
                .buttonStyle(.plain) // ทำให้ NavigationLink หน้าตาเหมือนปุ่ม
                // --- (สิ้นสุดส่วนที่แก้ไข) ---

                // --- ปุ่ม Booking Space (อันนี้ดีอยู่แล้ว) ---
                Button(action: {
                    if appState.isLoggedIn {
                        // Logged-in: ไปหน้า Booking
                        showBookingSpace = true
                    } else {
                        // Guest: แสดง Alert
                        showingLoginAlert = true
                    }
                }) {
                    ServiceCard(title: "Booking Space", description: "จองพื้นที่", backgroundColor: swuRed)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            .toolbar {
                // --- ปุ่ม Logout (จะแสดงเฉพาะเมื่อ Login แล้ว) ---
                if appState.isLoggedIn {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Logout") {
                            appState.logout() // <--- ต้องมีฟังก์ชันนี้ใน AppState
                        }
                        .foregroundColor(swuRed)
                    }
                }
                
                // --- ปุ่ม Profile/Login (สำหรับ Guest) ---
                // ปุ่มนี้จะแสดงเฉพาะใน "โหมด Guest" (คือเมื่อ !isLoggedIn และไม่ได้มาจาก WelcomeView)
                // เราต้องเช็กว่าเราอยู่ใน Navigation Stack ของ WelcomeView หรือไม่
                // แต่เพื่อความง่าย: ปุ่มนี้จะแสดงเมื่อยังไม่ Login
                if !appState.isLoggedIn {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // เราใช้ navigateToLoginFromAlert เพื่อ "ย้อนกลับ" ไปหน้า Login
                        Button(action: {
                            navigateToLoginFromAlert = true
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(!appState.isLoggedIn) // ซ่อนปุ่ม Back ถ้าเป็น Guest (เพราะมาจาก Login) แต่แสดงถ้าเป็น Student (มาจาก ContentView)
            
            // --- Navigation Links ที่ซ่อนไว้ ---
            
            // 1. สำหรับ Guest ที่โดน Alert แล้วกด "เข้าสู่ระบบ"
            // (และสำหรับปุ่ม Profile icon ด้านบน)
            NavigationLink(destination: LoginView().environmentObject(appState), isActive: $navigateToLoginFromAlert) {
                EmptyView()
            }
        
            // 2. สำหรับ Student ที่ Login แล้ว กด "Booking Space"
            NavigationLink(destination: BookingView().environmentObject(appState), isActive: $showBookingSpace) { // <--- ต้องมี BookingView
                EmptyView()
            }
        }
        .onAppear {
            print("ServiceView ปรากฏขึ้น. isLoggedIn: \(appState.isLoggedIn)")
        }
        .alert("เข้าสู่ระบบ", isPresented: $showingLoginAlert) {
//            Button("ตกลง", role: .none) {
//                navigateToLoginFromAlert = true // Trigger NavigationLink
//            }
            Button("ตกลง", role: .cancel) { }
        } message: {
            Text("คุณต้องเข้าสู่ระบบก่อนจึงจะสามารถจองพื้นที่ได้")
        }
    }
}

// ServiceCard struct (ไม่เปลี่ยนแปลง)
struct ServiceCard: View {
    let title: String
    let description: String
    let backgroundColor: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(description)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 5)
        .contentShape(Rectangle()) // ทำให้กดได้ทั้งการ์ด
    }
}

#Preview {
    // ต้องครอบด้วย NavigationStack เพื่อให้ Preview Toolbar ทำงาน
    NavigationStack {
        ServiceView().environmentObject(AppState())
    }
}
