//
//  Models.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import Foundation

enum UserRole {
    case admin
    case student
}

struct Activity: Identifiable, Equatable, Codable {
    let id = UUID()
    var name: String
    var queues: [QueueItem] = []
    var nextQueueNumber = 1
}

struct QueueItem: Identifiable, Equatable, Codable {
    let id = UUID()
    let studentId: String
    let studentName: String
    let number: Int
}
