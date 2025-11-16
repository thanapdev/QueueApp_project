//
//  AppState.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

struct QueueView: View {
    @Binding var activity: Activity
    @State private var showingAddQueue = false
    @State private var newCustomerName = ""
    @State private var showingCallOptions = false
    @State private var isCountingDown = false // ควบคุมการเปิด Modal
    @State private var showTimeoutMessage = false
    @EnvironmentObject var appState: AppState
    @State private var queueItems: [QueueItem] = [] // Local state for queue items

    // SWU Colors (From LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    // Computed property to get the next queue item
    private var nextQueueItem: QueueItem? {
        queueItems.first
    }

    var body: some View {
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

            VStack(spacing: 16) { // 👈 ปรับ spacing เล็กน้อย
                            // ⭐️ 1. ส่วนแสดงคิวถัดไป (ปรับเป็นการ์ดขาว)
                            if let next = nextQueueItem {
                                VStack {
                                    Text("คิวถัดไป")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("#\(next.number) - \(next.studentName)")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black) // 👈 เปลี่ยนเป็นสีดำ
                                }
                                .padding()
                                .frame(maxWidth: .infinity) // 👈 ทำให้เต็มความกว้าง
                                .background(.white) // 👈 ใช้พื้นหลังขาว
                                .cornerRadius(12) // 👈 ขอบมน
                                .shadow(radius: 3) // 👈 ใส่เงา
                                .padding(.horizontal) // 👈 เว้นขอบซ้ายขวา
                                
                            } else {
                                Text("ยังไม่มีคิว")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 32) // 👈 เพิ่ม padding ให้ไม่โล่งไป
                            }

                            // ⭐️ 2. ปุ่มเรียกคิว (ปรับให้เต็มความกว้าง)
                            Button("เรียกคิวถัดไป") {
                                if !queueItems.isEmpty {
                                    showingCallOptions = true
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity) // 👈 ทำให้เต็มความกว้าง (ใน padding)
                            .background(swuRed)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal) // 👈 เว้นขอบซ้ายขวา
                            .disabled(queueItems.isEmpty || isCountingDown)
                            .confirmationDialog(
                                "เลือกการกระทำ",
                                isPresented: $showingCallOptions,
                                titleVisibility: .visible
                            ) {
                                Button("✅ มาแล้ว") {
                                    callNextQueue(status: "มาแล้ว")
                                }
                                .foregroundColor(.black)
                                Button("⏳ ยังไม่มา") {
                                    isCountingDown = true
                                }
                                .foregroundColor(.black)
                                Button("⏭️ ข้ามคิว") {
                                    callNextQueue(status: "ข้ามคิว")
                                }
                                .foregroundColor(.black)
                                Button("ยกเลิก", role: .cancel) { }
                                    .foregroundColor(.black)
                            }

