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
        
        // สีพื้นหลัง Card/Container: ขาว ใน Light Mode -> เทาเข้ม ใน Dark Mode
        static let white = Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1) : UIColor.white
        })
        
        // สี Text: ดำเข้ม ใน Light Mode -> ขาว ใน Dark Mode
        static let textDark = Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor.white : UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
        })
        
        // Gradient พื้นหลัง (ไล่เฉด)
        static let bgGradientStart = Color(UIColor { trait in
            // Dark Mode: ฟ้าเข้มเกือบดำ / Light Mode: ฟ้าสดใส
            return trait.userInterfaceStyle == .dark ? UIColor(red: 10/255, green: 20/255, blue: 40/255, alpha: 1) : UIColor(red: 80/255, green: 190/255, blue: 255/255, alpha: 1)
        })
        
        static let bgGradientEnd = Color(UIColor { trait in
            // Dark Mode: ดำ / Light Mode: ฟ้าเข้มขึ้น
            return trait.userInterfaceStyle == .dark ? UIColor(red: 5/255, green: 10/255, blue: 20/255, alpha: 1) : UIColor(red: 40/255, green: 140/255, blue: 240/255, alpha: 1)
        })
    }
}

