//
//  Models.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import Foundation

enum UserRole {
    case organization
    case student
}

struct Activity: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var queues: [QueueItem] = []
    var nextQueueNumber = 1
}

struct QueueItem: Identifiable, Equatable {
    let id = UUID()
    let studentId: String
    let studentName: String
    let number: Int
}
