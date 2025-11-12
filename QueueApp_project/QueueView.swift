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

    var body: some View {
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
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(activity.queues.isEmpty || isCountingDown)

            // ปุ่มเพิ่มคิว
            Button("เพิ่มคิว") {
                showingAddQueue = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            // รายการคิว
            List(activity.queues) { item in
                HStack {
                    Text("#\(item.number)")
                    Text("\(item.studentName) (\(item.studentId))")
                }
            }
            .frame(maxHeight: 200)

            Spacer()
        }
        .navigationTitle(activity.name)
        .sheet(isPresented: $showingAddQueue) {
            NavigationStack {
                VStack {
                    Text("เพิ่มคิวใหม่")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()

                    TextField("ชื่อลูกค้า", text: $newCustomerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    HStack {
                        Button("ยกเลิก") { showingAddQueue = false }
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
                    }
                    .padding()
                }
                .padding()
            }
        }
        .actionSheet(isPresented: $showingCallOptions) {
            ActionSheet(title: Text("เลือกการกระทำ"), buttons: [
                .default(Text("✅ มาแล้ว")) {
                    if !activity.queues.isEmpty {
                        activity.queues.removeFirst()
                    }
                },
                .default(Text("⏳ ยังไม่มา")) {
                    isCountingDown = true
                },
                .default(Text("⏭️ ข้ามคิว")) {
                    if !activity.queues.isEmpty {
                        activity.queues.removeFirst()
                    }
                },
                .cancel()
            ])
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
        }, message: {
            Text("ลูกค้าไม่มาภายในเวลาที่กำหนด\nจึงข้ามคิวไปแล้ว")
        })
    }
}

// ✅ Modal สำหรับนับถอยหลัง — จัดการ Timer และลบคิวด้วยตัวเอง
struct CountdownModal: View {
    @Binding var isActive: Bool
    let onTimeout: () -> Void
    let onCancel: () -> Void

    @State private var seconds = 10
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            Text("ยังไม่มา?")
                .font(.title)
                .fontWeight(.bold)

            Text("เหลือเวลา \(seconds) วินาที")
                .font(.headline)

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
        }
        .padding()
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
