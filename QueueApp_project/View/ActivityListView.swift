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

    // SWU Colors (From LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    var body: some View {
        NavigationView {
            ZStack {
                // Background (Gradient From LoginView.swift)
                LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                // Shape Background (Circles From LoginView.swift)
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
                                NavigationLink(
                                    destination: QueueView(activity: $appState.activities[index])
                                        .environmentObject(appState)
                                ) {
                                    Text(appState.activities[index].name)
                                        .font(.body)
                                        .foregroundColor(.black)
                                }
                                .listRowBackground(Color.white.opacity(0.7))
                            }
                            .onDelete(perform: deleteActivities)
                        }
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                if !appState.activities.isEmpty {
                                    EditButton()
                                        .foregroundColor(.black)
                                }
                            }
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
            .sheet(isPresented: $showingAddActivity) {
                NavigationStack {
                    VStack {
                        ZStack {
                            LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                                .edgesIgnoringSafeArea(.all)

                            VStack {
                                TextField("ชื่อกิจกรรม", text: $newActivityName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding()
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(8)

                                HStack {
                                    Button("ยกเลิก") {
                                        showingAddActivity = false
                                    }
                                    .foregroundColor(.black)
                                    Spacer()
                                    Button("สร้าง") {
                                        if !newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            appState.addActivity(name: newActivityName)
                                            newActivityName = ""
                                            showingAddActivity = false
                                        }
                                    }
                                    .disabled(newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    .foregroundColor(.black)
                                }
                                .padding()
                            }
                            .padding()
                        }
                    }
                    
                }
                .background(LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
                    .edgesIgnoringSafeArea(.all)
            }
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

#Preview {
    ActivityListView().environmentObject(AppState())
}
