//
//  StudentQueueJoinView.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

struct StudentQueueJoinView: View {
    @EnvironmentObject var appState: AppState
    let activityIndex: Int

    @State private var isJoined = false

    var activity: Activity {
        appState.activities[activityIndex]
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("กิจกรรม: \(activity.name)")
                .font(.title2)
                .fontWeight(.bold)

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

                            // ✅ 2. คุณอยู่คิวที่ #X
                            Text("คุณอยู่คิวที่ #\(myPosition)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            } else {
                Button("ต่อคิว") {
                    guard let student = appState.currentUser else { return }
                    let newItem = QueueItem(
                        studentId: student.id,
                        studentName: student.name,
                        number: activity.nextQueueNumber
                    )
                    appState.activities[activityIndex].queues.append(newItem)
                    appState.activities[activityIndex].nextQueueNumber += 1
                    isJoined = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Spacer()
        }
        .onAppear {
            if let studentId = appState.currentUser?.id {
                isJoined = activity.queues.contains { $0.studentId == studentId }
            }
        }
        .navigationTitle("ต่อคิว")
    }
}
