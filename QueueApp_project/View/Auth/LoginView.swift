import SwiftUI
import FirebaseAuth

// MARK: - Login View
// หน้าจอล็อกอิน (Login)
// ทำหน้าที่:
// 1. รับข้อมูล Student ID และ Password จากผู้ใช้
// 2. เรียกใช้ AppState.loginAsStudent() เพื่อตรวจสอบข้อมูล
// 3. พายังไปหน้า Register (ถ้ายังไม่มีบัญชี)
// 4. แสดง Alert เมื่อ Login ล้มเหลว
struct LoginView: View {
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState           // Global state
    @State private var studentID = ""                   // รหัสนิสิตที่กรอก
    @State private var password = ""                    // รหัสผ่านที่กรอก
    @State private var showAlert = false                // แจ้งเตือน (เมื่อ Login ล้มเหลว)
    @State private var errorMessage = ""                // ข้อความ Error สำหรับแสดงในแจ้งเตือน
    @Environment(\.presentationMode) var presentationMode  // ใช้สำหรับปิดหน้านี้ (Back)
    
    var body: some View {
        ZStack {
            // 1. Background (ใช้ตัวเดียวกับ WelcomeView เพื่อความต่อเนื่อง)
            DynamicBackground(style: .style2)
            
            // 2. Content
            VStack {
                // ---------------------------------------
                // HEADER: Logo & Welcome Text
                // ส่วนหัวแสดงโลโก้และข้อความต้อนรับ
                // ---------------------------------------
                Spacer()
                
                VStack(alignment: .leading, spacing: 15) {
                    // Logo เล็กๆ
                    ZStack {
                        Circle().fill(Color.white.opacity(0.2)).frame(width: 80, height: 80)
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    Text("       \n Welcome !")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(5)
                    
                    Text("ลงชื่อเข้าใช้เพื่อเริ่มใช้งานบริการต่าง ๆ")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // ---------------------------------------
                // FORM AREA: White Bottom Sheet
                // ส่วนฟอร์มกรอกข้อมูล (พื้นหลังสีขาวโค้งมน)
                // ---------------------------------------
                ZStack {
                    Color.Theme.white
                        // ทำมุมโค้งแค่ด้านบน
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    VStack(spacing: 25) {
                        Text("Login")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.Theme.textDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 30)
                        
                        // Input Fields Group
                        VStack(spacing: 15) {
                            // Student ID Input
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .foregroundColor(Color.Theme.primary)
                                    .frame(width: 30)
                                TextField("Student ID", text: $studentID)
                                    .keyboardType(.numberPad)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(Color(uiColor: .systemGray6)) // พื้นหลังช่องกรอกสีเทาอ่อน
                            .cornerRadius(12)
                            
                            // Password Input
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(Color.Theme.primary)
                                    .frame(width: 30)
                                SecureField("Password", text: $password)
                            }
                            .padding()
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Login Button
                        Button(action: {
                            login()
                        }) {
                            Text("Login")
                        }
                        .buttonStyle(BluePillButtonStyle()) // ใช้ปุ่มสีฟ้าทรงแคปซูล
                        .padding(.top, 10)
                        
                        // Register Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(Color.gray)
                            NavigationLink(destination: RegisterView().environmentObject(appState)) {
                                Text("Register")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.Theme.primary)
                            }
                        }
                        .font(.subheadline)
                        
                        // Guest Link (เข้าใช้งานแบบไม่ล็อกอิน)
                        NavigationLink(destination: ServiceView().environmentObject(appState)) {
                            Text("Continue as Guest")
                                .font(.subheadline)
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                        .padding(.bottom, 20)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                }
                .frame(height: 500) // ความสูงของ Card
            }
            .edgesIgnoringSafeArea(.bottom) // ให้ Card ชิดขอบล่างสุด
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Login Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            print("LoginView ปรากฏขึ้น. isLoggedIn: \(appState.isLoggedIn)")
        }
    }
    
    // MARK: - Authentication Logic
    
    /// ฟังก์ชันเข้าสู่ระบบ
    /// เรียกใช้ AppState.loginAsStudent() และจัดการผลลัพธ์
    /// - Note: เมื่อ Login สำเร็จ AppState จะเปลี่ยน isLoggedIn เป็น true และ ContentView จะพาไปหน้าหลักอัตโนมัติ
    func login() {
        appState.loginAsStudent(studentID: studentID, password: password) { success, message in
            if success {
                print("LoginView: Login successful.")
                // AppState จะเปลี่ยน isLoggedIn เป็น true และ ContentView จะเปลี่ยนหน้าให้เอง
            } else {
                errorMessage = message ?? "Invalid credentials. Please try again."
                showAlert = true
            }
        }
    }
}

// MARK: - HELPER: Shape for Top Corners Only
// Custom Shape สำหรับทำมุมโค้งเฉพาะบางมุม (ใช้กับ Bottom Sheet)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - PREVIEW
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
    }
}
