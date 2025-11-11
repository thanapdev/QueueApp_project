//
//  AppState.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 11/11/2568 BE.
//


import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var currentUser: (role: UserRole, name: String, id: String)? = nil

    func loginAsOrganization(username: String, password: String) -> Bool {
        if username == "Admin" && password == "111" {
            currentUser = (role: .organization, name: "ผู้ดูแลระบบ", id: "ORG001")
            return true
        }
        return false
    }
}
