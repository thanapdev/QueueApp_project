//
//  ActivityListView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 12/11/2568 BE.
//

//
//  AppState.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

// ActivityListView.swift
import SwiftUI

struct ActivityListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddActivity = false
    @State private var newActivityName = ""
    @State private var showDeleteConfirmation = false
    @State private var deleteIndex: Int? = nil

    var body: some View {
        VStack {
            HStack {
                Text("Hello, \(appState.currentUser?.name ?? "Admin")")
                    .font(.headline)
                Spacer()
                Button("Logout") {
                    appState.logout()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if appState.activities.isEmpty {
                VStack {
                    Text("No activities yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button("Create new activity") {
                        showingAddActivity = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            } else {
                List {
                    ForEach(appState.activities.indices, id: \.self) { index in
                        NavigationLink(
                            destination: QueueView(activity: $appState.activities[index])
                                .environmentObject(appState)
                        ) {
                            Text(appState.activities[index].name)
                                .font(.body)
                        }
                    }
                    .onDelete(perform: deleteActivities)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !appState.activities.isEmpty {
                            EditButton()
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Add") {
                            showingAddActivity = true
                        }
                    }
                }
            }
        }
        .navigationTitle("Your Activities")
        .sheet(isPresented: $showingAddActivity) {
            NavigationStack {
                VStack {
                    TextField("Activity Name", text: $newActivityName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    HStack {
                        Button("Cancel") {
                            showingAddActivity = false
                        }
                        Spacer()
                        Button("Create") {
                            if !newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                appState.activities.append(Activity(name: newActivityName))
                                newActivityName = ""
                                showingAddActivity = false
                            }
                        }
                        .disabled(newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                }
                .navigationTitle("Create Activity")
            }
        }
        
        .alert("Confirm deletion?", isPresented: $showDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = false
                deleteIndex = nil
            }
            Button("Delete", role: .destructive) {
                if let index = deleteIndex {
                    appState.activities.remove(at: index)
                }
                showDeleteConfirmation = false
                deleteIndex = nil
            }
        }, message: {
            if let index = deleteIndex {
                Text("Are you sure you want to delete activity \"\(appState.activities[index].name)\"? \nAll queues will be lost!")
            }
        })
    }

    
    func deleteActivities(offsets: IndexSet) {
        if let index = offsets.first {
            deleteIndex = index
            showDeleteConfirmation = true
        }
    }
}
