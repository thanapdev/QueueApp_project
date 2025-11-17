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
    @Environment(\.editMode) var editMode
    @State private var showEditActivity = false
    @State private var editIndex: Int? = nil
    @State private var editActivityName: String = ""


    // SWU Colors (From LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                // Shape Background
                GeometryReader { geometry in
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.24, green: 0.27, blue: 0.68, alpha: 1)), Color(#colorLiteral(red: 0.14, green: 0.64, blue: 0.96, alpha: 1))]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 200, height: 200)
                        .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.1)
                    
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.97, green: 0.32, blue: 0.18, alpha: 1)), Color(#colorLiteral(red: 0.94, green: 0.59, blue: 0.1, alpha: 1))]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 200, height: 200)
                        .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.9)
                }

                VStack {
                    HStack {
                        Text("สวัสดี, \(appState.currentUser?.name ?? "ผู้ดูแล")")
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
                        Button("ออกจากระบบ") {
                            appState.logout()
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(swuRed)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(.white.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)

                    if appState.activities.isEmpty {
                        VStack {
                            Text("ยังไม่มีกิจกรรม")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Button("สร้างกิจกรรมใหม่") {
                                showingAddActivity = true
                            }
                            .padding()
                            .background(swuRed)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(appState.activities.indices, id: \.self) { index in
                                ActivityNavigationLink(activity: appState.activities[index])
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            editIndex = index
                                            editActivityName = appState.activities[index].name
                                            showEditActivity = true
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)

                                        Button(role: .destructive) {
                                            deleteIndex = index
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .listRowBackground(Color.white.opacity(0.7)) // <- คุณทำส่วนนี้ไว้ดีแล้วครับ
                            }
                        }
                        .scrollContentBackground(.hidden) // ⬅️ ✨ 1. ซ่อนพื้นหลังทึบของ List
                        .listStyle(.insetGrouped)       // ⬅️ ✨ 2. ทำให้ขอบมนและดูเหมือนการ์ด
                        .toolbar {
//                            ToolbarItem(placement: .navigationBarTrailing) {
//                                if !appState.activities.isEmpty {
//                                    EditButton()
//                                        .foregroundColor(.black)
//                                }
//                            }
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("เพิ่ม") {
                                    showingAddActivity = true
                                }
                                .foregroundColor(.black)
                            }
                        }
                    }

                    Spacer() // Push content to the top
                }
            }
            .navigationTitle("กิจกรรมของคุณ")
            
            // ⭐️⭐️⭐️======= โค้ดที่ปรับปรุงอยู่ตรงนี้ =======⭐️⭐️⭐️
            .sheet(isPresented: $showingAddActivity) {
                NavigationStack {
                    ZStack {
                        // ✅ 1. ใช้พื้นหลัง Gradient เดิมของคุณ
                        LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            // ✅ 2. เพิ่มคำอธิบายเล็กน้อย
                            Text("กรุณาป้อนชื่อกิจกรรมใหม่")
                                .font(.headline)
                                .foregroundColor(.black.opacity(0.7))
                                .padding(.top, 20) // เพิ่มช่องว่างจาก Title
                            
                            // ✅ 3. จัดสไตล์ TextField ใหม่ให้สวยงาม
                            TextField("เช่น 'กิจกรรมรับน้อง', 'ไหว้ครู'", text: $newActivityName)
                                .padding() // เพิ่ม padding ให้ช่องกรอก
                                .background(Color.white.opacity(0.8)) // พื้นหลังสีขาวกึ่งโปร่งแสง
                                .cornerRadius(10) // ขอบมน
                                .overlay(
                                    // เพิ่มเส้นขอบบางๆ
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                            
                            Spacer() // ดันทุกอย่างขึ้นบน
                        }
                        .padding() // เว้นขอบซ้ายขวา
                    }
                    .navigationTitle("สร้างกิจกรรมใหม่") // ✅ 4. เพิ่ม Title ให้หน้านี้
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        // ✅ 5. ย้ายปุ่ม 'ยกเลิก' มาไว้บน Toolbar
                        ToolbarItem(placement: .cancellationAction) {
                            Button("ยกเลิก") {
                                showingAddActivity = false
                                newActivityName = "" // เคลียร์ค่าเมื่อยกเลิก
                            }
                            .foregroundColor(swuRed) // ใช้สีธีมของแอป
                        }
                        
                        // ✅ 6. ย้ายปุ่ม 'สร้าง' มาไว้บน Toolbar
                        ToolbarItem(placement: .confirmationAction) {
                            Button("สร้าง") {
                                if !newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    appState.addActivity(name: newActivityName)
                                    newActivityName = ""
                                    showingAddActivity = false
                                }
                            }
                            .bold() // ทำให้ปุ่มหลักชัดเจน
                            .disabled(newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            // ⭐️⭐️⭐️======= สิ้นสุดโค้ดที่ปรับปรุง =======⭐️⭐️⭐️
            
            // ✅ Alert ยืนยันการลบ
            .alert("ยืนยันการลบ?", isPresented: $showDeleteConfirmation, actions: {
                Button("ยกเลิก", role: .cancel) {
                    showDeleteConfirmation = false
                    deleteIndex = nil
                }
                Button("ลบ", role: .destructive) {
                    if let index = deleteIndex {
                        let activityToDelete = appState.activities[index]
                        appState.deleteActivity(activity: activityToDelete)
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
            .sheet(isPresented: $showEditActivity) {
                EditActivityView(
                    showEditActivity: $showEditActivity,
                    activityName: $editActivityName,
                    onSave: {
                        if let index = editIndex {
                            let activity = appState.activities[index]
                            activity.name = editActivityName
                            appState.updateActivity(activity: activity)
                        }
                    }
                )
            }
        }
    }

    // ✅ ฟังก์ชันลบกิจกรรม — แสดง Alert ก่อนลบ
    func deleteActivities(offsets: IndexSet) {
        if let index = offsets.first {
            deleteIndex = index
            showDeleteConfirmation = true
        }
    }
}

struct ActivityNavigationLink: View {
    @ObservedObject var activity: Activity

    var body: some View {
        NavigationLink(
            destination: QueueView(activity: .constant(activity)) // Use a constant binding
                .environmentObject(AppState())
        ) {
            Text(activity.name)
                .font(.body)
                .foregroundColor(.black)
        }
    }
}


struct EditActivityView: View {
    @Binding var showEditActivity: Bool
    @Binding var activityName: String
    var onSave: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                TextField("Activity Name", text: $activityName)
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.bottom, 20)

                HStack {
                    Button("Cancel") {
                        showEditActivity = false
                    }
                    .foregroundColor(.black)
                    Spacer()
                    Button("Save") {
                        onSave()
                        showEditActivity = false
                    }
                    .foregroundColor(.black)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Edit Activity Name")
            .navigationBarTitleDisplayMode(.inline)
            
            // ⭐️ หมายเหตุ: EditActivityView ยังไม่ได้ใส่พื้นหลัง Gradient
            // ถ้าอยากให้สวยเหมือนกัน สามารถเพิ่ม ZStack และ LinearGradient
            // แบบเดียวกับที่ทำใน .sheet(isPresented: $showingAddActivity) ได้ครับ
        }
    }
}


#Preview {
    ActivityListView().environmentObject(AppState())
}
