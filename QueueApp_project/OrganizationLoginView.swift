//
//  OrganizationLoginView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 11/11/2568 BE.
//


import SwiftUI

struct OrganizationLoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Loing (Admin)")
                .font(.title2)
                .fontWeight(.bold)

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Login") {
                if appState.loginAsOrganization(username: username, password: password) {
                    dismiss()
                }
            }
            .disabled(username.isEmpty || password.isEmpty)
        }
        .padding()
    }
}
