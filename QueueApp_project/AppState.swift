import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: (role: UserRole, name: String, id: String)?
    @Published var activities: [Activity] = []
    
    private let db = Firestore.firestore()

    enum UserRole {
        case organization
        case student
    }
    
    init() {
        // Load activities from Firestore when AppState is initialized
        loadActivities()
    }
    
    func logout() {
        isLoggedIn = false
        currentUser = nil
    }
    
    // Function to add an activity to Firestore
    func addActivity(name: String) {
        let newActivity = Activity(name: name)
        activities.append(newActivity)
        
        // Add the activity to Firestore
        db.collection("activities").document(newActivity.id.uuidString).setData([
            "name": newActivity.name
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
        db.collection("activities").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.activities = querySnapshot!.documents.compactMap { document in
                    let data = document.data()
                    let name = data["name"] as? String ?? ""
                    
                    // Convert document ID to UUID
                    if let idString = document.documentID as String?, let id = UUID(uuidString: idString) {
                        return Activity(name: name)
                    } else {
                        return nil
                    }
                }
            }
        }
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
                             self.currentUser = (role: role, name: name, id: studentID)
                             self.isLoggedIn = true
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
                let role: UserRole = roleString == "admin" ? .organization : .student
                
                // 2. Use the email and password to sign in with Firebase Authentication
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        print("Error signing in: \(error.localizedDescription)")
                        completion(false, "Invalid Student ID or Password.")
                        return
                    } else {
                        // Sign in successful
                        self.currentUser = (role: role, name: name, id: studentID)
                        self.isLoggedIn = true
                        completion(true, nil)
                    }
                }
            }
    }
}
