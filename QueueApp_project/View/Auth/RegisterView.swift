import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Register View
// หน้าจอลงทะเบียนสมาชิกใหม่ (Registration)
// ทำหน้าที่:
// 1. รับข้อมูลผู้ใช้ใหม่ (ชื่อ, รหัสนิสิต, Email, Password)
// 2. เลือกบทบาท (Student/Admin)
// 3. เรียกใช้ AppState.register() เพื่อสร้างบัญชีใน Firebase
// 4. แสดง Alert เมื่อสำเร็จหรือล้มเหลว
struct RegisterView: View {
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState // Global state
    @State private var name = "" // ชื่อ-นามสกุล
    @State private var studentID = "" // รหัสนิสิต (11 หลัก)
    @State private var email = "" // อีเมล
    @State private var password = "" // รหัสผ่าน
    @State private var selectedRole: AppState.UserRole = .student // บทบาทที่เลือก (Default: Student)
    @State private var showAlert = false // สถานะการแสดง Alert สำหรับข้อผิดพลาด
    @State private var errorMessage = "" // ข้อความแสดงข้อผิดพลาด
    @State private var showSuccessAlert = false // สถานะการแสดง Alert สำหรับความสำเร็จ
    @Environment(\.presentationMode) var presentationMode // ใช้สำหรับปิดหน้านี้ (Back)

    var body: some View {
        ZStack {
            // 1. Background (สุ่มลายกราฟิกเหมือนหน้า Login)
            DynamicBackground(style: .random)
            
            VStack {
                // ---------------------------------------
                // HEADER: Back Button & Title
                // ส่วนหัว: ปุ่มย้อนกลับ และชื่อหน้า
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
                    // Title Area
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
                // ส่วนฟอร์มกรอกข้อมูล (พื้นหลังสีขาว)
                // ---------------------------------------
                ZStack {
                    Color.Theme.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 25) {
                            
                            // Input Fields Group
                            VStack(spacing: 15) {
                                CustomTextField(icon: "person.fill", placeholder: "Full Name", text: $name)
                                CustomTextField(icon: "person.text.rectangle", placeholder: "Student ID (11 digits)", text: $studentID, keyboardType: .numberPad)
                                CustomTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, keyboardType: .emailAddress)
                                CustomSecureField(icon: "lock.fill", placeholder: "Password", text: $password)
                            }
                            .padding(.top, 30)
                            
                            // Role Picker (เลือกบทบาท: นิสิต หรือ Admin)
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
                            .buttonStyle(BluePillButtonStyle())
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
                .frame(height: 550) // กำหนดความสูงของ Sheet
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Registration Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(title: Text("Success"), message: Text("Registration successful!"), dismissButton: .default(Text("OK"), action: {
                presentationMode.wrappedValue.dismiss() // ปิดหน้า Register เมื่อสำเร็จ
            }))
        }
    }
    
    // MARK: - Registration Logic
    
    /// ฟังก์ชันลงทะเบียนสมาชิก
    /// เรียกใช้ AppState.register() และจัดการผลลัพธ์
    /// - Note: ตรวจสอบรหัสนิสิต 11 หลักและบันทึกลง Firestore
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

// MARK: - HELPER VIEWS (Custom TextFields)
// Component ย่อยสำหรับช่องกรอกข้อมูล เพื่อลด Code ซ้ำซ้อน
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
