import SwiftUI

struct ServiceView: View {
    @EnvironmentObject var appState: AppState

    @State private var showActivityEvent = false
    @State private var showBookingSpace = false

    // SWU Colors (จาก LoginView.swift)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    var body: some View {
        ZStack {
            // Background (Gradient จาก LoginView.swift)
            LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            // Shape Background (Circles จาก LoginView.swift)
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

            VStack(spacing: 40) {
                Spacer()

                Text("เลือกบริการ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 20)

                Button(action: {
                    print("ServiceView: 'Activity / Event' button pressed. Setting isBrowsingAsGuest to true.")
                    withAnimation(.easeInOut(duration: 0.3)) { // <<< เพิ่ม withAnimation ตรงนี้
                        appState.isBrowsingAsGuest = true
                    }
                }) {
                    ServiceCard(title: "Activity / Event", description: "ดูกิจกรรมและอีเว้นท์", backgroundColor: swuRed)
                }
                .buttonStyle(.plain)

                Button(action: {
                    showBookingSpace = true
                }) {
                    ServiceCard(title: "Booking Space", description: "จองพื้นที่", backgroundColor: swuRed)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LoginView().environmentObject(appState)) {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                }
            }
        
            NavigationLink(destination: BookingView().environmentObject(appState), isActive: $showBookingSpace) {
                EmptyView()
            }
        }
        .onAppear {
            print("ServiceView ปรากฏขึ้น. isLoggedIn: \(appState.isLoggedIn), isBrowsingAsGuest: \(appState.isBrowsingAsGuest)")
        }
    }
}

// ServiceCard struct ไม่มีการเปลี่ยนแปลง
struct ServiceCard: View {
    let title: String
    let description: String
    let backgroundColor: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Text(description)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 5)
        .contentShape(Rectangle()) // ทำให้กดได้ทั้งการ์ด
    }
}

#Preview {
    ServiceView().environmentObject(AppState())
}
