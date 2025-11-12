//
//  StudentLoginView.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

struct StudentLoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var studentId = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("เข้าสู่ระบบ (นักศึกษา)")
                .font(.title2)
                .fontWeight(.bold)

            TextField("รหัสนักศึกษา (11 หลัก)", text: $studentId)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("เข้าสู่ระบบ") {
                if appState.loginAsStudent(studentId: studentId) {
                    dismiss()
                } else {
                    print("รหัสนักศึกษาไม่ถูกต้อง")
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(studentId.count != 11)
        }
        .padding()
    }
}
