//
//  StudentQueueJoinView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - Student Queue Join View
// หน้าต่อคิวกิจกรรม (Join Queue)
// ทำหน้าที่:
// 1. แสดงรายละเอียดกิจกรรม
// 2. แสดงคิวที่รออยู่และคิวปัจจุบัน
// 3. ต่อคิวและยกเลิกคิว
struct StudentQueueJoinView: View {
    // MARK: - Properties
    @EnvironmentObject var appState: AppState               // Global state
    @ObservedObject var activity: Activity                  // กิจกรรมที่เลือก (ObservableObject สำหรับ Real-time update)
    @Environment(\.presentationMode) var presentationMode   // ใช้สำหรับปิดหน้านี้
    
    // Computed Property: Check if user joined based on current queues
    // ตรวจสอบว่าผู้ใช้จองคิวไปแล้วหรือยัง
    var isJoined: Bool {
        guard let studentId = appState.currentUser?.id else { return false }
        // เช็กจาก array queues ที่ activity ถืออยู่ (ซึ่งอัปเดต real-time จาก Listener ใน AppState)
        return activity.queues.contains { $0.studentId == studentId }
    }

    var body: some View {
        ZStack {
            // 1. Background (Theme ใหม่)
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
           
                // HEADER SECTION
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
                    
                    Text("รายละเอียดการจองคิว")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
   
                // CONTENT AREA (White Sheet)
                ZStack {
                    Color.Theme.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        if isJoined {
                     
                            // CASE 1: JOINED (แสดงสถานะคิว)
                            if let myQueue = activity.queues.first(where: { $0.studentId == appState.currentUser?.id }),
                               let myIndex = activity.queues.firstIndex(where: { $0.id == myQueue.id }) {
                                
                                let myPosition = myIndex + 1
                                let queuesAhead = myIndex // จำนวนคิวที่รอ
                                
                                VStack(spacing: 25) {
                                    // --- Status Circle ---
                                    ZStack {
                                        Circle()
                                            .stroke(lineWidth: 15)
                                            .foregroundColor(Color.Theme.primary.opacity(0.1))
                                            .frame(width: 220, height: 220)
                                        
                                        if queuesAhead == 0 {
                                            // ถึงคิวแล้ว!
                                            Circle()
                                                .trim(from: 0.0, to: 1.0)
                                                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                                .foregroundColor(.green)
                                                .frame(width: 220, height: 220)
                                                .rotationEffect(.degrees(-90))
                                            
                                            VStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundColor(.green)
                                                Text("ถึงคิวคุณแล้ว!")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.green)
                                            }
                                        } else {
                                            // ยังรออยู่
                                            Circle()
                                                .trim(from: 0.0, to: 0.75)
                                                .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                                .foregroundColor(Color.Theme.primary)
                                                .frame(width: 220, height: 220)
                                                .rotationEffect(.degrees(-90))
                                            
                                            VStack {
                                                Text("รออีก")
                                                    .font(.headline)
                                                    .foregroundColor(.gray)
                                                Text("\(queuesAhead)")
                                                    .font(.system(size: 70, weight: .heavy))
                                                    .foregroundColor(Color.Theme.primary)
                                                Text("คิว")
                                                    .font(.headline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding(.top, 20)
                                    
                                    // Info Text
                                    VStack(spacing: 5) {
                                        Text("หมายเลขคิวของคุณ")
                                            .foregroundColor(.gray)
                                        Text("#\(myQueue.number)") // แสดงเบอร์คิวจริงๆ
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color.Theme.textDark)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.Theme.primary.opacity(0.05))
                                    .cornerRadius(15)
                                    
                                    Spacer()
                                    
                                    // Cancel Button
                                    Button(action: {
                                        leaveQueue()
                                    }) {
                                        Text("ยกเลิกการจอง")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(15)
                                    }
                                    .padding(.bottom, 40)
                                }
                                
                            } else {
                                // Loading State (กรณีข้อมูลยังไม่มา หรือหาไม่เจอ)
                                ProgressView("กำลังโหลดข้อมูล...")
                            }
                            
                        } else {

                            // CASE 2: NOT JOINED (ยังไม่จอง)
                            VStack(spacing: 30) {
                                Image(systemName: "person.3.sequence.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(Color.Theme.primary.opacity(0.5))
                                
                                VStack(spacing: 10) {
                                    Text("คุณยังไม่ได้จองคิว")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.Theme.textDark)
                                    
                                    Text("กดปุ่มด้านล่างเพื่อรับบัตรคิว\nและรอเรียกคิวของคุณ")
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // Join Button
                                Button(action: {
                                    joinQueue()
                                }) {
                                    HStack {
                                        Text("กดเพื่อรับบัตรคิว")
                                        Image(systemName: "ticket.fill")
                                    }
                                }
                                .buttonStyle(BluePillButtonStyle())
                                .padding(.bottom, 40)
                            }
                            .padding(.top, 50)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(true)
        .onAppear {
            // เรียก Listener เพื่อให้ activity.queues อัปเดตตลอดเวลา
            appState.startListening(to: activity)
            print("StudentQueueJoinView Appeared: \(activity.name)")
        }
        .onDisappear {
            // หยุด Listener เมื่อออกจากหน้า
            appState.stopListening(to: activity)
            print("StudentQueueJoinView Disappeared: \(activity.name)")
        }
    }
    
    // MARK: - LOGIC FUNCTIONS (เหมือนเดิมเป๊ะ)
    // ฟังก์ชันจองคิว
    func joinQueue() {
        guard let student = appState.currentUser else { return }
        
        // สร้าง QueueItem ใหม่
        // หมายเหตุ: id ควรจะเป็น UUID string ที่ตรงกับ documentID ใน Firestore
        let newItem = QueueItem(
            id: UUID(),
            studentId: student.id,
            studentName: student.name,
            number: activity.nextQueueNumber,
            status: nil
        )
        
        print("Joining queue: \(newItem)")
        appState.addQueueItem(activity: activity, queueItem: newItem)
    }

    // ฟังก์ชันยกเลิกคิว
    func leaveQueue() {
        guard let student = appState.currentUser else { return }
        
        // หา QueueItem ของเราจาก activity.queues
        if let myQueue = activity.queues.first(where: { $0.studentId == student.id }) {
            print("Leaving queue: \(myQueue)")
            // ส่งไปอัปเดต Status ใน Firestore
            appState.updateQueueItemStatus(activity: activity, queueItem: myQueue, status: "ยกเลิกคิว")
        } else {
            print("Error: Could not find queue item to leave.")
        }
    }
}

//struct StudentQueueJoinView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Mock Data
//        let dummyActivity = Activity(id: UUID(), name: "Mock Activity", description: "Test", queues: [], nextQueueNumber: 1, currentQueueNumber: nil, queueCount: 0)
//        StudentQueueJoinView(activity: dummyActivity)
//            .environmentObject(AppState())
//    }
//}
