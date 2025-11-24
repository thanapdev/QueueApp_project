//
//  CreatePostView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//

import SwiftUI

// MARK: - Create Post View
// หน้าสร้างโพสต์ใหม่
// ทำหน้าที่:
// 1. รับข้อความโพสต์จากผู้ใช้
// 2. เลือกหมวดหมู่ (ทั่วไป, ถาม-ตอบ, อื่นๆ)
// 3. เลือกโหมด Anonymous หรือไม่
// 4. ส่งโพสต์ไป Firestore
struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode   // ใช้สำหรับปิดหน้านี้
    @ObservedObject var viewModel: SocialViewModel          // ViewModel หลัก
    
    @State private var contentText: String = ""             // ข้อความโพสต์
    @State private var selectedCategory: String = "พูดคุยทั่วไป"  // หมวดหมู่ที่เลือก
    @State private var isAnonymous: Bool = false            // โหมด Anonymous
    
    let characterLimit = 500                                // จำกัดจำนวนตัวอักษร
    let categories = ["พูดคุยทั่วไป", "ถาม-ตอบ", "รีวิววิชา/อาจารย์", "ของหาย", "หาเพื่อน", "ตลาดนัด"] // รายการหมวดหมู่ทั้งหมด
    
    // Logic การโพสต์ (PRESERVED)
    private func submitPost() {
        if !contentText.isEmpty {
            viewModel.createPost(content: contentText, category: selectedCategory, isAnonymous: isAnonymous) { success in
                if success { presentationMode.wrappedValue.dismiss() }
                // ถ้ามี error message จาก ViewModel จะแสดงที่อื่น
            }
        }
    }
    
    var body: some View {
        NavigationStack { // ใช้ NavigationStack เพื่อจัดการ Toolbar ได้ดีขึ้น
            ZStack(alignment: .bottom) {
                // 1. Background
                DynamicBackground(style: .random)
                
                // 2. Content Scrollable
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // --- A. ส่วนเขียนข้อความ (Text Editor Card) ---
                        VStack(alignment: .leading, spacing: 5) {
                            Text("รายละเอียดโพสต์ (สูงสุด \(characterLimit) ตัวอักษร)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white) // สีขาวบนพื้นหลังกราฟิก
                                .padding(.leading, 8)
                            
                            // Text Editor Box
                            VStack(alignment: .leading) {
                                ZStack(alignment: .topLeading) {
                                    if contentText.isEmpty {
                                        Text("พิมพ์ข้อความ เนื้อหา หรือคำถามที่นี่...")
                                            .foregroundColor(Color(UIColor.placeholderText))
                                            .padding(.top, 10)
                                            .padding(.horizontal, 8)
                                    }
                                    
                                    TextEditor(text: $contentText)
                                        .onChange(of: contentText) { newValue in
                                            if newValue.count > characterLimit {
                                                contentText = String(newValue.prefix(characterLimit))
                                            }
                                        }
                                        .frame(height: 180)
                                        .padding(5)
                                }
                                
                                // Character Count
                                HStack {
                                    Spacer()
                                    Text("\(contentText.count) / \(characterLimit)")
                                        .font(.caption)
                                        .foregroundColor(contentText.count > characterLimit - 50 ? .red : .gray)
                                }
                                .padding(.horizontal, 10)
                                .padding(.bottom, 5)
                            }
                            .background(Color.Theme.white)
                            .cornerRadius(15)
                            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            
                        }
                        .padding(.horizontal, 20)
                        
                        // --- B. ส่วนตัวเลือก (Options Card) ---
                        VStack(spacing: 0) {
                            // Picker หมวดหมู่
                            HStack {
                                Text("หมวดหมู่").fontWeight(.medium).foregroundColor(Color.Theme.textDark)
                                Spacer()
                                Picker("หมวดหมู่", selection: $selectedCategory) {
                                    ForEach(categories, id: \.self) { category in
                                        Text(category).tag(category)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .foregroundColor(Color.Theme.primary)
                            }
                            .padding()
                            
                            Divider().padding(.leading)
                            
                            // Toggle ไม่ระบุตัวตน
                            Toggle(isOn: $isAnonymous) {
                                HStack(spacing: 10) {
                                    Image(systemName: isAnonymous ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(isAnonymous ? .purple : .gray)
                                        .frame(width: 25)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("โพสต์แบบไม่ระบุชื่อ").fontWeight(.medium).foregroundColor(Color.Theme.textDark)
                                        Text("ชื่อของคุณจะแสดงเป็น 'นิสิตท่านหนึ่ง'").font(.caption).foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(Color.Theme.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        
                        // Spacer to push content up and give room for button
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 20) // ระยะห่างจาก Navigation Bar
                }
                
                // --- C. ปุ่มโพสต์ขนาดใหญ่ (Floating Button) ---
                VStack {
                    Button(action: submitPost) {
                        Text("โพสต์กระทู้นี้")
                            .font(.headline).fontWeight(.bold).foregroundColor(.blue)
                    }
                    // ✅ ใช้ BluePillButtonStyle ที่เป็นปุ่มหลักของเรา
                    .buttonStyle(WhitePillButtonStyle())
                    .frame(width: UIScreen.main.bounds.width - 40) // กำหนดความกว้างตามหน้าจอ
                    .shadow(color: Color.Theme.primary.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 20)
                .disabled(contentText.isEmpty)
            }
            .navigationTitle("สร้างกระทู้ใหม่")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ยกเลิก") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.red)
                }
            }
        }
    }
}
