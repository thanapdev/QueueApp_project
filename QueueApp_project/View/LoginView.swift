import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var studentID = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var errorMessage = ""
    
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
            
            VStack {
                Spacer()
                
                Text("Sign in")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 20)
                
                // Input Fields
                TextField("Student ID", text: $studentID)
                    .padding()
                    .keyboardType(.numberPad)
                    .autocapitalization(.none)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 1))
                    // .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 1))
                    // .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                // Login Button
                Button("Login") {
                    login()
                }
                .padding()
                .frame(width: 200, height: 40)
                .foregroundColor(.white)
                .background(swuRed)
                .cornerRadius(8)
                .shadow(radius: 5)
                
                // Register Link
                NavigationLink(destination: RegisterView().environmentObject(appState)) { // <--- ต้องมี RegisterView
                    Text("Don't have an account? Register")
                        .foregroundColor(.blue)
                }
                .padding(.top, 10)

                // --- (ส่วนที่แก้ไข) ---
                // เปลี่ยนจาก Button เป็น NavigationLink
                NavigationLink(destination: ServiceView().environmentObject(appState)) {
                    Text("Continue as Guest")
                        .font(.subheadline)
                        .foregroundColor(swuGray)
                        .padding(.top, 15)
                }
                // --- (สิ้นสุดส่วนที่แก้ไข) ---
                
                Spacer()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationBarHidden(true) // ซ่อน Bar เมื่อมาจาก WelcomeView
        .onAppear {
            print("LoginView ปรากฏขึ้น. isLoggedIn: \(appState.isLoggedIn)")
        }
    }
    
    func login() {
        appState.loginAsStudent(studentID: studentID, password: password) { success, message in
            if success {
                // ไม่ต้องทำอะไร! ContentView จะสลับหน้าให้เอง
                print("LoginView: Login successful.")
            } else {
                errorMessage = message ?? "Invalid credentials. Please try again."
                showAlert = true
            }
        }
    }
}
