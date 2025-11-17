import SwiftUI

struct StudentActivityListView: View {
    @EnvironmentObject var appState: AppState

    // SWU Colors (From LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    var body: some View {
        // <<< ลบ NavigationView ที่ครอบ View ทั้งหมดออก >>>
        // NavigationView { // เดิม
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
                    // Top Bar
                    HStack {
                        // Profile Icon and Greeting
                        HStack {
                            Image(systemName: "person.circle.fill") // Use a profile icon
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("สวัสดี, \(appState.currentUser?.name ?? "นักศึกษา")")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }

                        Spacer()

                        // Logout Button (SF Symbol)
                        Button(action: {
                            print("StudentActivityListView: Logout button pressed.")
                            appState.logout()
                        }) {
                            Image(systemName: "arrow.right.square.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(swuRed) // Use SWU red for button
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(.white.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)

                    // Activities List
                    if appState.activities.isEmpty {
                        // "No Activities" Message
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            Text("ยังไม่มีกิจกรรมให้เข้าร่วม")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Center the message
                    } else {
                        // Activities List (using ScrollView and LazyVStack)
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(appState.activities.indices, id: \.self) { index in
                                    let activity = appState.activities[index]
                                    NavigationLink(
                                        destination: StudentQueueJoinView(activity: activity).environmentObject(appState)
                                    ) {
                                        HStack {
                                            Text(activity.name)
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.black) // Adjusted color
                                            Spacer()
                                            // ✅ แสดงจำนวนคิว + สีตามสถานะ
                                            QueueCountBadge(activity: activity)
                                        }
                                        .padding()
                                        .background(.white)
                                        .cornerRadius(12)
                                        .shadow(radius: 3)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Remove button styling
                                }
                            }
                            .padding()
                        }
                    }

                    Spacer() // Push content to the top
                }
            }
            .navigationTitle("กิจกรรม")
            .navigationBarTitleDisplayMode(.inline)
        // } // ลบวงเล็บปิดของ NavigationView
        .onAppear {
            appState.loadActivities()
            print("StudentActivityListView ปรากฏขึ้น. isLoggedIn: \(appState.isLoggedIn)")
        }
    }
}

// ✅ สร้าง View แยกสำหรับแสดง Badge จำนวนคิว
struct QueueCountBadge: View {
    @ObservedObject var activity: Activity
    
    var body: some View {
        Text("(\(activity.queues.count) คิว)")
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(queueColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var queueColor: Color {
        switch activity.queues.count {
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

#Preview{
    StudentActivityListView()
        .environmentObject(AppState())
}
