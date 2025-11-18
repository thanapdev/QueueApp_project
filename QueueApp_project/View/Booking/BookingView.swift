//
//  BookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import SwiftUI

struct BookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    // Grid Layout
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ZStack {
            // 1. Background
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // --- Header ---
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 5) {
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
                    
                    Text("Library Services")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    Text("จองห้องและบริการต่างๆ ของห้องสมุด")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                
                // --- Content Area ---
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // 1. Services Grid
                            Text("Available Services")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color.Theme.textDark)
                                .padding(.top, 24)
                            
                            LazyVGrid(columns: gridColumns, spacing: 15) {
                                ForEach(libraryServices) { service in
                                    NavigationLink(destination: BookingDetailView(service: service).environmentObject(appState)) {
                                        BookingMenuCard(service: service)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // -------------------------------------------------
                            // 2. ✅ NEW: FOOTER SECTION (เติมตรงนี้ให้เต็ม)
                            // -------------------------------------------------
                            VStack(spacing: 20) {
                                Divider()
                                    .padding(.vertical, 10)
                                
                                // Info Rows
                                HStack(alignment: .top, spacing: 30) {
                                    // Time
                                    VStack(spacing: 8) {
                                        Image(systemName: "clock.badge.checkmark.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                        Text("Open Daily")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("08:00 - 20:00")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.Theme.textDark)
                                    }
                                    
                                    // Location
                                    VStack(spacing: 8) {
                                        Image(systemName: "map.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                        Text("Location")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("Central Library, 4th FL")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color.Theme.textDark)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                
                                // Rules / Help Button
                                Button(action: {
                                    // Action สำหรับดูกฎระเบียบ (ถ้ามี)
                                }) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                        Text("Rules & Regulations")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(20)
                                }
                                
                                // Decorative Text
                                Text("Powered by SWU Library System")
                                    .font(.caption2)
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .padding(.top, 10)
                            }
                            .padding(.top, 20)
                            // -------------------------------------------------
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120) // เว้นที่ให้ Banner เยอะหน่อย
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // --- Active Banner ---
            if appState.hasActiveBooking {
                VStack {
                    Spacer()
                    MyBookingBannerView()
                        .environmentObject(appState)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - BookingMenuCard
struct BookingMenuCard: View {
    let service: LibraryService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Circle()
                    .fill(service.themeColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: service.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(service.themeColor)
            }
            .padding(.top, 16)
            .padding(.leading, 16)
            .padding(.bottom, 12)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.Theme.textDark)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                Text("Tap to book")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Preview
struct BookingView_Previews: PreviewProvider {
    static var previews: some View {
        BookingView()
            .environmentObject(AppState())
    }
}
