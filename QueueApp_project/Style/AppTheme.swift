//
//  AppTheme.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol
//

import SwiftUI

// MARK: - App Theme Colors
// รวมสีที่ใช้บ่อยในแอปไว้ที่เดียว เพื่อให้เรียกใช้ง่ายและคุมโทนสีได้สะดวก
extension Color {
    struct Theme {
        // สีหลัก: สีฟ้าสดแบบท้องฟ้า (ใช้กับปุ่ม, Header)
        static let primary = Color(red: 55/255, green: 165/255, blue: 250/255)
        
        // สีรอง: สีส้มพีชเข้ม (ใช้ตัดขอบ, หรือจุดที่ต้องการเน้น)
        static let secondary = Color(red: 255/255, green: 185/255, blue: 165/255)
        
        // สีขาวมาตรฐาน
        static let white = Color.white
        
        // สีดำเข้มสำหรับ Text (ไม่ดำสนิท เพื่อให้อ่านสบายตา)
        static let textDark = Color(red: 30/255, green: 30/255, blue: 30/255)
        
        // Gradient พื้นหลัง (ไล่เฉดจากฟ้าสด -> ฟ้าเข้ม)
        static let bgGradientStart = Color(red: 80/255, green: 190/255, blue: 255/255)
        static let bgGradientEnd = Color(red: 40/255, green: 140/255, blue: 240/255)
    }
}
