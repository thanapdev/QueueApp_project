import SwiftUI

struct BookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState // 👈 รับ "สมอง" มาจาก AppState
    
    // Layout สำหรับ Grid
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    // สี SWU (จากโค้ดเดิมของคุณ)
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    
    // MARK: - Body
    var body: some View {
        VStack {
            NavigationStack {
                ZStack {
                    
                    // MARK: - 1. UI Layout (Background & Grid)
                    // Background
                                 LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                                     .edgesIgnoringSafeArea(.all)

                                 // Shape Background
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
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(libraryServices) { service in
                                    // ⭐️ ส่ง AppState ไปยัง DetailView ด้วย
                                    NavigationLink(destination: BookingDetailView(service: service).environmentObject(appState)) {
                                        ServiceCardView(service: service)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 10)
                    }
                }
                .navigationTitle("Library Services")
                .navigationBarTitleDisplayMode(.large)
            }
            
            // MARK: - 2. Active Booking Banner
            // ⭐️ UI ส่วนนี้จะแสดง/ซ่อน อัตโนมัติ อิงจาก AppState
            if appState.hasActiveBooking {
                MyBookingBannerView()
                    .environmentObject(appState) // 👈 ส่ง AppState ไปให้ Banner
            }
        }
    }
}
