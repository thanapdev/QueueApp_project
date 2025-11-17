import SwiftUI

struct StudentQueueJoinView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var activity: Activity

    // <<< เปลี่ยน isJoined จาก @State เป็น Computed Property >>>
    var isJoined: Bool {
        guard let studentId = appState.currentUser?.id else { return false }
        let result = activity.queues.contains { $0.studentId == studentId }
        print("StudentQueueJoinView: isJoined computed to \(result) for student ID \(studentId ?? "N/A")")
        return result
    }

    // SWU Colors (From StudentActivityListView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    var body: some View {
        ZStack {
            // Background (Gradient From StudentActivityListView.swift)
            LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            // Shape Background (Circles From StudentActivityListView.swift)
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

            VStack(spacing: 24) {
                Text("กิจกรรม: \(activity.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                if isJoined { // ถ้าเข้าร่วมแล้ว
                    if let myQueue = activity.queues.first(where: { $0.studentId == appState.currentUser?.id }) {
                        if let myIndex = activity.queues.firstIndex(where: { $0.id == myQueue.id }) {
                            let myPosition = myIndex + 1
                            let queuesAhead = myIndex // คนข้างหน้า = จำนวนคิวที่ต้องรอ

                            VStack(spacing: 16) {
                                // ✅ 1. อีกกี่คิวจะถึงเรา → เน้นสุด!
                                if queuesAhead > 0 {
                                    VStack {
                                        Text("อีก")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        Text("\(queuesAhead) คิว")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.blue)
                                            .padding(.bottom, 4)
                                        Text("จะถึงคิวคุณ")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1)) // ใช้สีฟ้าอ่อนๆ
                                    .cornerRadius(16)
                                    
                                } else {
                                    // ✅ ถึงคิวแล้ว → แจ้งเตือนสวย ๆ
                                    VStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.green)
                                            .padding(.bottom, 8)
                                        Text("ถึงคิวคุณแล้ว!")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(16)
                                }

                                // ✅ 2. คุณอยู่คิวที่ #\(myPosition)
                                Text("คุณอยู่คิวที่ #\(myPosition)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Button("ยกเลิกคิว") {
                                    print("StudentQueueJoinView: Leave queue button pressed.")
                                    leaveQueue()
                                }
                                .padding()
                                .background(swuRed) // Use SWU red for button
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 3) // Adding shadow for the button
                            }
                            .padding()
                            .background(.white) // Adding a background for better readability
                            .cornerRadius(10)
                            .shadow(radius: 3)
                        }
                    } else {
                        // กรณีที่ isJoined เป็น true แต่หาคิวของตัวเองไม่เจอ (อาจเกิดจากข้อมูลยังไม่ sync)
                        Text("กำลังโหลดข้อมูลคิว...")
                            .foregroundColor(.gray)
                    }
                } else { // ถ้ายังไม่ได้เข้าร่วม
                    Button("ต่อคิว") {
                        print("StudentQueueJoinView: Join queue button pressed.")
                        joinQueue()
                    }
                    .padding()
                    .background(swuRed) // Use SWU red for button
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 3) // Adding shadow for the button
                }

                Spacer()
            }
            .padding()
            .navigationTitle("ต่อคิว")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // ไม่ต้องเรียก checkIfJoined() ตรงนี้แล้ว เพราะ isJoined เป็น computed property
            appState.startListening(to: activity)
            print("StudentQueueJoinView ปรากฏขึ้นสำหรับกิจกรรม: \(activity.name).")
        }
        .onDisappear {
            appState.stopListening(to: activity)
            print("StudentQueueJoinView หายไปสำหรับกิจกรรม: \(activity.name).")
        }
    }

    func joinQueue() {
        guard let student = appState.currentUser else {
            print("StudentQueueJoinView: No current user to join queue.")
            return
        }
        let newItem = QueueItem(
            id: UUID(),
            studentId: student.id,
            studentName: student.name,
            number: activity.nextQueueNumber,
            status: nil
        )
        print("StudentQueueJoinView: Adding queue item for \(student.name), number \(newItem.number)")
        appState.addQueueItem(activity: activity, queueItem: newItem)
        // isJoined จะถูกอัปเดตอัตโนมัติเมื่อ activity.queues เปลี่ยนผ่าน listener
    }

    func leaveQueue() {
        guard let student = appState.currentUser else {
            print("StudentQueueJoinView: No current user to leave queue.")
            return
        }
        if let myQueue = activity.queues.first(where: { $0.studentId == student.id }) {
            print("StudentQueueJoinView: Updating status to 'ยกเลิกคิว' for \(myQueue.studentName), number \(myQueue.number)")
            appState.updateQueueItemStatus(activity: activity, queueItem: myQueue, status: "ยกเลิกคิว")
            // isJoined จะถูกอัปเดตอัตโนมัติเมื่อ activity.queues เปลี่ยนผ่าน listener
        } else {
            print("StudentQueueJoinView: Could not find student's queue to leave.")
        }
    }
    
    // <<< ลบฟังก์ชัน checkIfJoined() ออกไป เพราะไม่จำเป็นแล้ว >>>
    // func checkIfJoined() {
    //    guard let studentId = appState.currentUser?.id else {
    //        isJoined = false
    //        return
    //    }
    //    isJoined = activity.queues.contains { $0.studentId == studentId }
    // }
}