                            // ⭐️ 2. ปุ่มเพิ่มคิว (ปรับให้เต็มความกว้าง)
                            Button("เพิ่มคิว") {
                                showingAddQueue = true
                            }
                            .padding()
                            .frame(maxWidth: .infinity) // 👈 ทำให้เต็มความกว้าง (ใน padding)
                            .background(swuRed)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal) // 👈 เว้นขอบซ้ายขวา

                            // ⭐️ 3. รายการคิว (เปลี่ยนจาก List เป็น ScrollView)
                            Text("คิวที่กำลังรอ")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(queueItems) { item in
                                        // ⭐️ นี่คือการ์ดของแต่ละคิว
                                        HStack {
                                            Text("#\(item.number)")
                                                .font(.title.weight(.bold))
                                                .foregroundColor(swuRed) // 👈 ใช้สีแดง SWU ให้เด่น
                                            
                                            VStack(alignment: .leading) {
                                                Text(item.studentName)
                                                    .font(.headline)
                                                    .foregroundColor(.black)
                                                Text(item.studentId)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if let status = item.status {
                                                Text(status)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                    .italic()
                                            }
                                        }
                                        .padding()
                                        .background(.white)
                                        .cornerRadius(12)
                                        .shadow(radius: 3)
                                    }
                                }
                                .padding(.horizontal) // 👈 เว้นขอบซ้ายขวาให้ ScrollView
                                .padding(.bottom) // 👈 เว้นด้านล่างหน่อย
                            }
                            // ❗️ ลบ .frame(maxHeight: 200) ทิ้งไปเลย

                            Spacer() // 👈 Spacer ตัวนี้ยังอยู่เหมือนเดิม
                        }
            .navigationTitle(activity.name)
            .sheet(isPresented: $showingAddQueue) {
                NavigationStack {
                    ZStack {
                        LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                            .edgesIgnoringSafeArea(.all)

                        VStack {
                            Text("เพิ่มคิวใหม่")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                                .foregroundColor(.black)

                            TextField("ชื่อลูกค้า", text: $newCustomerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(8)
                                .foregroundColor(.black)

                            HStack {
                                Button("ยกเลิก") { showingAddQueue = false }
                                    .foregroundColor(.black)
                                Spacer()
                                Button("เพิ่ม") {
                                    if !newCustomerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        let newItem = QueueItem(
                                            id: UUID(),
                                            studentId: "MANUAL-\(activity.nextQueueNumber)",
                                            studentName: newCustomerName,
                                            number: activity.nextQueueNumber,
                                            status: nil
                                        )
                                        appState.addQueueItem(activity: activity, queueItem: newItem)
                                        queueItems.append(newItem)
                                        activity.nextQueueNumber += 1
                                        appState.updateActivity(activity: activity) // Update nextQueueNumber in Firestore
                                        newCustomerName = ""
                                    }
                                    showingAddQueue = false
                                }
                                .disabled(newCustomerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .foregroundColor(.black)
                            }
                            .padding()
                        }
                        .padding()
                    }
                }
            }
            .sheet(isPresented: $isCountingDown) {
                CountdownModal(
                    isActive: $isCountingDown,
                    onTimeout: {
                        callNextQueue(status: "หมดเวลา")
                    },
                    onCancel: {
                        // ไม่ทำอะไร — ไม่ลบคิว
                    }
                )
                .presentationDetents([.medium])
            }
            .alert("มาช้าเกินไป!", isPresented: $showTimeoutMessage, actions: {
                Button("ตกลง") {
                    showTimeoutMessage = false
                }
                .foregroundColor(.black)
            }, message: {
                Text("ลูกค้าไม่มาภายในเวลาที่กำหนด\nจึงข้ามคิวไปแล้ว")
            })
        }
        .onAppear {
            loadQueueItems()
        }
        .onChange(of: activity.id) { _ in
            loadQueueItems()
        }
    }

    private func loadQueueItems() {
        appState.loadQueueItems(activity: activity) { loadedQueueItems in
            queueItems = loadedQueueItems
        }
    }


    private func callNextQueue(status: String) {
        guard let firstQueueItem = queueItems.first else {
            return
        }

        var updatedItem = firstQueueItem
        updatedItem.status = status
        appState.updateQueueItemStatus(activity: activity, queueItem: updatedItem, status: status)
        queueItems.removeFirst()
        activity.currentQueueNumber = nil
        appState.updateActivity(activity: activity) // Update currentQueueNumber
    }
}

// ✅ Modal สำหรับนับถอยหลัง — จัดการ Timer และลบคิวด้วยตัวเอง
struct CountdownModal: View {
    @Binding var isActive: Bool
    let onTimeout: () -> Void
    let onCancel: () -> Void

    @State private var seconds = 10
    @State private var timer: Timer?

    // SWU Colors (From LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 150/255, blue: 150/255)

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("ยังไม่มา?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text("เหลือเวลา \(seconds) วินาที")
                    .font(.headline)
                    .foregroundColor(.black)

                ProgressView(value: Double(seconds), total: 10.0)
                    .tint(.orange)
                    .padding()

                Text("หากไม่มา จะข้ามคิวอัตโนมัติ")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("ยกเลิก") {
                    timer?.invalidate()
                    onCancel()
                    isActive = false
                }
                .buttonStyle(.bordered)
                .foregroundColor(.black)
            }
            .padding()
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
            if seconds == 0 {
                onTimeout()
            }
        }
    }

    private func startTimer() {
        seconds = 10
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if seconds > 0 {
                seconds -= 1
            } else {
                timer?.invalidate()
                DispatchQueue.main.async {
                    isActive = false
                }
            }
        }
    }
}

#Preview {
    @State var activity: Activity = Activity(name: "ตัวอย่างกิจกรรม", queues: [
        QueueItem(id: UUID(), studentId: "654231001", studentName: "สมปอง", number: 1)
    ])
     QueueView(activity: $activity)
}
