//
//  CampusMapView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import SwiftUI
import MapKit

// MARK: - 1. Data Model
// โมเดลข้อมูลสำหรับจุดปักหมุดบนแผนที่ (Location Pin)
struct CampusLocation: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let type: LocationType
    
    // ประเภทของสถานที่ เพื่อกำหนดไอคอนและสี
    enum LocationType {
        case building, admin, food, facility, sport, medical, school, shop
        
        var icon: String {
            switch self {
            case .building: return "building.2.fill"
            case .admin: return "building.columns.fill"
            case .food: return "fork.knife"
            case .facility: return "books.vertical.fill"
            case .sport: return "figure.run"
            case .medical: return "cross.case.fill"
            case .school: return "graduationcap.fill"
            case .shop: return "basket.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .building: return .blue
            case .admin: return .purple
            case .food: return .orange
            case .facility: return .brown
            case .sport: return .green
            case .medical: return .red
            case .school: return .indigo
            case .shop: return .pink
            }
        }
    }
}

// MARK: - 2. Main Map View
// หน้าแสดงแผนที่วิทยาเขต (Campus Map)
struct CampusMapView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // พิกัดเริ่มต้น: ปรับ Center ให้เห็นภาพรวมตั้งแต่ COSCI ถึงสนามบอล
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 13.745500, longitude: 100.565000),
        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
    )
    
    @State private var selectedLocation: CampusLocation?
    
    // ข้อมูลจุดปักหมุด (เพิ่มข้อมูลใหม่แล้ว)
    let locations: [CampusLocation] = [
        CampusLocation(
            name: "วิทยาลัยนวัตกรรมสื่อสารสังคม (COSCI)",
            description: "College of Social Communication Innovation",
            coordinate: CLLocationCoordinate2D(latitude: 13.7472026, longitude: 100.5654315),
            type: .building
        ),
        CampusLocation(
            name: "โรงอาหาร (Canteen)",
            description: "ศูนย์อาหารหลัก มศว",
            coordinate: CLLocationCoordinate2D(latitude: 13.7438853, longitude: 100.5660696),
            type: .food
        ),
        CampusLocation(
            name: "7-11 ตึกไข่ดาว",
            description: "ร้านสะดวกซื้อ ใต้อาคารเรียนรวม",
            coordinate: CLLocationCoordinate2D(latitude: 13.7461563, longitude: 100.5648039),
            type: .shop
        ),
        CampusLocation(
            name: "7-11 โรงอาหาร",
            description: "ร้านสะดวกซื้อ ข้างโรงอาหาร",
            coordinate: CLLocationCoordinate2D(latitude: 13.7437267, longitude: 100.5659240),
            type: .shop
        ),
        CampusLocation(
            name: "สำนักหอสมุดกลาง",
            description: "Central Library",
            coordinate: CLLocationCoordinate2D(latitude: 13.7457309, longitude: 100.5656039),
            type: .facility
        ),
        CampusLocation(
            name: "สนามกีฬา มศว",
            description: "สนามฟุตบอลและลู่วิ่ง",
            coordinate: CLLocationCoordinate2D(latitude: 13.7449021, longitude: 100.5646879),
            type: .sport
        ),
        CampusLocation(
            name: "SWU NIGHT MARKET",
            description: "ตลาดนัด มศว",
            coordinate: CLLocationCoordinate2D(latitude: 13.7448783, longitude: 100.5634397),
            type: .shop
        )
    ]
    
    var body: some View {
        ZStack {
            // 1. MAP LAYER
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Button(action: {
                        withAnimation {
                            selectedLocation = location
                            region.center = location.coordinate // เลื่อนแผนที่ไปหาจุดที่เลือก
                        }
                    }) {
                        VStack(spacing: 0) {
                            Image(systemName: location.type.icon)
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(location.type.color)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                            
                            Image(systemName: "triangle.fill")
                                .font(.caption2)
                                .foregroundColor(location.type.color)
                                .offset(y: -4)
                        }
                        .scaleEffect(selectedLocation?.id == location.id ? 1.3 : 1.0)
                        .animation(.spring(), value: selectedLocation?.id)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // 2. UI OVERLAY
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                    }
                    Spacer()
                    
                    // Title Badge
                    Text("Campus Map")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 3. DETAIL CARD (Popup)
                // แสดงรายละเอียดสถานที่เมื่อกดเลือก
                if let location = selectedLocation {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: location.type.icon)
                                .font(.title)
                                .foregroundColor(location.type.color)
                                .frame(width: 50, height: 50)
                                .background(location.type.color.opacity(0.1))
                                .cornerRadius(12)
                            
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .lineLimit(2)
                                
                                Text(location.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            Spacer()
                            
                            Button(action: {
                                withAnimation { selectedLocation = nil }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// Preview
struct CampusMapView_Previews: PreviewProvider {
    static var previews: some View {
        CampusMapView()
    }
}
