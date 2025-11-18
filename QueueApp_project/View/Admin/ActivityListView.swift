//
//  ActivityListView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

struct ActivityListView: View {
    // MARK: - SYSTEM LOGIC (PRESERVED)
    @EnvironmentObject var appState: AppState
    @State private var showingAddActivity = false
    @State private var newActivityName = ""
    @State private var showDeleteConfirmation = false
    @State private var deleteIndex: Int? = nil
    @Environment(\.editMode) var editMode
    @State private var showEditActivity = false
    @State private var editIndex: Int? = nil
    @State private var editActivityName: String = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // ✅ 1. Background ใหม่
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // ---------------------------------------
                // CUSTOM HEADER (แทน Navigation Bar)
                // ---------------------------------------
                VStack(alignment: .leading, spacing: 10) {
                    // Back Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 50)
                    
                    // Greeting & Title
                    Text("Activities Management")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    Text("สวัสดี, \(appState.currentUser?.name ?? "ผู้ดูแล")")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)

                // ---------------------------------------
                // CONTENT AREA (White Sheet)
                // ---------------------------------------
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    if appState.activities.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "square.stack.3d.up.slash")
                                .font(.system(size: 60))
                                .foregroundColor(Color.gray.opacity(0.3))
                            Text("ยังไม่มีกิจกรรมให้จัดการ")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Button("สร้างกิจกรรมใหม่") {
                                showingAddActivity = true
                            }
                            .buttonStyle(BluePillButtonStyle()) // ✅ ใช้สไตล์ปุ่มที่เราทำไว้
                            .frame(width: 200)
                            
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(appState.activities.indices, id: \.self) { index in
                                // ✅ ใช้ ActivityNavigationLink ที่ปรับปรุงแล้ว
                                ActivityNavigationLink(activity: appState.activities[index])
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        // Edit Button
                                        Button {
                                            editIndex = index
                                            editActivityName = appState.activities[index].name
                                            showEditActivity = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.orange) // ใช้สีส้มเพื่อให้เข้าธีม
                                        
                                        // Delete Button
                                        Button(role: .destructive) {
                                            deleteIndex = index
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .listRowBackground(Color.white) // พื้นหลังขาว
                                    .listRowSeparator(.hidden) // ซ่อนเส้นแบ่ง List
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                        .padding(.top, 20)
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationBarHidden(true) // ซ่อน Navigation Bar เพราะทำ Header เอง

        // MARK: - Modals and Alerts
        .alert("ยืนยันการลบ?", isPresented: $showDeleteConfirmation, actions: {
            Button("ยกเลิก", role: .cancel) { deleteIndex = nil }
            Button("ลบ", role: .destructive) {
                if let index = deleteIndex {
                    appState.deleteActivity(activity: appState.activities[index])
                    appState.activities.remove(at: index) // 🎯 Logic: ลบจาก array
                }
                deleteIndex = nil
            }
        }, message: {
            if let index = deleteIndex {
                Text("คุณแน่ใจหรือไม่ว่าจะลบกิจกรรม \"\(appState.activities[index].name)\"? \nคิวทั้งหมดจะหายไปด้วย!")
            }
        })
        
        // --- Add Activity Sheet ---
        .sheet(isPresented: $showingAddActivity) {
            AddEditActivitySheet(
                title: "สร้างกิจกรรมใหม่",
                activityName: $newActivityName,
                onSave: {
                    appState.addActivity(name: newActivityName) // 🎯 Logic: เพิ่มกิจกรรม
                    newActivityName = ""
                }
            )
        }
        
        // --- Edit Activity Sheet ---
        .sheet(isPresented: $showEditActivity) {
            AddEditActivitySheet(
                title: "แก้ไขกิจกรรม",
                activityName: $editActivityName,
                onSave: {
                    if let index = editIndex {
                        appState.activities[index].name = editActivityName // 🎯 Logic: แก้ชื่อใน array
                        appState.updateActivity(activity: appState.activities[index]) // 🎯 Logic: ส่งไป Firebase
                    }
                }
            )
        }
        .onAppear {
            appState.loadActivities() // โหลดกิจกรรมทุกครั้งที่เข้าหน้า
        }
    }
}

// MARK: - Helper View: ActivityNavigationLink (List Row)
struct ActivityNavigationLink: View {
    @ObservedObject var activity: Activity

    var body: some View {
        NavigationLink(
            // Destination Logic Preserved
            destination: QueueView(activity: .constant(activity))
                .environmentObject(AppState())
        ) {
            HStack {
                Image(systemName: "list.number")
                    .font(.title2)
                    .foregroundColor(Color.Theme.primary)
                
                Text(activity.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.Theme.textDark)
                
                Spacer()
                
//                Text("คิว: \(activity.queues.count)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
    }
}


// MARK: - Helper View: Add/Edit Sheet (รวม Add และ Edit)
struct AddEditActivitySheet: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    @Binding var activityName: String
    var onSave: () -> Void

    var isSaveDisabled: Bool {
        activityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                DynamicBackground(style: .random)
                
                VStack(spacing: 20) {
                    Text(title == "สร้างกิจกรรมใหม่" ? "ป้อนชื่อกิจกรรมใหม่" : "ป้อนชื่อกิจกรรมที่แก้ไข")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 20)
                    
                    TextField("เช่น 'กิจกรรมรับน้อง', 'ไหว้ครู'", text: $activityName)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ยกเลิก") {
                        dismiss()
                        activityName = "" // เคลียร์ค่าเมื่อยกเลิก
                    }
                    .foregroundColor(Color.red) // ใช้สีแดง
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("บันทึก") {
                        onSave()
                        dismiss()
                    }
                    .bold()
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
}
