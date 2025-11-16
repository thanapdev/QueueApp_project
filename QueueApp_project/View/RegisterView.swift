import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var studentID = ""
    @State private var email = "" // Add email field
    @State private var password = ""
    @State private var selectedRole: AppState.UserRole = .student
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false // Add success alert state
    @Environment(\.presentationMode) var presentationMode

    // SWU Colors (From LoginView.swift)
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

                    Text("Register")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.bottom, 20)

                    TextField("Name", text: $name)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.black)
                        .padding(.bottom, 10)

                    TextField("Student ID", text: $studentID)
                        .padding()
                        .keyboardType(.numberPad)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.black)
                        .padding(.bottom, 10)
                    
                    TextField("Email", text: $email) // Add email field
                        .padding()
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.black)
                        .padding(.bottom, 10)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    Picker("Role", selection: $selectedRole) {
                        Text("Student").tag(AppState.UserRole.student)
                        Text("Admin").tag(AppState.UserRole.admin)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .frame(width: 200)

                    Button("Register") {
                        register()
                    }
                    .padding()
                    .frame(width: 200, height: 40)
                    .foregroundColor(.white)
                    .background(swuRed)
                    .cornerRadius(8)
                    .shadow(radius: 5)

                    Spacer()
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Register Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
                }
                .alert(isPresented: $showSuccessAlert) { // Success alert
                    Alert(title: Text("Registration Successful"), message: Text("You have successfully registered."), dismissButton: .default(Text("OK"), action: {
                        presentationMode.wrappedValue.dismiss() // Dismiss the view
                    }))
                }
            }
        }
    }

    func register() {
        // Call appState.register here
        appState.register(name: name, studentID: studentID, email: email, password: password, role: selectedRole) { success, message in
            if success {
                // Handle successful registration (e.g., navigate to another view)
                print("Registration Successful!")
                showSuccessAlert = true // Show success alert
            } else {
                errorMessage = message ?? "Registration failed. Please try again."
                showAlert = true
            }
        }
    }
}
