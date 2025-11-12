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
    @State private var showDeleteConfirmation = false // ✅ ใช้สำหรับ Alert
    @State private var deleteIndex: Int? = nil // เก็บ index ที่จะลบ

    var body: some View {
        VStack {
            HStack {
                Text("สวัสดี, \(appState.currentUser?.name ?? "ผู้ดูแล")")
                    .font(.headline)
                Spacer()
                Button("ออกจากระบบ") {
                    appState.logout()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if appState.activities.isEmpty {
                VStack {
                    Text("ยังไม่มีกิจกรรม")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button("สร้างกิจกรรมใหม่") {
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
                        Button("เพิ่ม") {
                            showingAddActivity = true
                        }
                    }
                }
            }
        }
        .navigationTitle("กิจกรรมของคุณ")
        .sheet(isPresented: $showingAddActivity) {
            NavigationStack {
                VStack {
                    TextField("ชื่อกิจกรรม", text: $newActivityName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    HStack {
                        Button("ยกเลิก") {
                            showingAddActivity = false
                        }
                        Spacer()
                        Button("สร้าง") {
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
                .navigationTitle("สร้างกิจกรรม")
            }
        }
        // ✅ Alert ยืนยันการลบ
        .alert("ยืนยันการลบ?", isPresented: $showDeleteConfirmation, actions: {
            Button("ยกเลิก", role: .cancel) {
                showDeleteConfirmation = false
                deleteIndex = nil
            }
            Button("ลบ", role: .destructive) {
                if let index = deleteIndex {
                    appState.activities.remove(at: index)
                }
                showDeleteConfirmation = false
                deleteIndex = nil
            }
        }, message: {
            if let index = deleteIndex {
                Text("คุณแน่ใจหรือไม่ว่าจะลบกิจกรรม \"\(appState.activities[index].name)\"? \nคิวทั้งหมดจะหายไปด้วย!")
            }
        })
    }

    // ✅ ฟังก์ชันลบกิจกรรม — แสดง Alert ก่อนลบ
    func deleteActivities(offsets: IndexSet) {
        if let index = offsets.first {
            deleteIndex = index
            showDeleteConfirmation = true
        }
    }
}
