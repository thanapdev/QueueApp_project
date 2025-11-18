//
//  AppTheme.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol
//

import SwiftUI

extension Color {
    struct Theme {
        // สีฟ้าสดแบบท้องฟ้า (ตามรูป)
        static let primary = Color(red: 55/255, green: 165/255, blue: 250/255)
        // สีส้มพีชเข้ม
        static let secondary = Color(red: 255/255, green: 185/255, blue: 165/255)
        // สีขาว
        static let white = Color.white
        // สีดำเข้มสำหรับ Text
        static let textDark = Color(red: 30/255, green: 30/255, blue: 30/255)
        
        // Gradient พื้นหลัง (ฟ้าสด -> ฟ้าเข้ม)
        static let bgGradientStart = Color(red: 80/255, green: 190/255, blue: 255/255)
        static let bgGradientEnd = Color(red: 40/255, green: 140/255, blue: 240/255)
    }
}
