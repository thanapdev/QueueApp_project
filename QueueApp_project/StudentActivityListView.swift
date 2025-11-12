//
//  StudentActivityListView.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

struct StudentActivityListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            HStack {
                Text("สวัสดี, \(appState.currentUser?.name ?? "นักศึกษา")")
                    .font(.headline)
                Spacer()
                Button("ออกจากระบบ") {
                    appState.logout()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if appState.activities.isEmpty {
                Text("ยังไม่มีกิจกรรมให้เข้าร่วม")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(appState.activities.indices, id: \.self) { index in
                    let activity = appState.activities[index]
                    NavigationLink(
                        destination: StudentQueueJoinView(activityIndex: index).environmentObject(appState)
                    ) {
                        HStack {
                            Text(activity.name)
                                .font(.body)
                            
                            Spacer()
                            
                            // ✅ แสดงจำนวนคิว + สีตามสถานะ
                            QueueCountBadge(count: activity.queues.count)
                        }
                    }
                }
            }
        }
        .navigationTitle("กิจกรรม")
    }
}

// ✅ สร้าง View แยกสำหรับแสดง Badge จำนวนคิว
struct QueueCountBadge: View {
    let count: Int
    
    var body: some View {
        Text("(\(count) คิว)")
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(queueColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var queueColor: Color {
        switch count {
        case 0:
            return Color.green.opacity(0.7)
        case 1...3:
            return Color.yellow.opacity(0.7)
        case 4...7:
            return Color.orange.opacity(0.7)
        default:
            return Color.red.opacity(0.7)
        }
    }
}
