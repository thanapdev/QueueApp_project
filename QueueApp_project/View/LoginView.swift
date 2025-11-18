import SwiftUI
import FirebaseAuth

struct LoginView: View {
    // MARK: - SYSTEM LOGIC (DO NOT CHANGE)
    @EnvironmentObject var appState: AppState
    @State private var studentID = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // 1. Background (ใช้ตัวเดียวกับ WelcomeView)
            DynamicBackground(style: .style2)
            
            // 2. Content
            VStack {
                // ---------------------------------------
                // HEADER: Logo & Welcome Text
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
                    
                    Text("        \n Welcome !")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(5)
                    
                    Text("ลงชื่อเข้าใช้เพื่อเริ่มใช้งานบริการต่างๆ")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // ---------------------------------------
                // FORM AREA: White Bottom Sheet
                // ---------------------------------------
                ZStack {
                    Color.white
                        // ทำมุมโค้งเฉพาะด้านบน
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    VStack(spacing: 25) {
                        Text("Login")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.Theme.textDark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 30)
                        
                        // Input Fields
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
                        .buttonStyle(BluePillButtonStyle()) // ใช้ปุ่มสีฟ้าตัวเดิม
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
                        
                        // Guest Link
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
    
    // MARK: - LOGIC FUNCTIONS
    func login() {
        appState.loginAsStudent(studentID: studentID, password: password) { success, message in
            if success {
                print("LoginView: Login successful.")
            } else {
                errorMessage = message ?? "Invalid credentials. Please try again."
                showAlert = true
            }
        }
    }
}

// MARK: - HELPER: Shape for Top Corners Only
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
