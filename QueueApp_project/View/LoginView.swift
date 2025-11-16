import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var studentID = "" // Use studentID for both
    @State private var password = ""
    //@State private var isLoggedIn = false // Remove this line
    @State private var showAlert = false
    @State private var errorMessage = ""
    
    // SWU Colors
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)
    
    var body: some View {
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
                
                VStack {
                    Spacer()
                    
                    Text("Sign in")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                    
                    // Input Fields
                    TextField("Student ID", text: $studentID) // Use studentID for both
                        .padding()
                        .keyboardType(.numberPad)
                        .autocapitalization(.none)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.white)
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
                    NavigationLink(destination: RegisterView()) {
                        Text("Don't have an account? Register")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Login Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
            }
            .fullScreenCover(isPresented: $appState.isLoggedIn, content: { // Use appState.isLoggedIn
                destinationView()
            })
        }
    }
    
    func login() {
        appState.loginAsStudent(studentID: studentID, password: password) { success, message in
            if success {
                withAnimation {
                    //isLoggedIn = true // Remove this line
                }
            } else {
                errorMessage = message ?? "Invalid credentials. Please try again."
                showAlert = true
            }
        }
    }
    
    @ViewBuilder
    private func destinationView() -> some View {
        if appState.currentUser?.role == .admin {
            ActivityListView()
        } else {
            StudentActivityListView()
        }
    }
}
