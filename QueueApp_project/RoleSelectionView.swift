//
//  RoleSelectionView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 10/11/2568 BE.
//

import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 40) {
            Text("Welcome to Queue App SWU")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            NavigationLink(
                destination: OrganizationLoginView().environmentObject(appState)
            ) {
                VStack {
                    Text("SWU Admin")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Create Event / Activities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            NavigationLink(
                destination: StudentLoginView().environmentObject(appState)
            ) {
                VStack {
                    Text("SWU Student")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Join Event / Activities queue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding()
        .navigationTitle("You are ?")
    }
}
