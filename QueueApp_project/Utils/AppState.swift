import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: (role: UserRole, name: String, id: String)?
    @Published var activities: [Activity] = []
    @Published var isBrowsingAsGuest = false

    private let db = Firestore.firestore()
    private var activityListeners: [UUID: ListenerRegistration] = [:]

    enum UserRole {
        case admin
        case student
    }

    init() {
        // Load activities from Firestore when AppState is initialized
        loadActivities()
    }

    func logout() {
        withAnimation(.easeInOut(duration: 0.3)) { // <<< เพิ่ม withAnimation ตรงนี้
            isLoggedIn = false
            currentUser = nil
            isBrowsingAsGuest = false // 👈 2. เพิ่มบรรทัดนี้ (สำคัญมาก)
        }
        // Optional: Sign out from Firebase Authentication
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // Function to add an activity to Firestore
    func addActivity(name: String) {
        let newActivity = Activity(name: name)
        activities.append(newActivity)

        // Add the activity to Firestore
        db.collection("activities").document(newActivity.id.uuidString).setData([
            "name": newActivity.name,
            "nextQueueNumber": newActivity.nextQueueNumber, // Save nextQueueNumber
            "currentQueueNumber": newActivity.currentQueueNumber, // Save currentQueueNumber
            "queueCount": newActivity.queueCount // Save queueCount
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(newActivity.id.uuidString)")
            }
        }
    }

    // Function to load activities from Firestore
    func loadActivities() {
        db.collection("activities").getDocuments() { [weak self] (querySnapshot, err) in
            guard let self = self else { return }
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.activities = querySnapshot!.documents.compactMap { document in
                    let data = document.data()
                    let name = data["name"] as? String ?? ""
                    let nextQueueNumber = data["nextQueueNumber"] as? Int ?? 1 // Load nextQueueNumber
                    let currentQueueNumber = data["currentQueueNumber"] as? Int // Load currentQueueNumber
                    let queueCount = data["queueCount"] as? Int ?? 0 // Load queueCount


                    // Convert document ID to UUID
                    if let idString = document.documentID as String?, let id = UUID(uuidString: idString) {
                        let activity = Activity(id: id, name: name, nextQueueNumber: nextQueueNumber, currentQueueNumber: currentQueueNumber, queueCount: queueCount)
                        self.loadQueueItems(activity: activity) { queueItems in
                            activity.queues = queueItems
                        }
                        return activity// Pass ID when loading data
                    } else {
                        return nil
                    }
                }
            }
        }
    }

    // Function to update an activity in Firestore
    func updateActivity(activity: Activity) {
        db.collection("activities").document(activity.id.uuidString).setData([
            "name": activity.name,
            "nextQueueNumber": activity.nextQueueNumber, // Update nextQueueNumber
            "currentQueueNumber": activity.currentQueueNumber, // Update currentQueueNumber
            "queueCount": activity.queueCount // Update queueCount
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document updated with ID: \(activity.id.uuidString)")
            }
        }
    }

    // Function to delete an activity from Firestore
    func deleteActivity(activity: Activity) {
        db.collection("activities").document(activity.id.uuidString).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
    }

    // Function to add a queue item to Firestore
    func addQueueItem(activity: Activity, queueItem: QueueItem) {
        db.collection("activities")
            .document(activity.id.uuidString)
            .collection("queues")
            .document(queueItem.id.uuidString)
            .setData([
                "studentName": queueItem.studentName,
                "number": queueItem.number,
                "studentId": queueItem.studentId,
                "status": queueItem.status // Save status
            ]) { err in
                if let err = err {
                    print("Error adding queue item: \(err)")
                } else {
                    print("Queue item added for activity \(activity.name)")
                    // Update queue count in Activity
                    self.updateQueueCount(activity: activity, increment: true)
                    self.loadActivities()
                }
            }
    }

    // Function to load queue items from Firestore
    func loadQueueItems(activity: Activity, completion: @escaping ([QueueItem]) -> Void) {
        db.collection("activities")
            .document(activity.id.uuidString)
            .collection("queues")
            .order(by: "number") // Add this line to order by queue number
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting queue items: \(err)")
                    completion([])
                } else {
                    let queueItems = querySnapshot!.documents.compactMap { document in
                        let data = document.data()
                        let studentName = data["studentName"] as? String ?? ""
                        let number = data["number"] as? Int ?? 0
                        let studentId = data["studentId"] as? String ?? ""
                        let status = data["status"] as? String // Load status
                        if let idString = document.documentID as String?, let id = UUID(uuidString: idString) {
                            return QueueItem(id: id, studentId: studentId, studentName: studentName, number: number, status: status)
                        } else {
                            return nil
                        }
                    }.filter { item in
                        item.status == nil // Keep only items without a status (nil status)
                    }
                    completion(queueItems)
                }
            }
    }


    // Function to update queue item status in Firestore
    func updateQueueItemStatus(activity: Activity, queueItem: QueueItem, status: String) {
        db.collection("activities")
            .document(activity.id.uuidString)
            .collection("queues")
            .document(queueItem.id.uuidString)
            .updateData([
                "status": status
            ]) { err in
                if let err = err {
                    print("Error updating queue item status: \(err)")
                } else {
                    print("Queue item status updated for \(queueItem.studentName)")
                    // Update current queue number in Activity when status is updated
                    self.updateCurrentQueueNumber(activity: activity, queueItem: queueItem)
                    self.loadActivities()
                }
            }
    }

    // Function to delete a queue item from Firestore (we will not use this anymore)
    func deleteQueueItem(activity: Activity, queueItem: QueueItem) {
           // No longer deleting, just updating status
       }

    // Function to register a new user with Firebase Authentication and store additional user data in Firestore
    func register(name: String, studentID: String, email: String, password: String, role: UserRole, completion: @escaping (Bool, String?) -> Void) {
        // Check if studentID has 11 digits
        guard studentID.count == 11, studentID.allSatisfy({ $0.isNumber }) else {
            completion(false, "รหัสนักศึกษาต้องมี 11 หลัก และเป็นตัวเลขเท่านั้น")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                // User registration successful
                if let user = authResult?.user {
                    // Store additional user data in Firestore
                    let userData: [String: Any] = [
                        "name": name,
                        "studentID": studentID,
                        "email": email,
                        "role": role == .student ? "student" : "admin" // Store "admin" for admin role
                    ]

                    self.db.collection("users").document(user.uid).setData(userData) { error in
                        if let error = error {
                            print("Error adding user data to Firestore: \(error.localizedDescription)")
                            completion(false, "Failed to save user data.")
                        } else {
                            print("User data saved to Firestore")
                            withAnimation(.easeInOut(duration: 0.3)) { // <<< เพิ่ม withAnimation ตรงนี้
                                self.currentUser = (role: role, name: name, id: studentID)
                                self.isLoggedIn = true
                                self.isBrowsingAsGuest = false // ตั้งค่าให้ไม่เป็น Guest เมื่อ Login สำเร็จ
                            }
                            completion(true, nil)
                        }
                    }
                } else {
                    completion(false, "Failed to retrieve user information.")
                }
            }
        }
    }

    func loginAsStudent(studentID: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // 1. Query Firestore to get the user's email based on studentID
        db.collection("users")
            .whereField("studentID", isEqualTo: studentID)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completion(false, "Failed to retrieve user data.")
                    return
                }

                guard let document = querySnapshot?.documents.first else {
                    print("Student ID not found")
                    completion(false, "Invalid Student ID or Password.")
                    return
                }

                let data = document.data()
                let email = data["email"] as? String ?? ""
                let name = data["name"] as? String ?? ""
                let roleString = data["role"] as? String ?? "student"
                let role: UserRole = roleString == "admin" ? .admin : .student

                // 2. Use the email and password to sign in with Firebase Authentication
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        print("Error signing in: \(error.localizedDescription)")
                        completion(false, "Invalid Student ID or Password.")
                        return
                    } else {
                        // Sign in successful
                        withAnimation(.easeInOut(duration: 0.3)) { // <<< เพิ่ม withAnimation ตรงนี้
                            self.currentUser = (role: role, name: name, id: studentID)
                            self.isLoggedIn = true
                            self.isBrowsingAsGuest = false // ตั้งค่าให้ไม่เป็น Guest เมื่อ Login สำเร็จ
                        }
                        completion(true, nil)
                    }
                }
            }
    }
    
    // Function to update current queue number in Activity
    func updateCurrentQueueNumber(activity: Activity, queueItem: QueueItem) {
        db.collection("activities")
            .document(activity.id.uuidString)
            .updateData([
                "currentQueueNumber": queueItem.number // Set currentQueueNumber to the called queue number
            ]) { err in
                if let err = err {
                    print("Error updating current queue number: \(err)")
                } else {
                    print("Current queue number updated for activity \(activity.name)")
                    activity.currentQueueNumber = queueItem.number
                }
            }
    }

    // Function to update queue count in Activity
    func updateQueueCount(activity: Activity, increment: Bool) {
        let change = increment ? 1 : -1
        let newCount = max(0, activity.queueCount + change) // Ensure count doesn't go below 0

        db.collection("activities")
            .document(activity.id.uuidString)
            .updateData([
                "queueCount": newCount
            ]) { err in
                if let err = err {
                    print("Error updating queue count: \(err)")
                } else {
                    print("Queue count updated for activity \(activity.name)")
                    activity.queueCount = newCount
                }
            }
    }

    // Function to start listening for queue item changes
    func startListening(to activity: Activity) {
           guard activityListeners[activity.id] == nil else { return }

           let listener = db.collection("activities")
               .document(activity.id.uuidString)
               .collection("queues")
               .addSnapshotListener { [weak self] querySnapshot, error in
                   guard let self = self else { return }
                   guard let documents = querySnapshot?.documents else {
                       print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                       return
                   }

                   let queueItems = documents.compactMap { document in
                       let data = document.data()
                       let studentName = data["studentName"] as? String ?? ""
                       let number = data["number"] as? Int ?? 0
                       let studentId = data["studentId"] as? String ?? ""
                       let status = data["status"] as? String // Load status
                       if let idString = document.documentID as String?, let id = UUID(uuidString: idString) {
                           return QueueItem(id: id, studentId: studentId, studentName: studentName, number: number, status: status)
                       } else {
                           return nil
                       }
                   }.filter { item in
                       item.status == nil // Keep only items without a status (nil status)
                   }

                   DispatchQueue.main.async {
                       activity.queues = queueItems
                   }
               }

           activityListeners[activity.id] = listener
       }

    // Function to stop listening for queue item changes
    func stopListening(to activity: Activity) {
        if let listener = activityListeners[activity.id] {
            listener.remove()
            activityListeners.removeValue(forKey: activity.id)
        }
    }
}
