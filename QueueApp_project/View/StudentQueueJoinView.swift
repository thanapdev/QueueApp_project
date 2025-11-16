import SwiftUI

struct StudentQueueJoinView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var activity: Activity

    @State private var isJoined = false

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

                if isJoined {
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
                                                                // ⭐️ เพิ่ม 4 บรรทัดนี้เข้าไป ⭐️
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
                    }
                } else {
                    Button("ต่อคิว") {
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
            checkIfJoined()
            appState.startListening(to: activity)
        }
        .onDisappear {
            appState.stopListening(to: activity)
        }
    }

    func joinQueue() {
        guard let student = appState.currentUser else { return }
        let newItem = QueueItem(
            id: UUID(), //Provide a unique ID here
            studentId: student.id,
            studentName: student.name,
            number: activity.nextQueueNumber,
            status: nil
        )
        appState.addQueueItem(activity: activity, queueItem: newItem)
        isJoined = true
    }

    func leaveQueue() {
        guard let student = appState.currentUser else { return }
        if let myQueue = activity.queues.first(where: { $0.studentId == student.id }) {
            appState.updateQueueItemStatus(activity: activity, queueItem: myQueue, status: "ยกเลิกคิว")
            isJoined = false
        }
    }

    func checkIfJoined() {
        guard let studentId = appState.currentUser?.id else {
            isJoined = false
            return
        }
        isJoined = activity.queues.contains { $0.studentId == studentId }
    }
}

//#Preview {
//    let appState = AppState()
//    appState.activities = [
//        Activity(name: "กิจกรรมทดสอบ", queues: [
//            QueueItem(id: <#UUID#>, studentId: "654231024", studentName: "สมชาย", number: 1)
//        ]),
//        Activity(name: "กิจกรรมที่สอง", queues: [])
//    ]
//    appState.currentUser = (role: .student, name: "สมศรี", id: "654231024")
//
//    StudentQueueJoinView(activityIndex: 0)
//        .environmentObject(appState)
//}
