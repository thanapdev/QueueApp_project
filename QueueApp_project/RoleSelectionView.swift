//
//  AppState.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOrgLogin = false
    @State private var showStudentLogin = false

    var body: some View {
        VStack(spacing: 40) {
            Text("ยินดีต้อนรับสู่ระบบคิวมหาลัย")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                showOrgLogin = true
            }) {
                RoleCard(title: "องค์กรมหาวิทยาลัย", description: "จัดการกิจกรรมและคิว")
            }
            .buttonStyle(.plain)

            Button(action: {
                showStudentLogin = true
            }) {
                RoleCard(title: "นิสิต/นักศึกษา", description: "ต่อคิวเข้าร่วมกิจกรรม")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .navigationTitle("SWU Queue")

        // NavigationLink แบบซ่อน — วางไว้ท้ายสุดของ body
        NavigationLink(destination: OrganizationLoginView().environmentObject(appState), isActive: $showOrgLogin) {
            EmptyView()
        }
        NavigationLink(destination: StudentLoginView().environmentObject(appState), isActive: $showStudentLogin) {
            EmptyView()
        }
    }
}

struct RoleCard: View {
    let title: String
    let description: String

    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .contentShape(Rectangle()) // ทำให้กดได้ทั้งการ์ด
    }
}
