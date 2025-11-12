//
//  AppState.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

struct OrganizationLoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("เข้าสู่ระบบ (องค์กร)")
                .font(.title2)
                .fontWeight(.bold)

            TextField("ชื่อผู้ใช้", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("รหัสผ่าน", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("เข้าสู่ระบบ") {
                if appState.loginAsOrganization(username: username, password: password) {
                    dismiss()
                } else {
                    // สามารถแสดง alert ได้ แต่ demo ใช้ print ไปก่อน
                    print("ล็อกอินไม่สำเร็จ")
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(username.isEmpty || password.isEmpty)
        }
        .padding()
    }
}
