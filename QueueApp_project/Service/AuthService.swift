//
//  AuthService.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Authentication Service
// Service สำหรับจัดการเรื่อง Authentication ทั้งหมด
// ทำหน้าที่:
// 1. Login (เข้าสู่ระบบด้วย Student ID)
// 2. Register (สมัครสมาชิกใหม่)
// 3. Logout (ออกจากระบบ)
// 4. ดึงข้อมูลผู้ใช้จาก Firestore
class AuthService {
    private let db = Firestore.firestore()
    
    // MARK: - Authentication Methods
    
    /// ออกจากระบบ (Sign Out)
    /// ทำการ Sign Out จาก Firebase Authentication
    func logout() {
        try? Auth.auth().signOut()
    }
    
    /// สมัครสมาชิกใหม่ (Register)
    /// - Parameters:
    ///   - name: ชื่อ-นามสกุล
    ///   - studentID: รหัสนิสิต 11 หลัก
    ///   - email: อีเมล (สำหรับ Login)
    ///   - password: รหัสผ่าน
    ///   - role: บทบาท (Student/Admin)
    ///   - completion: Callback เมื่อเสร็จสิ้น (success, errorMessage)
    func register(name: String, studentID: String, email: String, password: String, role: AppState.UserRole, completion: @escaping (Bool, String?) -> Void) {
        // ตรวจสอบรหัสนิสิต (ต้องเป็นตัวเลข 11 หลัก)
        guard studentID.count == 11, studentID.allSatisfy({ $0.isNumber }) else {
            completion(false, "ID ต้องเป็นตัวเลข 11 หลัก")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else if let user = authResult?.user {
                // บันทึกข้อมูลเพิ่มเติมลง Firestore
                let userData: [String: Any] = [
                    "name": name,
                    "studentID": studentID,
                    "email": email,
                    "role": role == .student ? "student" : "admin"
                ]
                
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        completion(false, "Failed to save user data: \(error.localizedDescription)")
                    } else {
                        completion(true, nil)
                    }
                }
            } else {
                completion(false, "Failed to retrieve user information.")
            }
        }
    }
    
    /// เข้าสู่ระบบด้วยรหัสนิสิต (Login as Student)
    /// - Parameters:
    ///   - studentID: รหัสนิสิต 11 หลัก
    ///   - password: รหัสผ่าน
    ///   - completion: Callback เมื่อเสร็จสิ้น (Result<UserData, Error>)
    /// - Note: ระบบจะค้นหา Email จาก StudentID ก่อน แล้วค่อย Login ด้วย Firebase Auth
    func loginAsStudent(studentID: String, password: String, completion: @escaping (Result<(role: AppState.UserRole, name: String, id: String), Error>) -> Void) {
        // 1. หา Email จาก StudentID ใน Firestore ก่อน
        db.collection("users").whereField("studentID", isEqualTo: studentID).getDocuments { (qs, err) in
            if let err = err {
                completion(.failure(err))
                return
            }
            
            guard let doc = qs?.documents.first else {
                completion(.failure(NSError(domain: "AuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid Student ID."])))
                return
            }
            
            let data = doc.data()
            let email = data["email"] as? String ?? ""
            let name = data["name"] as? String ?? ""
            let roleString = data["role"] as? String ?? "student"
            let role: AppState.UserRole = (roleString == "admin") ? .admin : .student
            
            // 2. Login ด้วย Email/Password ผ่าน Firebase Auth
            Auth.auth().signIn(withEmail: email, password: password) { authResult, err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    completion(.success((role: role, name: name, id: studentID)))
                }
            }
        }
    }
}
