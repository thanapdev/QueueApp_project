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

    // SWU Colors (From LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

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

            VStack(spacing: 20) {
                // ส่วนแสดงคิวถัดไป
                if let next = activity.queues.first {
                    VStack {
                        Text("คิวถัดไป")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("#\(next.number) - \(next.studentName)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .padding(.bottom)
                } else {
                    Text("ยังไม่มีคิว")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }

                // ปุ่มเรียกคิว
                Button("เรียกคิวถัดไป") {
                    if !activity.queues.isEmpty {
                        showingCallOptions = true
                    }
                }
                .padding()
                .background(swuRed)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(activity.queues.isEmpty || isCountingDown)
                .confirmationDialog(
                    "เลือกการกระทำ",
                    isPresented: $showingCallOptions,
                    titleVisibility: .visible
                ) {
                    Button("✅ มาแล้ว") {
                        if !activity.queues.isEmpty {
                            activity.queues.removeFirst()
                        }
                    }
                    .foregroundColor(.black)
                    Button("⏳ ยังไม่มา") {
                        isCountingDown = true
                    }
                    .foregroundColor(.black)
                    Button("⏭️ ข้ามคิว") {
                        if !activity.queues.isEmpty {
                            activity.queues.removeFirst()
                        }
                    }
                    .foregroundColor(.black)
                    Button("ยกเลิก", role: .cancel) { }
                        .foregroundColor(.black)
                }

                // ปุ่มเพิ่มคิว
                Button("เพิ่มคิว") {
                    showingAddQueue = true
                }
                .padding()
                .background(swuRed)
                .foregroundColor(.white)
                .cornerRadius(10)

                // รายการคิว
                List(activity.queues) { item in
                    HStack {
                        Text("#\(item.number)")
                            .foregroundColor(.black)
                        Text("\(item.studentName) (\(item.studentId))")
                            .foregroundColor(.black)
                    }
                    .listRowBackground(Color.white.opacity(0.7))
                }
                .frame(maxHeight: 200)

                Spacer()
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
                                            studentId: "MANUAL-\(activity.nextQueueNumber)",
                                            studentName: newCustomerName,
                                            number: activity.nextQueueNumber
                                        )
                                        activity.queues.append(newItem)
                                        activity.nextQueueNumber += 1
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
                        if !activity.queues.isEmpty {
                            activity.queues.removeFirst() // ✅ ลบเพียงครั้งเดียว
                        }
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
    let swuRed = Color(red: 190/255, green: 50/255, blue: 150/255)

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
        QueueItem(studentId: "654231001", studentName: "สมปอง", number: 1)
    ])
    return QueueView(activity: $activity)
}
