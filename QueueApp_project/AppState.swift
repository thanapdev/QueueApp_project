//
//  AppState.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var currentUser: (role: UserRole, name: String, id: String)? = nil

    func loginAsOrganization(username: String, password: String) -> Bool {
        if username == "admin" && password == "111" {
            currentUser = (role: .organization, name: "ผู้ดูแลระบบ", id: "ORG001")
            return true
        }
        return false
    }

    func loginAsStudent(studentId: String) -> Bool {
        if studentId.count == 11 && studentId.allSatisfy({ $0.isNumber }) {
            let name = "นาย\(studentId.suffix(2))"
            currentUser = (role: .student, name: name, id: studentId)
            return true
        }
        return false
    }

    func logout() {
        currentUser = nil
        // ❌ ลบ originalUser ออก — ไม่ใช้แล้ว
    }
}
