//
//  RoleSelectionView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 10/11/2568 BE.
//


import SwiftUI

struct RoleSelectionView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Hello ! welcome to Queue App")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            NavigationLink("University Organization") {
                Text("Organization Login")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)

            NavigationLink("SWU's Student") {
                Text("Student Login")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .navigationTitle("Queue App SWU")
        .multilineTextAlignment(.center)
    }
}
