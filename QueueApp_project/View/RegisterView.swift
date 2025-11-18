import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    // MARK: - SYSTEM LOGIC (DO NOT CHANGE)
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var studentID = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: AppState.UserRole = .student
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // 1. Background (สุ่มลายกราฟิกเหมือนหน้า Login)
            DynamicBackground(style: .random)
            
            VStack {
                // ---------------------------------------
                // HEADER: Back Button & Title
                // ---------------------------------------
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 50) // เผื่อพื้นที่ให้ Dynamic Island / Notch
                .padding(.horizontal, 20)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Create\nAccount")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(5)
                    
                    Text("กรอกข้อมูลเพื่อลงทะเบียนเข้าใช้งาน")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                
                Spacer()
                
                // ---------------------------------------
                // FORM AREA: White Bottom Sheet
                // ---------------------------------------
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    // ใช้ ScrollView เพราะช่องกรอกเยอะ อาจล้นจอ
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 25) {
                            
                            // Input Fields Group
                            VStack(spacing: 15) {
                                // Name Input
                                CustomTextField(icon: "person.fill", placeholder: "Full Name", text: $name)
                                
                                // Student ID Input
                                CustomTextField(icon: "person.text.rectangle", placeholder: "Student ID", text: $studentID, keyboardType: .numberPad)
                                
                                // Email Input
                                CustomTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, keyboardType: .emailAddress)
                                
                                // Password Input
                                CustomSecureField(icon: "lock.fill", placeholder: "Password", text: $password)
                            }
                            .padding(.top, 30)
                            
                            // Role Picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Select Role")
                                    .font(.subheadline)
                                    .foregroundColor(Color.gray)
                                    .padding(.leading, 5)
                                
                                Picker("Role", selection: $selectedRole) {
                                    Text("Student").tag(AppState.UserRole.student)
                                    Text("Admin").tag(AppState.UserRole.admin)
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Register Button
                            Button(action: {
                                register()
                            }) {
                                Text("Register")
                            }
                            .buttonStyle(BluePillButtonStyle()) // ใช้ปุ่มสไตล์เดียวกัน
                            .padding(.top, 10)
                            
                            // Footer Link (Back to Login)
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Text("Already have an account?")
                                        .foregroundColor(Color.gray)
                                    Text("Login")
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.Theme.primary)
                                }
                                .font(.subheadline)
                            }
                            .padding(.bottom, 40) // เว้นระยะด้านล่างเผื่อ Home Bar
                        }
                        .padding(.horizontal, 30)
                    }
                }
                .frame(height: 550) // กำหนดความสูงของ Sheet (ปรับได้ตามต้องการ)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Register Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Registration successful!"), dismissButton: .default(Text("OK"), action: {
                presentationMode.wrappedValue.dismiss()
            }))
        }
    }
    
    // MARK: - LOGIC FUNCTION
    func register() {
        appState.register(name: name, studentID: studentID, email: email, password: password, role: selectedRole) { success, message in
            if success {
                print("Registration Successful!")
                showSuccessAlert = true
            } else {
                errorMessage = message ?? "Registration failed. Please try again."
                showAlert = true
            }
        }
    }
}

// MARK: - HELPER VIEWS (Custom TextFields เพื่อความสะอาดของโค้ด)
struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.Theme.primary)
                .frame(width: 30)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.Theme.primary)
                .frame(width: 30)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AppState())
    }
}
