//
//  QueueView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

// MARK: - Queue View (Admin)
// หน้าจัดการคิวสำหรับกิจกรรม (Activity)
// Admin สามารถเรียกคิวถัดไป, ข้ามคิว, หรือเพิ่มคิวแบบ Manual ได้
struct QueueView: View {
    // MARK: - Properties
    @Binding var activity: Activity
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddQueue = false
    @State private var newCustomerName = ""
    @State private var showingCallOptions = false
    @State private var isCountingDown = false
    @State private var showTimeoutMessage = false
    
    // Local state for queue items (to manage filtering/sorting locally if needed)
    @State private var queueItems: [QueueItem] = []

    // Computed property: คิวถัดไปที่จะถูกเรียก
    private var nextQueueItem: QueueItem? {
        queueItems.first
    }

    var body: some View {
        ZStack {
            // 1. Background (Theme ใหม่)
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // ---------------------------------------
                // HEADER
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
                    
                    // Title
                    Text(activity.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                        .lineLimit(2)
                    
                    Text("จัดการคิว (Admin Panel)")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                
                // ---------------------------------------
                // CONTENT (White Sheet)
                // ---------------------------------------
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    VStack(spacing: 24) {
                        
                        // 1. Current Queue Card (การ์ดแสดงคิวปัจจุบัน)
                        VStack(spacing: 10) {
                            Text("NOW SERVING")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            if let next = nextQueueItem {
                                Text("#\(next.number)")
                                    .font(.system(size: 80, weight: .heavy))
                                    .foregroundColor(Color.Theme.primary)
                                
                                Text(next.studentName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.Theme.textDark)
                                
                                Text(next.studentId)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                // Empty State (ไม่มีคิวรอ)
                                VStack(spacing: 15) {
                                    Image(systemName: "moon.zzz.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("ไม่มีคิวรอ")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                        
                        // 2. Action Buttons
                        HStack(spacing: 15) {
                            // ปุ่มเพิ่มคิว (Manual Add)
                            Button(action: {
                                showingAddQueue = true
                            }) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                    Text("Add Queue")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(Color.Theme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.Theme.primary.opacity(0.1))
                                .cornerRadius(15)
                            }
                            
                            // ปุ่มเรียกคิว (Call Next)
                            Button(action: {
                                if !queueItems.isEmpty {
                                    showingCallOptions = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                    Text("Call Next")
                                }
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(queueItems.isEmpty ? Color.gray : Color.Theme.primary)
                                .cornerRadius(15)
                                .shadow(color: queueItems.isEmpty ? .clear : Color.Theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .disabled(queueItems.isEmpty || isCountingDown)
                        }
                        .padding(.horizontal, 30)
                        
                        // 3. Waiting List Header
                        HStack {
                            Text("Waiting List")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.Theme.textDark)
                            Spacer()
                            Text("\(queueItems.count) People")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 30)
                        
                        // 4. Waiting List (ScrollView)
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(queueItems) { item in
                                    HStack(spacing: 15) {
                                        // Queue Number
                                        Text("#\(item.number)")
                                            .font(.title3)
                                            .fontWeight(.heavy)
                                            .foregroundColor(Color.Theme.primary)
                                            .frame(width: 50)
                                        
                                        // Divider
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 1, height: 30)
                                        
                                        // Info
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.studentName)
                                                .font(.headline)
                                                .foregroundColor(Color.Theme.textDark)
                                            Text(item.studentId)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        // Status (if any)
                                        if let status = item.status {
                                            Text(status)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.gray)
                                                .padding(6)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(6)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 50)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .onAppear {
            loadQueueItems()
        }
        .onChange(of: activity.id) { _ in
            loadQueueItems()
        }
        
        // MARK: - Action Sheets & Alerts
        // Dialog เลือกสถานะเมื่อเรียกคิว (มาแล้ว / ไม่มา / ข้าม)
        .confirmationDialog("Action for Queue #\(nextQueueItem?.number ?? 0)", isPresented: $showingCallOptions, titleVisibility: .visible) {
            Button("✅ Customer Arrived") {
                callNextQueue(status: "มาแล้ว")
            }
            Button("⏳ Not Here (Timer)") {
                isCountingDown = true
            }
            Button("⏭️ Skip Queue") {
                callNextQueue(status: "ข้ามคิว")
            }
            Button("Cancel", role: .cancel) { }
        }
        // Sheet นับถอยหลัง (Timer)
        .sheet(isPresented: $isCountingDown) {
            CountdownModal(
                isActive: $isCountingDown,
                onTimeout: { callNextQueue(status: "หมดเวลา") },
                onCancel: { /* Do nothing */ }
            )
            .presentationDetents([.medium])
        }
        // Sheet เพิ่มคิว Manual
        .sheet(isPresented: $showingAddQueue) {
            // Custom Add Queue Sheet
            AddQueueSheet(
                isPresented: $showingAddQueue,
                customerName: $newCustomerName,
                onAdd: {
                    addManualQueue()
                }
            )
        }
        .alert("Time's Up!", isPresented: $showTimeoutMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Customer didn't arrive in time.\nQueue skipped automatically.")
        }
    }
    
    // MARK: - Logic Functions
    
    // โหลดรายการคิวจาก Firestore
    private func loadQueueItems() {
        appState.loadQueueItems(activity: activity) { loadedQueueItems in
            queueItems = loadedQueueItems
            activity.queueCount = loadedQueueItems.count
            appState.updateActivity(activity: activity)
        }
    }

    // เรียกคิวถัดไปและอัปเดตสถานะ
    private func callNextQueue(status: String) {
        guard let firstQueueItem = queueItems.first else { return }
        
        var updatedItem = firstQueueItem
        updatedItem.status = status
        appState.updateQueueItemStatus(activity: activity, queueItem: updatedItem, status: status)
        
        if let index = queueItems.firstIndex(where: { $0.id == firstQueueItem.id }) {
            queueItems.remove(at: index)
            activity.queueCount = queueItems.count
            appState.updateActivity(activity: activity)
        }
        activity.currentQueueNumber = nil
        appState.updateActivity(activity: activity)
    }
    
    // เพิ่มคิวแบบ Manual
    private func addManualQueue() {
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
            appState.updateActivity(activity: activity)
            newCustomerName = ""
            showingAddQueue = false
        }
    }
}

// MARK: - Helper View: Add Queue Sheet
// หน้าต่างสำหรับเพิ่มคิวด้วยตัวเอง
struct AddQueueSheet: View {
    @Binding var isPresented: Bool
    @Binding var customerName: String
    var onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                DynamicBackground(style: .random)
                
                VStack(spacing: 20) {
                    Text("Add New Queue")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 20)
                    
                    TextField("Customer Name", text: $customerName)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { onAdd() }
                        .bold()
                        .disabled(customerName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Helper View: Countdown Modal
// หน้าต่างนับถอยหลังเมื่อเรียกลูกค้าแล้วยังไม่มา
struct CountdownModal: View {
    @Binding var isActive: Bool
    let onTimeout: () -> Void
    let onCancel: () -> Void

    @State private var seconds = 10
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Waiting for Customer...")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                ZStack {
                    Circle()
                        .stroke(lineWidth: 15)
                        .opacity(0.1)
                        .foregroundColor(.orange)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(seconds) / 10.0)
                        .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.orange)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: seconds)
                    
                    Text("\(seconds)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.orange)
                }
                .frame(width: 150, height: 150)
                .padding()

                Text("Auto-skip if not arrived")
                    .font(.caption)
                    .foregroundColor(.gray)

                Button(action: {
                    timer?.invalidate()
                    onCancel()
                    isActive = false
                }) {
                    Text("Cancel Timer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            .padding()
        }
        .onAppear { startTimer() }
        .onDisappear {
            timer?.invalidate()
            if seconds == 0 { onTimeout() }
        }
    }

    private func startTimer() {
        seconds = 10
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if seconds > 0 {
                seconds -= 1
            }
            DispatchQueue.main.async {
                if seconds == 0 {
                    timer?.invalidate()
                    isActive = false
                }
            }
        }
    }
}
