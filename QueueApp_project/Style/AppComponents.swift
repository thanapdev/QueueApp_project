//
//  AppComponents.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// ==========================================
// MARK: - BACKGROUND SYSTEM (คงเดิม)
// ==========================================
enum BackgroundStyle {
    case style1, style2, style3, random
}

struct DynamicBackground: View {
    var style: BackgroundStyle = .style1
    var selectedStyle: BackgroundStyle {
        if style == .random {
            let styles: [BackgroundStyle] = [.style1, .style2, .style3]
            return styles.randomElement() ?? .style1
        }
        return style
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.Theme.bgGradientStart, Color.Theme.bgGradientEnd]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            switch selectedStyle {
            case .style1: BackgroundVariant1()
            case .style2: BackgroundVariant2()
            case .style3: BackgroundVariant3()
            default: BackgroundVariant1()
            }
        }
    }
}

// --- BACKGROUND VARIANTS ---
struct BackgroundVariant1: View {
    var body: some View {
        GeometryReader { geometry in
            Circle().fill(Color.white.opacity(0.1)).frame(width: 300, height: 300).position(x: geometry.size.width, y: 0)
            Circle().stroke(Color.white.opacity(0.3), lineWidth: 2).frame(width: 100, height: 100).position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.1)
            SquiggleShape().stroke(Color.Theme.secondary, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)).frame(width: 100, height: 50).position(x: 60, y: geometry.size.height - 100).rotationEffect(.degrees(-20))
        }
    }
}
struct BackgroundVariant2: View {
    var body: some View {
        GeometryReader { geometry in
            Circle().fill(Color.white.opacity(0.05)).frame(width: 400, height: 400).position(x: geometry.size.width / 2, y: geometry.size.height * 0.3)
            Circle().fill(Color.Theme.secondary.opacity(0.8)).frame(width: 120, height: 120).position(x: 0, y: geometry.size.height * 0.1).offset(x: -30)
        }
    }
}
struct BackgroundVariant3: View {
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: "sparkle").font(.system(size: 40)).foregroundColor(Color.white.opacity(0.4)).position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.35)
        }
    }
}

// MARK: - HELPER SHAPES & BUTTONS
struct SquiggleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height / 2))
        path.addCurve(to: CGPoint(x: rect.width / 2, y: rect.height / 2), control1: CGPoint(x: rect.width / 4, y: 0), control2: CGPoint(x: rect.width / 4, y: rect.height))
        path.addCurve(to: CGPoint(x: rect.width, y: rect.height / 2), control1: CGPoint(x: rect.width * 0.75, y: 0), control2: CGPoint(x: rect.width * 0.75, y: rect.height))
        return path
    }
}

struct BluePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.Theme.primary)
            .clipShape(Capsule())
            .shadow(color: Color.Theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// ✅ NEW: White Pill Button Style (ใช้สำหรับปุ่มรอง หรือปุ่มที่มีพื้นหลังสีเข้ม)
struct WhitePillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color.Theme.primary) // ตัวหนังสือสีฟ้า
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white) // พื้นหลังขาว
            .clipShape(Capsule())
            .overlay(
                // เพิ่มขอบสีฟ้าจางๆ ให้ปุ่ม
                Capsule()
                    .stroke(Color.Theme.primary.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// ==========================================
// MARK: - SHARED ACTIVITY CARD (แก้ไขให้ตรงกับ AppState)
// ==========================================

struct ActivityCardView: View {
    @ObservedObject var activity: Activity
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon Box
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.Theme.primary.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "star.bubble.fill")
                    .font(.title2)
                    .foregroundColor(Color.Theme.primary)
            }
            
            // Text Info
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Theme.textDark)
                    .lineLimit(1)
                
                Text("แตะเพื่อดูรายละเอียด")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Queue Badge
            QueueCountBadge(activity: activity)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct QueueCountBadge: View {
    @ObservedObject var activity: Activity
    
    var body: some View {
        VStack(spacing: 2) {
            // ⭐️ แก้ไข: ใช้ queueCount (Int) แทน queues.count (Array)
            // เพราะหน้า List โหลดมาแค่ queueCount ไม่ได้โหลด Array
            Text("\(activity.queueCount)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(statusColor)
            
            Text("คิว")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(width: 50, height: 50)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        // ใช้ queueCount เช็คสี
        switch activity.queueCount {
        case 0: return Color.green
        case 1...5: return Color.orange
        default: return Color.red
        }
    }
}
