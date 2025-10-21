import SwiftUI
import FamilyControls
import ManagedSettings
import Combine
@preconcurrency import AVFoundation
import UIKit
import UserNotifications
import DeviceActivity

// MARK: - Notification Manager
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var hasPermission = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
                if granted {
                    print("Notification permission granted")
                    self.setupNotificationCategories()
                } else if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func setupNotificationCategories() {
        // Create actions for notifications
        let kudosAction = UNNotificationAction(
            identifier: "KUDOS_ACTION",
            title: "Give Kudos 👏",
            options: [.foreground]
        )
        
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View Activity",
            options: [.foreground]
        )
        
        // Create categories
        let taskCompletedCategory = UNNotificationCategory(
            identifier: "TASK_COMPLETED",
            actions: [kudosAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        let friendRequestCategory = UNNotificationCategory(
            identifier: "FRIEND_REQUEST",
            actions: [
                UNNotificationAction(identifier: "ACCEPT_ACTION", title: "Accept ✓", options: [.foreground]),
                UNNotificationAction(identifier: "DECLINE_ACTION", title: "Decline ✗", options: [.destructive])
            ],
            intentIdentifiers: [],
            options: []
        )

        let taskAssignedCategory = UNNotificationCategory(
            identifier: "TASK_ASSIGNED",
            actions: [
                UNNotificationAction(identifier: "VIEW_TASK_ACTION", title: "View Task", options: [.foreground]),
                UNNotificationAction(identifier: "START_TASK_ACTION", title: "Start Now", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )

        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            taskCompletedCategory,
            friendRequestCategory,
            taskAssignedCategory
        ])
    }
    
    // MARK: - Send Notifications
    
    func sendFriendCompletedTaskNotification(friendName: String, taskTitle: String, xpEarned: Int, hasPhoto: Bool = false) {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(friendName) completed a task!"
        content.body = "\(taskTitle) • Earned \(xpEarned) XP"
        
        if hasPhoto {
            content.body += " 📸"
        }
        
        content.sound = .default
        content.categoryIdentifier = "TASK_COMPLETED"
        content.badge = 1
        
        // Add user info for handling
        content.userInfo = [
            "type": "task_completed",
            "friend": friendName,
            "task": taskTitle,
            "xp": xpEarned
        ]
        
        // Create trigger (immediate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // Add notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    func sendTaskAssignedNotification(childName: String, taskTitle: String, xpReward: Int) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Task Assigned! 🎯"
        content.body = "\(taskTitle) • Earn \(xpReward) minutes"

        // Use "complete" sound from Apple's sound library
        content.sound = UNNotificationSound(named: UNNotificationSoundName("complete.caf"))
        content.categoryIdentifier = "TASK_ASSIGNED"
        content.badge = 1

        // Add user info for handling
        content.userInfo = [
            "type": "task_assigned",
            "child": childName,
            "task": taskTitle,
            "xp": xpReward
        ]

        // Create trigger (immediate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        // Add notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending task assignment notification: \(error)")
            } else {
                print("✅ Task assignment notification sent")
            }
        }
    }

    func sendFriendRequestNotification(fromUser: String) {
        guard hasPermission else { return }

        let content = UNMutableNotificationContent()
        content.title = "New Friend Request!"
        content.body = "\(fromUser) wants to be your friend"
        content.sound = .default
        content.categoryIdentifier = "FRIEND_REQUEST"
        content.badge = 1

        content.userInfo = [
            "type": "friend_request",
            "from": fromUser
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
    
    func sendLocationShareNotification(friendName: String) {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(friendName) is sharing location"
        content.body = "Your friend is now sharing their location with you"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendMilestoneNotification(milestone: String, reward: Int) {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Milestone Achieved! 🎉"
        content.body = "\(milestone) • Earned \(reward) bonus XP"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendSessionReminderNotification(minutesRemaining: Int) {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Screen Time Ending Soon"
        content.body = "\(minutesRemaining) minutes remaining in your session"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendDailyGoalReminder() {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Reminder"
        content.body = "Complete a task to maintain your streak!"
        content.sound = .default
        
        // Schedule for 7 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 19
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "KUDOS_ACTION":
            if let friendName = userInfo["friend"] as? String {
                print("User gave kudos to \(friendName)")
                // Handle kudos action
            }
            
        case "ACCEPT_ACTION":
            if let fromUser = userInfo["from"] as? String {
                print("User accepted friend request from \(fromUser)")
                // Handle accept friend request
            }
            
        case "DECLINE_ACTION":
            if let fromUser = userInfo["from"] as? String {
                print("User declined friend request from \(fromUser)")
                // Handle decline friend request
            }
            
        case "VIEW_ACTION":
            print("User wants to view activity")
            // Handle view action
            
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Badge Management
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    func updateBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}

// MARK: - Data Models
struct User: Identifiable {
    let id = UUID()
    var username: String
    var profileImage: String?
    var xpBalance: Int
    var totalXPEarned: Int
    var credibilityScore: Double
    var friends: [String]
    var pendingFriendRequests: [String]
    var isParentallyManaged: Bool
    var parentId: String?
}

struct TaskItem: Identifiable {
    let id = UUID()
    var title: String
    var category: TaskCategory
    var xpReward: Int
    var estimatedMinutes: Int
    var isCustom: Bool
    var completed: Bool
    var completedAt: Date?
    var createdBy: String
    var isGroupTask: Bool
    var participants: [String]
    var verificationRequired: Bool
    var verificationPhoto: UIImage? // Back camera image
    var verificationPhotoFront: UIImage? // Front camera image
}

enum TaskCategory: String, CaseIterable, Codable {
    case exercise = "Exercise"
    case chores = "Chores"
    case study = "Study"
    case social = "Social"
    case creative = "Creative"
    case outdoor = "Outdoor"
    case health = "Health"
    case custom = "Custom"
}

struct FriendActivity: Identifiable {
    let id = UUID()
    let userId: String
    let username: String
    let activity: String
    let xpEarned: Int
    let timestamp: Date
    let kudos: Int
    let hasVerificationPhoto: Bool
    let verificationPhoto: UIImage?
}

// MARK: - Location Manager
// MARK: - Photo Storage Model
struct SavedPhoto: Codable, Identifiable {
    let id = UUID()
    let fileName: String  // Back camera image
    let frontFileName: String?  // Front camera image (optional for backwards compatibility)
    let timestamp: Date
    let taskTitle: String
    let taskId: UUID? // Associated task ID for proper photo-task binding

    // Initializer for backwards compatibility
    init(fileName: String, frontFileName: String? = nil, timestamp: Date, taskTitle: String, taskId: UUID?) {
        self.fileName = fileName
        self.frontFileName = frontFileName
        self.timestamp = timestamp
        self.taskTitle = taskTitle
        self.taskId = taskId
    }
}

struct SocialPost: Identifiable, Codable {
    let id = UUID()
    let userId: String
    let userName: String
    let userAvatar: String? // File name for avatar image
    let taskId: UUID
    var taskTitle: String  // Made mutable for editing
    let taskDescription: String?
    let completionTime: Date
    let xpEarned: Int
    let photoFileName: String?
    var likes: Int = 0
    var downvotes: Int = 0
    var comments: [SocialComment] = []
    var likedBy: [String] = [] // Array of user IDs who liked this post
    var downvotedBy: [String] = [] // Array of user IDs who downvoted this post

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: completionTime, relativeTo: Date())
    }
}

struct SocialComment: Identifiable, Codable {
    let id = UUID()
    let userId: String
    let userName: String
    let content: String
    let timestamp: Date
}

// MARK: - Enhanced Camera Manager
@available(iOS 10.0, *)
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage?
    @Published var frontCameraImage: UIImage?
    @Published var backCameraImage: UIImage?
    @Published var isShowingCamera = false
    @Published var cameraError: String?
    @Published var savedPhotos: [SavedPhoto] = []
    @Published var isCapturing = false
    @Published var cameraStatus: CameraStatus = .initializing

    enum CameraStatus: String {
        case initializing
        case ready
        case frontOnly
        case backOnly
        case failed
        case capturing
    }

    enum CapturePhase {
        case readyForBack
        case capturingBack
        case readyForFront
        case capturingFront
        case completed
    }

    @Published var currentCapturePhase: CapturePhase = .readyForBack

    // Enhanced dual camera system
    private var dualCaptureSession: AVCaptureSession?
    var frontCaptureSession: AVCaptureSession?
    var backCaptureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    private var frontInput: AVCaptureDeviceInput?
    private var backInput: AVCaptureDeviceInput?
    var frontPhotoOutput: AVCapturePhotoOutput?
    var backPhotoOutput: AVCapturePhotoOutput?

    // Capture synchronization
    private var captureCompletionHandler: ((UIImage?, UIImage?) -> Void)? // (backImage, frontImage)
    private var frontImageCaptured = false
    private var backImageCaptured = false
    private let captureQueue = DispatchQueue(label: "com.envive.camera.capture", qos: .userInitiated)

    // Check if running in simulator
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    override init() {
        super.init()
        loadSavedPhotos()
        setupDualCameraSystem()
    }

    // MARK: - Photo Storage Methods
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var photosDirectory: URL {
        documentsDirectory.appendingPathComponent("EnvivePhotos")
    }

    private var photosMetadataURL: URL {
        documentsDirectory.appendingPathComponent("savedPhotos.json")
    }

    private func createPhotosDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: photosDirectory.path) {
            try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }

    func savePhoto(_ image: UIImage, taskTitle: String, taskId: UUID? = nil, frontImage: UIImage? = nil) -> Bool {
        createPhotosDirectoryIfNeeded()

        let timestamp = Date().timeIntervalSince1970
        let backFileName = "photo_back_\(timestamp).jpg"
        let backFileURL = photosDirectory.appendingPathComponent(backFileName)

        guard let backImageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert back image to JPEG data")
            return false
        }

        do {
            // Save back image
            try backImageData.write(to: backFileURL)
            print("✅ Back photo saved: \(backFileName)")

            // Save front image if provided
            var frontFileName: String? = nil
            if let frontImage = frontImage {
                frontFileName = "photo_front_\(timestamp).jpg"
                let frontFileURL = photosDirectory.appendingPathComponent(frontFileName!)

                if let frontImageData = frontImage.jpegData(compressionQuality: 0.8) {
                    try frontImageData.write(to: frontFileURL)
                    print("✅ Front photo saved: \(frontFileName!)")
                } else {
                    print("⚠️ Failed to convert front image to JPEG data, saving without front image")
                    frontFileName = nil
                }
            }

            let savedPhoto = SavedPhoto(fileName: backFileName, frontFileName: frontFileName, timestamp: Date(), taskTitle: taskTitle, taskId: taskId)
            savedPhotos.append(savedPhoto)
            saveSavedPhotosMetadata()
            print("✅ Photo(s) saved successfully for task: \(taskId?.uuidString ?? "unknown")")
            return true
        } catch {
            print("❌ Failed to save photo: \(error.localizedDescription)")
            return false
        }
    }

    func loadSavedPhotos() {
        guard let data = try? Data(contentsOf: photosMetadataURL),
              let photos = try? JSONDecoder().decode([SavedPhoto].self, from: data) else {
            savedPhotos = []
            return
        }
        savedPhotos = photos
    }

    private func saveSavedPhotosMetadata() {
        guard let data = try? JSONEncoder().encode(savedPhotos) else { return }
        try? data.write(to: photosMetadataURL)
    }

    func loadPhoto(savedPhoto: SavedPhoto) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(savedPhoto.fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }

    func loadFrontPhoto(savedPhoto: SavedPhoto) -> UIImage? {
        guard let frontFileName = savedPhoto.frontFileName else {
            print("⚠️ No front photo available for this saved photo")
            return nil
        }
        let fileURL = photosDirectory.appendingPathComponent(frontFileName)
        return UIImage(contentsOfFile: fileURL.path)
    }

    func deletePhoto(_ savedPhoto: SavedPhoto) {
        // Delete back image
        let backFileURL = photosDirectory.appendingPathComponent(savedPhoto.fileName)
        try? FileManager.default.removeItem(at: backFileURL)

        // Delete front image if exists
        if let frontFileName = savedPhoto.frontFileName {
            let frontFileURL = photosDirectory.appendingPathComponent(frontFileName)
            try? FileManager.default.removeItem(at: frontFileURL)
        }

        savedPhotos.removeAll { $0.id == savedPhoto.id }
        saveSavedPhotosMetadata()
    }

    // MARK: - Task-Specific Photo Management

    func getPhotosForTask(_ taskId: UUID) -> [SavedPhoto] {
        return savedPhotos.filter { $0.taskId == taskId }
    }

    func getLatestPhotoForTask(_ taskId: UUID) -> SavedPhoto? {
        return savedPhotos
            .filter { $0.taskId == taskId }
            .max(by: { $0.timestamp < $1.timestamp })
    }

    func deletePhotosForTask(_ taskId: UUID) {
        let taskPhotos = getPhotosForTask(taskId)
        for photo in taskPhotos {
            deletePhoto(photo)
        }
    }
    
    func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("📹 Camera permissions already granted")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("📹 Camera permissions granted")
                    } else {
                        self.cameraError = "Camera access denied"
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.cameraError = "Camera access denied. Please enable in Settings."
            }
        @unknown default:
            break
        }
    }
    

    func clearCapturedImages() {
        DispatchQueue.main.async {
            // Release memory immediately for better performance
            self.capturedImage = nil
            self.frontCameraImage = nil
            self.backCameraImage = nil
            self.captureCompletionHandler = nil
        }
    }
    
    
    func takeSequentialPhoto() {
        print("📸 takeSequentialPhoto called - Phase: \(currentCapturePhase)")

        switch currentCapturePhase {
        case .readyForBack:
            takeBackCameraPhoto()
        case .readyForFront:
            takeFrontCameraPhoto()
        case .capturingBack, .capturingFront:
            print("⚠️ Already capturing, ignoring tap")
        case .completed:
            print("⚠️ Capture already completed")
        }
    }

    private func takeBackCameraPhoto() {
        print("📸 Taking back camera photo...")

        // Clear previous images
        clearCapturedImages()
        frontImageCaptured = false
        backImageCaptured = false

        currentCapturePhase = .capturingBack

        // Check if we're in simulator mode
        if isSimulator {
            print("🤖 Simulator: Creating mock back camera image")
            DispatchQueue.main.async {
                self.backCameraImage = self.createMockImage(text: "Back Camera\nPhoto", backgroundColor: .systemBlue)
                self.backImageCaptured = true
                self.currentCapturePhase = .readyForFront
                print("✅ Back camera photo captured (mock). Ready for front camera.")
            }
            return
        }

        // Real device capture
        guard let backOutput = self.backPhotoOutput,
              let backSession = self.backCaptureSession else {
            print("❌ Back camera not available")
            // Fall back to mock
            DispatchQueue.main.async {
                self.backCameraImage = self.createMockImage(text: "Back Camera\nUnavailable", backgroundColor: .systemRed)
                self.backImageCaptured = true
                self.currentCapturePhase = .readyForFront
            }
            return
        }

        // Ensure session is running
        if !backSession.isRunning {
            captureQueue.async {
                backSession.startRunning()
                // Start capture immediately - session will be ready
                self.captureBackPhoto(output: backOutput)
            }
        } else {
            captureBackPhoto(output: backOutput)
        }
    }

    private func takeFrontCameraPhoto() {
        print("📸 Taking front camera photo...")

        currentCapturePhase = .capturingFront

        // Check if we're in simulator mode
        if isSimulator {
            print("🤖 Simulator: Creating mock front camera image")
            DispatchQueue.main.async {
                self.frontCameraImage = self.createMockImage(text: "Front Camera\nPhoto", backgroundColor: .systemGreen)
                self.frontImageCaptured = true
                self.currentCapturePhase = .completed
                self.processCapturedImages()
                print("✅ Front camera photo captured (mock). Both photos complete.")
            }
            return
        }

        // Real device capture
        guard let frontOutput = self.frontPhotoOutput,
              let frontSession = self.frontCaptureSession else {
            print("❌ Front camera not available")
            // Fall back to mock
            DispatchQueue.main.async {
                self.frontCameraImage = self.createMockImage(text: "Front Camera\nUnavailable", backgroundColor: .systemRed)
                self.frontImageCaptured = true
                self.currentCapturePhase = .completed
                self.processCapturedImages()
            }
            return
        }

        // Ensure session is running
        if !frontSession.isRunning {
            captureQueue.async {
                frontSession.startRunning()
                // Start capture immediately - session will be ready
                self.captureFrontPhoto(output: frontOutput)
            }
        } else {
            captureFrontPhoto(output: frontOutput)
        }
    }

    private func captureBackPhoto(output: AVCapturePhotoOutput) {
        let settings = AVCapturePhotoSettings()
        if output.isHighResolutionCaptureEnabled {
            settings.isHighResolutionPhotoEnabled = true
        }

        print("📷 Capturing back camera...")
        output.capturePhoto(with: settings, delegate: self)
    }

    private func captureFrontPhoto(output: AVCapturePhotoOutput) {
        let settings = AVCapturePhotoSettings()
        if output.isHighResolutionCaptureEnabled {
            settings.isHighResolutionPhotoEnabled = true
        }

        print("📷 Capturing front camera...")
        output.capturePhoto(with: settings, delegate: self)
    }

    func resetCaptureFlow() {
        print("🔄 Resetting capture flow")
        currentCapturePhase = .readyForBack
        clearCapturedImages()
        frontImageCaptured = false
        backImageCaptured = false
    }

    private func performActualCapture(frontOutput: AVCapturePhotoOutput, backOutput: AVCapturePhotoOutput) {
        print("📷 Performing actual photo capture...")

        // Create separate settings for each camera with safe high resolution settings
        let frontSettings = AVCapturePhotoSettings()
        if frontOutput.isHighResolutionCaptureEnabled {
            frontSettings.isHighResolutionPhotoEnabled = true
            print("📷 Front camera: High resolution enabled")
        } else {
            print("📷 Front camera: High resolution not supported")
        }

        let backSettings = AVCapturePhotoSettings()
        if backOutput.isHighResolutionCaptureEnabled {
            backSettings.isHighResolutionPhotoEnabled = true
            print("📷 Back camera: High resolution enabled")
        } else {
            print("📷 Back camera: High resolution not supported")
        }

        // Verify sessions are still running before capture
        let frontStillRunning = self.frontCaptureSession?.isRunning ?? false
        let backStillRunning = self.backCaptureSession?.isRunning ?? false
        print("📊 Final session check - Front: \(frontStillRunning), Back: \(backStillRunning)")

        // Capture both cameras simultaneously for better synchronization
        if frontStillRunning {
            print("📷 Capturing front camera...")
            frontOutput.capturePhoto(with: frontSettings, delegate: self)
        } else {
            print("❌ Front session not running, using fallback")
            DispatchQueue.main.async {
                self.frontCameraImage = self.createMockImage(text: "Front Camera\nUnavailable", backgroundColor: .systemRed)
                self.frontImageCaptured = true
                self.checkAndProcessCapturedImages()
            }
        }

        if backStillRunning {
            print("📷 Capturing back camera...")
            backOutput.capturePhoto(with: backSettings, delegate: self)
        } else {
            print("❌ Back session not running, using fallback")
            DispatchQueue.main.async {
                self.backCameraImage = self.createMockImage(text: "Back Camera\nUnavailable", backgroundColor: .systemRed)
                self.backImageCaptured = true
                self.checkAndProcessCapturedImages()
            }
        }
    }

    private func generateMockImages() {
        // Create mock images for simulator testing
        let mockBackImage = createMockImage(text: "Back Camera\nMock Image", backgroundColor: .systemBlue)
        let mockFrontImage = createMockImage(text: "Front Camera\nMock Image", backgroundColor: .systemGreen)

        DispatchQueue.main.async {
            self.backCameraImage = mockBackImage
            self.frontCameraImage = mockFrontImage
            self.frontImageCaptured = true
            self.backImageCaptured = true

            // Process captured images to trigger completion handler
            self.processCapturedImages()
        }
    }

    private func createMockImage(text: String, backgroundColor: UIColor) -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    
    func addTimestampWatermark(to image: UIImage, taskTitle: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            image.draw(at: .zero)

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            let timestamp = formatter.string(from: Date())

            // Create Envive logo text
            let logoText = "ENVIVE"
            let logoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor.systemGreen,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]

            // Create task and timestamp text
            let infoText = "\(taskTitle) • \(timestamp)"
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -1.0
            ]

            let logoSize = logoText.size(withAttributes: logoAttributes)
            let infoSize = infoText.size(withAttributes: infoAttributes)

            // Calculate watermark dimensions
            let maxWidth = max(logoSize.width, infoSize.width)
            let totalHeight = logoSize.height + infoSize.height + 4 // 4pt spacing
            let padding: CGFloat = 15

            // Position watermark in bottom-right corner
            let watermarkRect = CGRect(
                x: image.size.width - maxWidth - padding,
                y: image.size.height - totalHeight - padding,
                width: maxWidth,
                height: totalHeight
            )

            // Create background
            let backgroundRect = CGRect(
                x: watermarkRect.origin.x - 8,
                y: watermarkRect.origin.y - 8,
                width: maxWidth + 16,
                height: totalHeight + 16
            )

            context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.6).cgColor)
            let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 8)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.fillPath()

            // Draw Envive logo
            let logoRect = CGRect(
                x: watermarkRect.origin.x + (maxWidth - logoSize.width) / 2,
                y: watermarkRect.origin.y,
                width: logoSize.width,
                height: logoSize.height
            )
            logoText.draw(in: logoRect, withAttributes: logoAttributes)

            // Draw task and timestamp info
            let infoRect = CGRect(
                x: watermarkRect.origin.x + (maxWidth - infoSize.width) / 2,
                y: watermarkRect.origin.y + logoSize.height + 4,
                width: infoSize.width,
                height: infoSize.height
            )
            infoText.draw(in: infoRect, withAttributes: infoAttributes)
        }
    }
    
    func combineDualImages() -> UIImage? {
        guard let frontImage = frontCameraImage,
              let backImage = backCameraImage else { return nil }
        
        let combinedSize = CGSize(
            width: max(frontImage.size.width, backImage.size.width),
            height: frontImage.size.height + backImage.size.height + 20
        )
        
        let renderer = UIGraphicsImageRenderer(size: combinedSize)
        
        return renderer.image { context in
            backImage.draw(at: .zero)
            
            let frontImageSize = CGSize(width: 120, height: 160)
            let frontImageRect = CGRect(
                x: combinedSize.width - frontImageSize.width - 20,
                y: backImage.size.height - frontImageSize.height - 20,
                width: frontImageSize.width,
                height: frontImageSize.height
            )
            
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(3)
            context.cgContext.stroke(frontImageRect)
            
            frontImage.draw(in: frontImageRect)
        }
    }

    // MARK: - Enhanced Dual Camera System (NEW)

    func setupDualCameraSystem() {
        print("🔧 Setting up enhanced dual camera system...")

        DispatchQueue.main.async {
            self.cameraStatus = .initializing
            self.cameraError = nil
        }

        captureQueue.async {
            self.requestCameraPermissions { [weak self] granted in
                guard let self = self else { return }

                guard granted else {
                    print("❌ Camera permission denied")
                    DispatchQueue.main.async {
                        self.cameraError = "Camera permission denied"
                        self.cameraStatus = .failed
                    }
                    return
                }

                // Initialize cameras immediately after permission grant
                self.captureQueue.async {
                    self.initializeCameras()
                }
            }
        }
    }

    private func requestCameraPermissions(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("📹 Camera permissions already granted")
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                print("📹 Camera permission request result: \(granted)")
                completion(granted)
            }
        case .denied, .restricted:
            print("❌ Camera access denied or restricted")
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func initializeCameras() {
        print("🔧 Initializing camera hardware...")

        do {
            // Stop any existing sessions safely
            dualCaptureSession?.stopRunning()
            frontCaptureSession?.stopRunning()
            backCaptureSession?.stopRunning()

            // Create separate capture sessions for sequential photo capture
            frontCaptureSession = AVCaptureSession()
            backCaptureSession = AVCaptureSession()

            guard let frontSession = frontCaptureSession,
                  let backSession = backCaptureSession else {
                DispatchQueue.main.async {
                    self.cameraError = "Failed to create capture sessions"
                    self.cameraStatus = .failed
                }
                return
            }

            // Set session presets optimized for preview performance
            if frontSession.canSetSessionPreset(.high) {
                frontSession.sessionPreset = .high
            }
            if backSession.canSetSessionPreset(.high) {
                backSession.sessionPreset = .high
            }

            var frontCameraAvailable = false
            var backCameraAvailable = false

            // Setup front camera with error handling
            do {
                frontSession.beginConfiguration()
                defer { frontSession.commitConfiguration() }

                if setupCamera(position: .front, session: frontSession) {
                    frontCameraAvailable = true
                    print("✅ Front camera initialized successfully")
                } else {
                    print("❌ Front camera initialization failed")
                }
            }

            // Setup back camera with error handling
            do {
                backSession.beginConfiguration()
                defer { backSession.commitConfiguration() }

                if setupCamera(position: .back, session: backSession) {
                    backCameraAvailable = true
                    print("✅ Back camera initialized successfully")
                } else {
                    print("❌ Back camera initialization failed")
                }
            }

            // Determine final status
            DispatchQueue.main.async {
                if frontCameraAvailable && backCameraAvailable {
                    self.cameraStatus = .ready
                    print("✅ Dual camera system ready")
                } else if frontCameraAvailable {
                    self.cameraStatus = .frontOnly
                    print("⚠️ Front camera only")
                } else if backCameraAvailable {
                    self.cameraStatus = .backOnly
                    print("⚠️ Back camera only")
                } else {
                    self.cameraStatus = .failed
                    self.cameraError = "No cameras available"
                    print("❌ No cameras available")
                }
            }

            // Start the sessions if at least one camera is available
            if frontCameraAvailable || backCameraAvailable {
                // Start immediately for faster preview
                self.startCameraSession()
            } else {
                // If no cameras available but we're in simulator, still try to continue
                if self.isSimulator {
                    print("🤖 No hardware cameras in simulator, mock setup ready")
                    DispatchQueue.main.async {
                        self.cameraStatus = .ready
                    }
                }
            }

        } catch {
            print("❌ Camera initialization error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.cameraError = "Camera initialization failed: \(error.localizedDescription)"
                self.cameraStatus = .failed
            }
        }
    }

    private func setupCamera(position: AVCaptureDevice.Position, session: AVCaptureSession) -> Bool {
        let positionName = position == .front ? "Front" : "Back"

        // Handle simulator
        if isSimulator {
            let photoOutput = AVCapturePhotoOutput()

            // Configure photo output capabilities
            photoOutput.isHighResolutionCaptureEnabled = true

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)

                if position == .front {
                    frontPhotoOutput = photoOutput
                } else {
                    backPhotoOutput = photoOutput
                }

                print("🤖 Mock \(positionName) camera created for simulator")
                return true
            }
            return false
        }

        // Find camera device
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("❌ \(positionName) camera device not found")
            return false
        }

        // Store camera reference
        if position == .front {
            frontCamera = camera
        } else {
            backCamera = camera
        }

        // Create input
        do {
            let input = try AVCaptureDeviceInput(device: camera)

            if session.canAddInput(input) {
                session.addInput(input)

                // Store input reference
                if position == .front {
                    frontInput = input
                } else {
                    backInput = input
                }

                print("✅ \(positionName) camera input added")
            } else {
                print("❌ Cannot add \(positionName) camera input")
                return false
            }
        } catch {
            print("❌ Failed to create \(positionName) camera input: \(error)")
            return false
        }

        // Create photo output
        let photoOutput = AVCapturePhotoOutput()

        // Configure photo output capabilities
        photoOutput.isHighResolutionCaptureEnabled = true

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)

            // Store output reference
            if position == .front {
                frontPhotoOutput = photoOutput
            } else {
                backPhotoOutput = photoOutput
            }

            print("✅ \(positionName) camera output added (High Res: \(photoOutput.isHighResolutionCaptureEnabled))")
            return true
        } else {
            print("❌ Cannot add \(positionName) camera output")
            return false
        }
    }

    func startCameraSession() {
        print("📷 Starting camera sessions...")
        captureQueue.async {
            if let frontSession = self.frontCaptureSession, !frontSession.isRunning {
                frontSession.startRunning()
                print("✅ Front camera session started")
            }

            if let backSession = self.backCaptureSession, !backSession.isRunning {
                backSession.startRunning()
                print("✅ Back camera session started")
            }

            // Legacy support for dual session
            if let dualSession = self.dualCaptureSession, !dualSession.isRunning {
                dualSession.startRunning()
                print("✅ Dual camera session started")
            }

            // Verify session status
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let frontRunning = self.frontCaptureSession?.isRunning ?? false
                let backRunning = self.backCaptureSession?.isRunning ?? false
                print("📊 Session Status - Front: \(frontRunning), Back: \(backRunning)")
            }
        }
    }

    func stopCameraSession() {
        captureQueue.async {
            self.frontCaptureSession?.stopRunning()
            self.backCaptureSession?.stopRunning()
            // Legacy support for dual session
            self.dualCaptureSession?.stopRunning()
            print("📷 Camera sessions stopped")
        }
    }

    // MARK: - Enhanced Photo Capture

    func capturePhoto(completion: @escaping (UIImage?, UIImage?) -> Void) {
        print("📸 Starting dual camera capture...")

        DispatchQueue.main.async {
            self.isCapturing = true
            self.cameraStatus = .capturing
        }

        captureCompletionHandler = completion
        frontImageCaptured = false
        backImageCaptured = false

        // Clear previous images
        clearCapturedImages()

        if isSimulator {
            generateEnhancedMockImages()
            return
        }

        // Use the new sequential photo implementation
        takeSequentialPhoto()
    }


    private func generateEnhancedMockImages() {
        print("🤖 Generating enhanced mock images for simulator")

        let mockBackImage = createEnhancedMockImage(text: "📷 Back Camera\nMock Photo", backgroundColor: .systemBlue)
        let mockFrontImage = createEnhancedMockImage(text: "🤳 Front Camera\nMock Photo", backgroundColor: .systemGreen)

        DispatchQueue.main.async {
            self.backCameraImage = mockBackImage
            self.frontCameraImage = mockFrontImage
            self.frontImageCaptured = true
            self.backImageCaptured = true
            self.processCapturedImages()
        }
    }

    private func createEnhancedMockImage(text: String, backgroundColor: UIColor) -> UIImage {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]

            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            attributedString.draw(in: textRect)
        }
    }

    private func checkAndProcessCapturedImages() {
        // Only process when both images are captured (or when we have what we need)
        if shouldProcessCapturedImages() {
            processCapturedImages()
        }
    }

    private func processCapturedImages() {
        // Store both back and front camera images separately
        // This prevents duplicate overlays in social view
        let backImage = backCameraImage
        let frontImage = frontCameraImage

        if backImage != nil || frontImage != nil {
            DispatchQueue.main.async {
                // Use back camera for display if available, otherwise front
                self.capturedImage = backImage ?? frontImage
                self.isCapturing = false
                self.cameraStatus = .ready

                // Call completion handler with both images
                self.captureCompletionHandler?(backImage, frontImage)
                self.captureCompletionHandler = nil

                print("✅ Photo capture completed successfully - back: \(backImage != nil), front: \(frontImage != nil)")
            }
        } else {
            DispatchQueue.main.async {
                self.isCapturing = false
                self.cameraStatus = .ready
                self.cameraError = "Failed to process captured images"

                self.captureCompletionHandler?(nil, nil)
                self.captureCompletionHandler = nil

                print("❌ Photo capture failed - could not process images")
            }
        }
    }

    func combineEnhancedDualImages() -> UIImage? {
        // Handle cases where we only have one image
        if let frontImage = frontCameraImage, backCameraImage == nil {
            return frontImage
        }

        if let backImage = backCameraImage, frontCameraImage == nil {
            return backImage
        }

        guard let frontImage = frontCameraImage,
              let backImage = backCameraImage else {
            return nil
        }

        // Create composite image with back camera as main and front as overlay
        let mainSize = backImage.size
        let renderer = UIGraphicsImageRenderer(size: mainSize)

        return renderer.image { context in
            // Draw main (back camera) image
            backImage.draw(at: .zero)

            // Calculate front camera overlay size and position
            let overlaySize = CGSize(
                width: mainSize.width * 0.25,
                height: mainSize.height * 0.25
            )

            let overlayRect = CGRect(
                x: mainSize.width - overlaySize.width - 20,
                y: 20,
                width: overlaySize.width,
                height: overlaySize.height
            )

            // Draw border for front camera overlay
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(4)
            context.cgContext.stroke(overlayRect.insetBy(dx: -2, dy: -2))

            // Draw front camera image as overlay
            frontImage.draw(in: overlayRect)
        }
    }
}

extension CameraManager {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📷 Photo delegate called - processing photo")

        if let error = error {
            let errorDescription = error.localizedDescription
            print("❌ Photo capture error: \(errorDescription)")

            // Handle specific "Cannot Record" error
            if errorDescription.contains("Cannot Record") {
                print("🔄 'Cannot Record' error detected - camera may be busy")

                // Mark this camera as failed but continue with the other
                DispatchQueue.main.async {
                    if output == self.frontPhotoOutput {
                        print("⚠️ Front camera failed, continuing with back camera only")
                        self.frontImageCaptured = true
                        self.frontCameraImage = self.createMockImage(text: "Front Camera\nUnavailable", backgroundColor: .systemRed)
                    } else if output == self.backPhotoOutput {
                        print("⚠️ Back camera failed, continuing with front camera only")
                        self.backImageCaptured = true
                        self.backCameraImage = self.createMockImage(text: "Back Camera\nUnavailable", backgroundColor: .systemRed)
                    }

                    // Check if we can still process with available images
                    self.checkAndProcessCapturedImages()
                }
            } else {
                // Other errors - fail completely
                DispatchQueue.main.async {
                    self.cameraError = "Photo capture failed: \(errorDescription)"
                    self.isCapturing = false
                    self.cameraStatus = .ready
                    self.captureCompletionHandler?(nil, nil)
                    self.captureCompletionHandler = nil
                }
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to process photo data")
            DispatchQueue.main.async {
                self.cameraError = "Failed to process photo data"
                self.isCapturing = false
                self.cameraStatus = .ready
                self.captureCompletionHandler?(nil, nil)
                self.captureCompletionHandler = nil
            }
            return
        }

        DispatchQueue.main.async {
            if output == self.frontPhotoOutput {
                print("📷 Front camera image captured")
                self.frontCameraImage = image
                self.frontImageCaptured = true
                print("✅ Front camera capture completed")
                self.checkAndProcessCapturedImages()
            } else if output == self.backPhotoOutput {
                print("📷 Back camera image captured")
                self.backCameraImage = image
                self.backImageCaptured = true
                print("✅ Back camera capture completed")
                self.checkAndProcessCapturedImages()
            }
        }
    }

    private func shouldProcessCapturedImages() -> Bool {
        switch cameraStatus {
        case .ready:
            // Both cameras available - wait for both
            return frontImageCaptured && backImageCaptured
        case .frontOnly:
            // Only front camera - process when front is captured
            return frontImageCaptured
        case .backOnly:
            // Only back camera - process when back is captured
            return backImageCaptured
        default:
            return false
        }
    }
}

// MARK: - Enhanced Screen Time Model with Friends
class EnhancedScreenTimeModel: ObservableObject {
    @Published var isAuthorized = false
    // Removed selectedAppsToDiscourage - now using appSelectionStore.familyActivitySelection
    @Published var authorizationStatus: String = "Not Requested"
    @Published var minutesEarned: Int = 45
    @Published var xpBalance: Int = 0
    @Published var isSessionActive = false
    @Published var sessionTimeRemaining: TimeInterval = 0
    @Published var isSessionPaused = false
    @Published var sessionTimeAllocated: TimeInterval = 0  // Total time user allocated for session
    @Published var sessionTimeUsed: TimeInterval = 0      // Time actually spent/used

    // Session timing for background handling
    private var sessionStartTime: Date?
    private var sessionEndTime: Date?

    // Computed property for total available screen time
    // Returns only the minutesEarned balance (not including active session time)
    // Active session time is displayed separately in the UI to avoid double-counting
    var totalAvailableMinutes: Int {
        return minutesEarned
    }
    private var pausedTime: Date?

    // Streak tracking
    @Published var currentStreak: Int = UserDefaults.standard.integer(forKey: "currentStreak")
    @Published var hasCompletedTaskToday: Bool = false
    @Published var shouldShowStreakFireAnimation: Bool = false
    @Published var justIncrementedStreak: Bool = false
    var lastTaskCompletionDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastTaskCompletionDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastTaskCompletionDate") }
    }

    // Social Features
    @Published var currentUser: User = User(username: "You", xpBalance: 0, totalXPEarned: 0, credibilityScore: 100.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false)
    @Published var friends: [User] = []
    @Published var recentTasks: [TaskItem] = []
    @Published var friendActivities: [FriendActivity] = []
    @Published var socialPosts: [SocialPost] = []
    
    // Friend Management
    @Published var searchResults: [User] = []
    @Published var pendingFriendRequests: [User] = []
    @Published var sentFriendRequests: [User] = []
    @Published var allUsers: [User] = []
    @Published var isSearching = false

    // Toast notifications
    @Published var toastMessage: String?
    @Published var showToast = false
    
    // Camera
    @Published var cameraManager = CameraManager()

    // Notifications
    @Published var notificationManager = NotificationManager()
    // App Selection Store (shared with ParentControlView)
    @Published var appSelectionStore = AppSelectionStore()
    // Credibility Manager (shared across app)
    @Published var credibilityManager = CredibilityManager()

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private var sessionTimer: Timer?
    private var sessionWarningTimer: Timer?
    
    init() {
        checkAuthorizationStatus()
        loadMockData()
        setupMockUserDatabase()
        loadMockSocialPosts()

        // Request notification permission on init
        notificationManager.requestPermission()

        // Ensure apps are blocked if no session is active
        ensureAppsAreBlocked()

        // Sync credibility manager with current user score
        credibilityManager.credibilityScore = Int(currentUser.credibilityScore)

        // Check streak status on app launch
        checkStreakStatus()

        // Listen for widget requests to start screen time session
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StartScreenTimeSession"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let minutes = notification.userInfo?["minutes"] as? Int {
                print("🎯 Received widget request to start \(minutes) minute session")
                self?.startEarnedSession(duration: minutes)
            }
        }

        // Check for pending widget session requests
        checkForPendingWidgetSession()

        // Check for widget end session requests
        checkForEndSessionRequest()
    }

    func checkForPendingWidgetSession() {
        print("🔍 Checking for pending widget session...")

        // Use shared container to read widget data
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.neal.envivenew.screentime") else {
            print("❌ Failed to access shared UserDefaults container")
            return
        }

        // Check if there's a pending session request from the widget
        if let minutes = sharedDefaults.object(forKey: "PendingScreenTimeMinutes") as? Int,
           let timestamp = sharedDefaults.object(forKey: "PendingScreenTimeTimestamp") as? TimeInterval {

            let requestDate = Date(timeIntervalSince1970: timestamp)
            let now = Date()

            // Only honor requests made in the last 10 seconds to avoid stale requests
            if now.timeIntervalSince(requestDate) < 10 {
                print("🎯 Found pending widget request for \(minutes) minutes (requested \(now.timeIntervalSince(requestDate))s ago)")

                // Clear the pending request
                sharedDefaults.removeObject(forKey: "PendingScreenTimeMinutes")
                sharedDefaults.removeObject(forKey: "PendingScreenTimeTimestamp")
                sharedDefaults.synchronize()

                // Start the session after a short delay to ensure UI is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🚀 Starting session from widget request...")
                    self.startEarnedSession(duration: minutes)
                }
            } else {
                print("⚠️ Found stale widget request (requested \(now.timeIntervalSince(requestDate))s ago), ignoring")
                sharedDefaults.removeObject(forKey: "PendingScreenTimeMinutes")
                sharedDefaults.removeObject(forKey: "PendingScreenTimeTimestamp")
                sharedDefaults.synchronize()
            }
        } else {
            print("ℹ️ No pending widget session found")
        }
    }

    func checkForEndSessionRequest() {
        print("🔍 Checking for widget end session request...")

        guard let sharedDefaults = UserDefaults(suiteName: "group.com.neal.envivenew.screentime") else {
            print("❌ Failed to access shared UserDefaults container")
            return
        }

        if sharedDefaults.bool(forKey: "EndSessionRequested") {
            print("🛑 Widget requested to end session")
            sharedDefaults.set(false, forKey: "EndSessionRequested")
            sharedDefaults.synchronize()

            if isSessionActive {
                print("🚀 Ending session from widget request...")
                endSession()
            } else {
                print("ℹ️ No active session to end")
            }
        }
    }

    // MARK: - Friend Management
    func setupMockUserDatabase() {
        // Mock user database
        allUsers = [
            User(username: "Oliver", xpBalance: 120, totalXPEarned: 580, credibilityScore: 95.0, friends: [], pendingFriendRequests: [], isParentallyManaged: true),
            User(username: "Emma", xpBalance: 85, totalXPEarned: 420, credibilityScore: 88.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false),
            User(username: "Jake", xpBalance: 200, totalXPEarned: 750, credibilityScore: 92.0, friends: [], pendingFriendRequests: [], isParentallyManaged: true),
            User(username: "Sophia", xpBalance: 150, totalXPEarned: 650, credibilityScore: 90.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false),
            User(username: "Alex", xpBalance: 75, totalXPEarned: 300, credibilityScore: 85.0, friends: [], pendingFriendRequests: [], isParentallyManaged: true),
            User(username: "Maya", xpBalance: 180, totalXPEarned: 820, credibilityScore: 97.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false),
            User(username: "Noah", xpBalance: 95, totalXPEarned: 480, credibilityScore: 87.0, friends: [], pendingFriendRequests: [], isParentallyManaged: true),
            User(username: "Zoe", xpBalance: 220, totalXPEarned: 900, credibilityScore: 94.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false)
        ]
    }
    
    func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.searchResults = self.allUsers.filter { user in
                user.username.lowercased().contains(query.lowercased()) &&
                user.username != self.currentUser.username &&
                !self.friends.contains(where: { $0.username == user.username }) &&
                !self.sentFriendRequests.contains(where: { $0.username == user.username })
            }
            self.isSearching = false
        }
    }
    
    func sendFriendRequest(to user: User) {
        sentFriendRequests.append(user)
        
        if let index = allUsers.firstIndex(where: { $0.username == user.username }) {
            allUsers[index].pendingFriendRequests.append(currentUser.username)
        }
        
        searchResults.removeAll { $0.username == user.username }
        
        print("Friend request sent to \(user.username)")
    }
    
    func acceptFriendRequest(from user: User) {
        friends.append(user)
        currentUser.friends.append(user.username)
        
        pendingFriendRequests.removeAll { $0.username == user.username }
        currentUser.pendingFriendRequests.removeAll { $0 == user.username }
        
        if let index = allUsers.firstIndex(where: { $0.username == user.username }) {
            allUsers[index].friends.append(currentUser.username)
        }
        
        print("Accepted friend request from \(user.username)")
    }
    
    func declineFriendRequest(from user: User) {
        pendingFriendRequests.removeAll { $0.username == user.username }
        currentUser.pendingFriendRequests.removeAll { $0 == user.username }
        
        print("Declined friend request from \(user.username)")
    }
    
    func removeFriend(_ user: User) {
        let username = user.username
        friends.removeAll { $0.username == username }
        currentUser.friends.removeAll { $0 == username }

        if let index = allUsers.firstIndex(where: { $0.username == username }) {
            allUsers[index].friends.removeAll { $0 == currentUser.username }
        }

        print("Removed \(username) from friends")

        // Show toast notification
        showToastNotification("\(username) has been removed as a friend")
    }

    func showToastNotification(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showToast = false
            }
        }
    }
    
    func cancelFriendRequest(to user: User) {
        sentFriendRequests.removeAll { $0.username == user.username }
        
        if let index = allUsers.firstIndex(where: { $0.username == user.username }) {
            allUsers[index].pendingFriendRequests.removeAll { $0 == currentUser.username }
        }
        
        print("Cancelled friend request to \(user.username)")
    }
    
    func simulateIncomingFriendRequests() {
        let incomingRequests = allUsers.filter { user in
            !friends.contains(where: { $0.username == user.username }) &&
            !pendingFriendRequests.contains(where: { $0.username == user.username }) &&
            user.username != currentUser.username
        }.prefix(2)
        
        pendingFriendRequests.append(contentsOf: incomingRequests)
        currentUser.pendingFriendRequests.append(contentsOf: incomingRequests.map { $0.username })
    }
    
    // MARK: - Task Completion with Photo
    func completeTaskWithPhoto(_ task: TaskItem, backPhoto: UIImage?, frontPhoto: UIImage?) {
        print("🔄 ========== TASK COMPLETION START ==========")
        print("🔄 Task: \(task.title)")
        print("🔄 Has Back Photo: \(backPhoto != nil)")
        print("🔄 Has Front Photo: \(frontPhoto != nil)")
        print("🔄 Current Streak Before: \(currentStreak)")
        print("🔄 Has Completed Today Before: \(hasCompletedTaskToday)")
        print("🔄 Last Completion: \(lastTaskCompletionDate?.description ?? "Never")")

        let credibilityMultiplier = currentUser.credibilityScore / 100.0
        let earnedXP = Int(Double(task.xpReward) * credibilityMultiplier)

        xpBalance += earnedXP
        currentUser.xpBalance += earnedXP
        currentUser.totalXPEarned += earnedXP

        if let index = recentTasks.firstIndex(where: { $0.id == task.id }) {
            print("✅ Found task at index \(index), marking as completed")
            DispatchQueue.main.async {
                self.recentTasks[index].verificationPhoto = backPhoto
                self.recentTasks[index].verificationPhotoFront = frontPhoto
                self.recentTasks[index].completed = true
                self.recentTasks[index].completedAt = Date()
                print("✅ Task marked completed: \(self.recentTasks[index].completed)")
            }
        } else {
            print("❌ Could not find task with ID: \(task.id)")
            print("🔍 Available task IDs in recentTasks: \(recentTasks.map { "\($0.title): \($0.id)" })")
        }
        
        let activity = FriendActivity(
            userId: currentUser.id.uuidString,
            username: currentUser.username,
            activity: "Completed: \(task.title)",
            xpEarned: earnedXP,
            timestamp: Date(),
            kudos: 0,
            hasVerificationPhoto: backPhoto != nil,
            verificationPhoto: backPhoto
        )

        friendActivities.insert(activity, at: 0)

        // Create social post for all completed tasks (with or without photo)
        print("📱 Creating social post for completed task...")
        DispatchQueue.main.async {
            self.createSocialPostFromTask(task: task, photo: backPhoto, xpEarned: earnedXP)
        }

        print("Completed task: \(task.title) for \(earnedXP) XP with photo verification")

        // Update streak (this returns true if fire animation should show)
        print("🔄 About to call updateStreak()...")
        let shouldShowFire = updateStreak()
        print("🔄 updateStreak() returned: \(shouldShowFire)")
        print("🔄 Current Streak After: \(currentStreak)")
        print("🔄 shouldShowStreakFireAnimation: \(shouldShowStreakFireAnimation)")
        print("🔄 ========== TASK COMPLETION END ==========")

        if shouldShowFire {
            print("🔥 First task of the day - streak is now \(currentStreak)")
        }

        // Send notification to friends about task completion
        notificationManager.sendFriendCompletedTaskNotification(
            friendName: currentUser.username,
            taskTitle: task.title,
            xpEarned: earnedXP,
            hasPhoto: backPhoto != nil
        )
    }

    // MARK: - Streak Methods
    func checkStreakStatus() {
        let calendar = Calendar.current
        let now = Date()

        guard let lastCompletion = lastTaskCompletionDate else {
            // No previous completion - streak is 0
            currentStreak = 0
            hasCompletedTaskToday = false
            return
        }

        // Check if last completion was today
        if calendar.isDateInToday(lastCompletion) {
            hasCompletedTaskToday = true
            return
        }

        // Check if last completion was yesterday
        if calendar.isDateInYesterday(lastCompletion) {
            // Streak continues, but they haven't completed today yet
            hasCompletedTaskToday = false
            return
        }

        // Last completion was more than 1 day ago - streak is lost
        if currentStreak > 0 {
            print("💔 Streak lost! Was \(currentStreak) days")
            // Don't reset here - let the view show the loss alert
        }
    }

    func updateStreak() -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Check if they already completed a task today
        if hasCompletedTaskToday {
            print("⚠️ Already completed a task today - no streak update")
            return false // Don't increment streak
        }

        var shouldShowFireAnimation = false

        if let lastCompletion = lastTaskCompletionDate {
            if calendar.isDateInYesterday(lastCompletion) {
                // Increment streak - completed yesterday and now today
                currentStreak += 1
                shouldShowFireAnimation = true
                print("✅ Streak continued! Yesterday was last completion. Streak now: \(currentStreak)")
            } else if !calendar.isDateInToday(lastCompletion) {
                // Streak was broken - start over
                print("💔 Streak was broken. Last completion was \(lastCompletion). Starting fresh.")
                currentStreak = 1
                shouldShowFireAnimation = true
            } else {
                print("⚠️ Last completion was today - this shouldn't happen")
            }
        } else {
            // First ever task
            print("🎉 First ever task! Starting streak at 1")
            currentStreak = 1
            shouldShowFireAnimation = true
        }

        // Update stored values
        lastTaskCompletionDate = now
        hasCompletedTaskToday = true
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")

        // Trigger fire animation in views
        if shouldShowFireAnimation {
            DispatchQueue.main.async {
                self.shouldShowStreakFireAnimation = true
                self.justIncrementedStreak = true
            }
        }

        print("🔥 Streak updated to \(currentStreak) days. Fire animation: \(shouldShowFireAnimation)")
        return shouldShowFireAnimation
    }

    func resetStreak() {
        currentStreak = 0
        UserDefaults.standard.set(0, forKey: "currentStreak")
        lastTaskCompletionDate = nil
        hasCompletedTaskToday = false
    }

    func hasLostStreak() -> Bool {
        guard let lastCompletion = lastTaskCompletionDate else { return false }

        let calendar = Calendar.current
        let now = Date()

        // Check if last completion was more than 1 day ago AND streak > 0
        if currentStreak > 0 &&
           !calendar.isDateInToday(lastCompletion) &&
           !calendar.isDateInYesterday(lastCompletion) {
            return true
        }
        return false
    }

    // MARK: - Original Methods
    func loadMockData() {
        recentTasks = [
            TaskItem(title: "Morning run", category: .exercise, xpReward: 30, estimatedMinutes: 30, isCustom: false, completed: false, createdBy: currentUser.id.uuidString, isGroupTask: false, participants: [], verificationRequired: true, verificationPhoto: nil, verificationPhotoFront: nil),
            TaskItem(title: "Clean room", category: .chores, xpReward: 20, estimatedMinutes: 20, isCustom: false, completed: false, createdBy: currentUser.id.uuidString, isGroupTask: false, participants: [], verificationRequired: true, verificationPhoto: nil, verificationPhotoFront: nil),
            TaskItem(title: "Study math", category: .study, xpReward: 45, estimatedMinutes: 45, isCustom: false, completed: false, createdBy: currentUser.id.uuidString, isGroupTask: false, participants: [], verificationRequired: true, verificationPhoto: nil, verificationPhotoFront: nil)  // Fixed: ALL tasks require photo
        ]

        friendActivities = [
            FriendActivity(userId: "1", username: "Oliver", activity: "Completed a 5-mile hike", xpEarned: 90, timestamp: Date().addingTimeInterval(-3600), kudos: 3, hasVerificationPhoto: true, verificationPhoto: nil),
            FriendActivity(userId: "2", username: "Emma", activity: "Finished homework", xpEarned: 30, timestamp: Date().addingTimeInterval(-7200), kudos: 1, hasVerificationPhoto: false, verificationPhoto: nil),
            FriendActivity(userId: "3", username: "Jake", activity: "Helped with dishes", xpEarned: 15, timestamp: Date().addingTimeInterval(-10800), kudos: 2, hasVerificationPhoto: true, verificationPhoto: nil)
        ]
    }
    
    func checkAuthorizationStatus() {
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
            authorizationStatus = "Approved"
        case .denied:
            isAuthorized = false
            authorizationStatus = "Denied"
        case .notDetermined:
            isAuthorized = false
            authorizationStatus = "Not Requested"
        @unknown default:
            isAuthorized = false
            authorizationStatus = "Unknown"
        }
    }
    
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            DispatchQueue.main.async {
                self.checkAuthorizationStatus()
            }
        } catch {
            DispatchQueue.main.async {
                self.authorizationStatus = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    func startAppRestrictions() {
        // Check current authorization status directly
        let currentAuthStatus = center.authorizationStatus
        print("🔍 Current authorization status: \(currentAuthStatus)")

        guard currentAuthStatus == .approved else {
            print("❌ Cannot start app restrictions - not authorized")
            print("❌ Current status: \(currentAuthStatus)")
            // Update our cached status
            checkAuthorizationStatus()
            return
        }

        let selection = appSelectionStore.familyActivitySelection
        print("🛡️ Starting app restrictions...")
        print("🛡️ Selected apps: \(selection.applicationTokens.count)")
        print("🛡️ Selected categories: \(selection.categoryTokens.count)")
        print("🛡️ Selected websites: \(selection.webDomainTokens.count)")

        // PERFORMANCE FIX: Run shield operations asynchronously on background thread
        // to prevent UI freeze. clearAllSettings() is extremely expensive (9-10 seconds).
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            // Only clear shield settings, not ALL settings - much faster
            await MainActor.run {
                self.store.shield.applications = nil
                self.store.shield.applicationCategories = nil
                self.store.shield.webDomains = nil
            }

            // Small delay to ensure clear completes
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // Apply new shields
            await MainActor.run {
                if !selection.applicationTokens.isEmpty {
                    self.store.shield.applications = selection.applicationTokens
                    print("🛡️ Applied shield to \(selection.applicationTokens.count) apps")
                }

                if !selection.categoryTokens.isEmpty {
                    self.store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
                    print("🛡️ Applied shield to \(selection.categoryTokens.count) categories")
                }

                if !selection.webDomainTokens.isEmpty {
                    self.store.shield.webDomains = selection.webDomainTokens
                    print("🛡️ Applied shield to \(selection.webDomainTokens.count) websites")
                }

                print("✅ App restrictions started successfully")
            }
        }
    }
    
    func removeAppRestrictions() {
        // Check current authorization status directly
        let currentAuthStatus = center.authorizationStatus
        print("🔍 Current authorization status for removal: \(currentAuthStatus)")

        guard currentAuthStatus == .approved else {
            print("❌ Cannot remove app restrictions - not authorized")
            print("❌ Current authorization status: \(currentAuthStatus)")
            // Update our cached status
            checkAuthorizationStatus()
            return
        }

        let selection = appSelectionStore.familyActivitySelection
        print("🔓 Removing app restrictions...")
        print("🔓 Clearing shields for \(selection.applicationTokens.count) apps")
        print("🔓 Clearing shields for \(selection.categoryTokens.count) categories")
        print("🔓 Clearing shields for \(selection.webDomainTokens.count) websites")

        // PERFORMANCE FIX: Run asynchronously to prevent UI freeze
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }

            await MainActor.run {
                // Only clear shield settings - much faster than clearAllSettings()
                self.store.shield.applications = nil
                self.store.shield.applicationCategories = nil
                self.store.shield.webDomains = nil

                print("✅ App restrictions removed successfully")
            }
        }
    }
    
    func completeTask(_ task: TaskItem) {
        let credibilityMultiplier = currentUser.credibilityScore / 100.0
        let earnedXP = Int(Double(task.xpReward) * credibilityMultiplier)
        
        xpBalance += earnedXP
        currentUser.xpBalance += earnedXP
        currentUser.totalXPEarned += earnedXP
        
        let activity = FriendActivity(
            userId: currentUser.id.uuidString,
            username: currentUser.username,
            activity: "Completed: \(task.title)",
            xpEarned: earnedXP,
            timestamp: Date(),
            kudos: 0,
            hasVerificationPhoto: task.verificationRequired,
            verificationPhoto: nil
        )

        friendActivities.insert(activity, at: 0)

        // Create social post for completed task (without photo)
        print("📱 Creating social post for completed task (no photo)...")
        DispatchQueue.main.async {
            self.createSocialPostFromTask(task: task, photo: nil, xpEarned: earnedXP)
        }
    }
    
    func createCustomTask(title: String, category: TaskCategory) -> TaskItem {
        let defaultMinutes = 30
        let suggestedXP = calculateXPForTask(category: category, minutes: defaultMinutes)

        let newTask = TaskItem(
            title: title,
            category: category,
            xpReward: suggestedXP,
            estimatedMinutes: defaultMinutes,
            isCustom: true,
            completed: false,
            createdBy: currentUser.id.uuidString,
            isGroupTask: false,
            participants: [],
            verificationRequired: true,  // ALL tasks require photo verification
            verificationPhoto: nil,
            verificationPhotoFront: nil
        )
        
        recentTasks.insert(newTask, at: 0)
        return newTask
    }
    
    func calculateXPForTask(category: TaskCategory, minutes: Int) -> Int {
        // Simple 1:1 ratio: 1 minute of work = 1 XP
        // Credibility multiplier is the only variable that affects final screen time
        return max(5, minutes)
    }
    
    func convertXPToMinutes(conversionRate: Int = 5) {
        // Use credibility-based conversion
        let earnedMinutes = credibilityManager.calculateXPToMinutes(xpAmount: xpBalance)

        minutesEarned += earnedMinutes

        // Deduct all XP used
        let usedXP = xpBalance
        xpBalance = 0
        currentUser.xpBalance = 0

        // Sync credibility score
        currentUser.credibilityScore = Double(credibilityManager.credibilityScore)

        let rate = credibilityManager.getFormattedConversionRate()
        let tier = credibilityManager.getCurrentTier().name
        print("✨ Converted \(usedXP) XP → \(earnedMinutes) minutes (Rate: \(rate), Tier: \(tier))")
    }
    
    func startEarnedSession(duration: Int) {
        print("🚀 ============ START EARNED SESSION ============")
        print("🚀 Duration requested: \(duration) minutes")
        print("🚀 Minutes available: \(minutesEarned)")
        print("🚀 Is session active: \(isSessionActive)")
        print("🚀 Is session paused: \(isSessionPaused)")
        print("🚀 Authorization status: \(authorizationStatus)")
        logCurrentShieldStatus()

        // Check guard conditions individually for better debugging
        if duration > minutesEarned {
            print("❌ FAIL: Not enough minutes (need \(duration), have \(minutesEarned))")
            return
        }
        if isSessionActive {
            print("❌ FAIL: Session already active")
            return
        }
        if isSessionPaused {
            print("❌ FAIL: Session is paused")
            return
        }

        print("✅ All checks passed - starting session")

        print("🔓 Removing app restrictions before starting session...")
        removeAppRestrictions()

        isSessionActive = true
        isSessionPaused = false
        sessionTimeRemaining = TimeInterval(duration * 60)
        sessionTimeAllocated = TimeInterval(duration * 60)
        sessionTimeUsed = 0

        // Store absolute start and end times for background handling
        sessionStartTime = Date()
        sessionEndTime = Date().addingTimeInterval(TimeInterval(duration * 60))
        pausedTime = nil

        print("✅ Session state updated - \(duration) minutes allocated")
        print("⏰ Session will end at: \(sessionEndTime!)")

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.sessionTimeRemaining > 0 {
                    self.sessionTimeRemaining -= 1
                    self.sessionTimeUsed += 1

                    // Deduct from minutesEarned every 60 seconds (1 minute)
                    if Int(self.sessionTimeUsed) % 60 == 0 && self.minutesEarned > 0 {
                        self.minutesEarned -= 1
                        print("⏱️ Minute elapsed - minutesEarned now: \(self.minutesEarned)")
                    }
                } else {
                    print("⏰ Session timer expired - ending session")
                    self.endSession()
                }
            }
        }
        print("⏱️ Session timer started successfully")
        logCurrentShieldStatus()
        print("🚀 ============ SESSION STARTED SUCCESSFULLY ============")
    }
    
    func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil

        // Calculate any remaining partial minute to deduct
        let totalSecondsUsed = Int(sessionTimeUsed)
        let remainingSeconds = totalSecondsUsed % 60

        // If there's a partial minute used (e.g., 30 seconds), deduct one more minute
        if remainingSeconds > 0 && minutesEarned > 0 {
            minutesEarned -= 1
            print("⏱️ Deducting partial minute (used \(remainingSeconds) seconds)")
        }

        let minutesUsed = Int(ceil(sessionTimeUsed / 60.0))

        // Reset session state
        isSessionActive = false
        isSessionPaused = false
        sessionTimeRemaining = 0
        sessionTimeAllocated = 0
        sessionTimeUsed = 0

        // Clear timestamps
        sessionStartTime = nil
        sessionEndTime = nil
        pausedTime = nil

        startAppRestrictions()
        print("Session ended. Used \(minutesUsed) minutes, \(minutesEarned) minutes remaining")
    }
    
    func pauseSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        sessionWarningTimer?.invalidate()
        sessionWarningTimer = nil

        // Mark session as paused instead of ending
        isSessionActive = false
        isSessionPaused = true
        pausedTime = Date()
        // Keep sessionTimeRemaining and sessionTimeUsed values

        startAppRestrictions()
        print("Session paused. Used \(Int(sessionTimeUsed / 60)) minutes so far, \(Int(sessionTimeRemaining / 60)) minutes remaining")
    }

    func resumeSession() {
        guard isSessionPaused, sessionTimeRemaining > 0 else { return }

        removeAppRestrictions()
        isSessionActive = true
        isSessionPaused = false

        // Adjust end time based on how long we were paused
        if let paused = pausedTime {
            let pauseDuration = Date().timeIntervalSince(paused)
            sessionEndTime = sessionEndTime?.addingTimeInterval(pauseDuration)
        }
        pausedTime = nil

        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.sessionTimeRemaining > 0 {
                    self.sessionTimeRemaining -= 1
                    self.sessionTimeUsed += 1

                    // Deduct from minutesEarned every 60 seconds (1 minute)
                    if Int(self.sessionTimeUsed) % 60 == 0 && self.minutesEarned > 0 {
                        self.minutesEarned -= 1
                        print("⏱️ Minute elapsed - minutesEarned now: \(self.minutesEarned)")
                    }
                } else {
                    self.endSession()
                }
            }
        }
        print("Session resumed. \(Int(sessionTimeRemaining / 60)) minutes remaining")
    }

    // MARK: - Session Time Synchronization
    func syncSessionTime() {
        // Only sync if session is active (not paused)
        guard isSessionActive, let endTime = sessionEndTime else { return }

        let now = Date()

        // Check if session has expired
        if now >= endTime {
            print("⏰ Session expired while app was in background - ending session")
            endSession()
            return
        }

        // Calculate actual time remaining based on wall-clock time
        let actualTimeRemaining = endTime.timeIntervalSince(now)
        let timeDifference = abs(sessionTimeRemaining - actualTimeRemaining)

        // Only update if there's a significant difference (more than 2 seconds)
        if timeDifference > 2 {
            print("🔄 Syncing session time: was \(Int(sessionTimeRemaining))s, now \(Int(actualTimeRemaining))s")

            // Update time used based on how much actually elapsed
            if let startTime = sessionStartTime {
                let totalElapsed = now.timeIntervalSince(startTime)
                sessionTimeUsed = totalElapsed
            }

            sessionTimeRemaining = actualTimeRemaining
        }
    }

    // MARK: - Failsafe and Cleanup
    func ensureAppsAreBlocked() {
        // Sync session timer first if active
        syncSessionTime()

        // Failsafe: If no session is active or paused, ensure apps are blocked
        if !isSessionActive && !isSessionPaused {
            print("🔒 Ensuring apps are blocked (failsafe)")
            startAppRestrictions()
        }
    }

    // MARK: - Debug and Status Functions
    func logCurrentShieldStatus() {
        print("\n📊 CURRENT SHIELD STATUS:")
        print("📊 Authorization Status: \(authorizationStatus)")
        print("📊 Is Authorized: \(isAuthorized)")
        print("📊 Is Session Active: \(isSessionActive)")
        print("📊 Is Session Paused: \(isSessionPaused)")
        print("📊 Minutes Earned: \(minutesEarned)")

        let selection = appSelectionStore.familyActivitySelection
        print("📊 Selected Apps: \(selection.applicationTokens.count)")
        print("📊 Selected Categories: \(selection.categoryTokens.count)")
        print("📊 Selected Websites: \(selection.webDomainTokens.count)")

        if isSessionActive {
            print("📊 Session Time Remaining: \(Int(sessionTimeRemaining / 60)) minutes")
            print("📊 Session Time Used: \(Int(sessionTimeUsed / 60)) minutes")
        }
        print("📊 ===================\n")
    }

    // MARK: - Friend Activity Simulation
    func simulateFriendActivity() {
        guard !friends.isEmpty else {
            // Add some friends first if none exist
            let mockFriend = allUsers.first { user in !friends.contains(where: { $0.username == user.username }) }
            if let friend = mockFriend {
                friends.append(friend)
            }
            return
        }

        let friend = friends.randomElement()!
        let activities = [
            "Completed a morning run",
            "Finished homework early",
            "Helped with household chores",
            "Practiced guitar for 30 minutes",
            "Read a chapter of a book"
        ]

        let activity = activities.randomElement()!
        let xpEarned = Int.random(in: 15...35)

        notificationManager.sendFriendCompletedTaskNotification(
            friendName: friend.username,
            taskTitle: activity,
            xpEarned: xpEarned,
            hasPhoto: Bool.random()
        )

        // Also add to the activity feed
        let friendActivity = FriendActivity(
            userId: friend.id.uuidString,
            username: friend.username,
            activity: activity,
            xpEarned: xpEarned,
            timestamp: Date(),
            kudos: 0,
            hasVerificationPhoto: Bool.random(),
            verificationPhoto: nil
        )

        friendActivities.insert(friendActivity, at: 0)
    }

    // MARK: - Social Feed Integration

    func createSocialPost(with image: UIImage, taskTitle: String, xpEarned: Int) {
        print("📱 Creating social post for task: \(taskTitle)")

        // Create activity for current user
        let userActivity = FriendActivity(
            userId: currentUser.id.uuidString,
            username: currentUser.username,
            activity: taskTitle,
            xpEarned: xpEarned,
            timestamp: Date(),
            kudos: 0,
            hasVerificationPhoto: true,
            verificationPhoto: image
        )

        // Add to the top of friend activities (social feed)
        DispatchQueue.main.async {
            self.friendActivities.insert(userActivity, at: 0)
            print("✅ Social post created successfully")
        }

        // Send notification to friends
        notificationManager.sendFriendCompletedTaskNotification(
            friendName: currentUser.username,
            taskTitle: taskTitle,
            xpEarned: xpEarned,
            hasPhoto: true
        )

        // Simulate friends seeing the post (for demo purposes)
        simulateFriendEngagement(for: userActivity)
    }

    private func simulateFriendEngagement(for activity: FriendActivity) {
        // Simulate some friends giving kudos after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...10)) {
            if let index = self.friendActivities.firstIndex(where: { $0.id == activity.id }) {
                let newKudos = Int.random(in: 1...3)
                let updatedActivity = FriendActivity(
                    userId: activity.userId,
                    username: activity.username,
                    activity: activity.activity,
                    xpEarned: activity.xpEarned,
                    timestamp: activity.timestamp,
                    kudos: activity.kudos + newKudos,
                    hasVerificationPhoto: activity.hasVerificationPhoto,
                    verificationPhoto: activity.verificationPhoto
                )

                self.friendActivities[index] = updatedActivity
                print("👍 Friends gave \(newKudos) kudos to your post!")
            }
        }
    }

    func refreshSocialFeed() {
        // Refresh social feed - for now load mock data
        print("🔄 Refreshing social feed...")
        loadMockSocialPosts()
    }

    private func loadMockSocialPosts() {
        // Create some mock social posts for testing
        let mockPosts = [
            SocialPost(
                userId: "user1",
                userName: "Alex Johnson",
                userAvatar: nil,
                taskId: UUID(),
                taskTitle: "Clean my room",
                taskDescription: "Organized closet and made bed",
                completionTime: Date().addingTimeInterval(-3600), // 1 hour ago
                xpEarned: 25,
                photoFileName: "mock_photo_1.jpg",
                likes: 12,
                downvotes: 1,
                comments: []
            ),
            SocialPost(
                userId: "user2",
                userName: "Sarah Smith",
                userAvatar: nil,
                taskId: UUID(),
                taskTitle: "Morning exercise",
                taskDescription: "30 minute jog around the park",
                completionTime: Date().addingTimeInterval(-7200), // 2 hours ago
                xpEarned: 35,
                photoFileName: "mock_photo_2.jpg",
                likes: 8,
                downvotes: 0,
                comments: []
            )
        ]

        socialPosts = mockPosts
    }

    func createSocialPostFromTask(task: TaskItem, photo: UIImage?, xpEarned: Int) {
        print("📱 Creating social post for completed task: \(task.title)")

        // Save the photo and get filename (if photo exists OR if task has verification photo)
        let photoFileName: String?
        if let photo = photo {
            photoFileName = saveTaskPhoto(photo, taskTitle: task.title)
            print("💾 Photo saved with filename: \(photoFileName ?? "none")")
        } else if task.verificationPhoto != nil {
            // Task has a verification photo, indicate this in the social post
            photoFileName = "task_verification_photo"
            print("💾 Social post created with existing task verification photo")
        } else {
            photoFileName = nil
            print("📝 Social post created without photo")
        }

        // Create social post
        let socialPost = SocialPost(
            userId: currentUser.id.uuidString,
            userName: currentUser.username,
            userAvatar: nil,
            taskId: task.id,
            taskTitle: task.title,
            taskDescription: nil,
            completionTime: Date(),
            xpEarned: xpEarned,
            photoFileName: photoFileName,
            likes: 0,
            downvotes: 0,
            comments: []
        )

        // Add to social feed at the top
        DispatchQueue.main.async {
            self.socialPosts.insert(socialPost, at: 0)
            print("✅ Social post created and added to feed (total posts: \(self.socialPosts.count))")
        }
    }

    private func saveTaskPhoto(_ image: UIImage, taskTitle: String) -> String {
        // Create a unique filename for the task photo
        let fileName = "task_\(Date().timeIntervalSince1970)_\(taskTitle.replacingOccurrences(of: " ", with: "_")).jpg"

        // For now, just return the filename - in a real app you'd save to disk
        // The actual image saving logic would go here
        print("📸 Saving task photo as: \(fileName)")

        return fileName
    }

    func deleteSocialPost(withId postId: UUID) {
        DispatchQueue.main.async {
            self.socialPosts.removeAll { $0.id == postId }
            print("🗑️ Deleted social post with ID: \(postId)")
        }
    }

    func editSocialPost(withId postId: UUID, newTitle: String) {
        DispatchQueue.main.async {
            if let index = self.socialPosts.firstIndex(where: { $0.id == postId }) {
                self.socialPosts[index].taskTitle = newTitle
                print("✏️ Edited social post: \(newTitle)")
            }
        }
    }
}

// MARK: - Location Tracking View
// MARK: - Friend Map View (Removed - Location tracking disabled)
struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isPresented: Bool
    let taskTitle: String
    let taskId: UUID?
    let onPhotoTaken: (UIImage, UIImage?) -> Void // (backImage, frontImage)
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.cameraManager = cameraManager
        controller.taskTitle = taskTitle
        controller.taskId = taskId
        controller.onPhotoTaken = onPhotoTaken
        controller.onDismiss = {
            isPresented = false
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var cameraManager: CameraManager?
    var taskTitle: String = ""
    var taskId: UUID?
    var onPhotoTaken: ((UIImage, UIImage?) -> Void)? // (backImage, frontImage)
    var onDismiss: (() -> Void)?

    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureButton: UIButton?
    private var retakeButton: UIButton?
    private var usePhotoButton: UIButton?
    private var imagePreviewView: UIImageView?
    private var blackTransitionView: UIView?
    private var frontOverlayImageView: UIImageView?

    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var isFlashOn = false
    private var isCapturing = false
    private var capturedRearImage: UIImage?
    private var capturedFrontImage: UIImage?
    private var isShowingPreview = false
    private var imageObserver: AnyCancellable?
    private var captureCompletionHandler: ((UIImage?, UIImage?) -> Void)? // (backImage, frontImage)

    // Video recording properties
    enum CaptureMode {
        case photo
        case video
    }
    private var captureMode: CaptureMode = .photo
    private var isRecording = false
    private var frontVideoOutput: AVCaptureMovieFileOutput?
    private var backVideoOutput: AVCaptureMovieFileOutput?
    private var frontVideoURL: URL?
    private var backVideoURL: URL?
    private var recordingTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    private var progressLayer: CAShapeLayer?
    private var outerRingView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // Camera manager already initialized in its init() method
        print("📱 [Camera VC] viewDidLoad started")
        print("   Camera manager exists: \(cameraManager != nil)")

        // Observe camera status to setup preview when ready
        setupCameraStatusObserver()

        // Check if camera is already ready (immediate check for race condition)
        if let status = cameraManager?.cameraStatus {
            print("   Camera status: \(status)")
            if status == .ready || status == .frontOnly || status == .backOnly {
                print("🔧 Camera already ready, setting up preview immediately...")
                setupCamera()
                debugCameraManagerState()
            } else if status == .initializing {
                print("⏳ Camera is still initializing, will wait for status change...")
            } else if status == .failed {
                print("❌ Camera initialization failed!")
                if let error = cameraManager?.cameraError {
                    print("   Error: \(error)")
                }
            }
        } else {
            print("⚠️ Camera status is nil")
        }
    }

    private func setupCameraStatusObserver() {
        // Observe when camera becomes ready
        print("📡 [Camera VC] Setting up camera status observer")
        cameraManager?.objectWillChange.sink { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Check if camera is ready and preview hasn't been set up yet
                let previewExists = self.cameraPreviewLayer != nil
                let status = self.cameraManager?.cameraStatus

                print("📡 [Camera VC] Status changed - Preview exists: \(previewExists), Status: \(status?.rawValue ?? "nil")")

                if self.cameraPreviewLayer == nil,
                   let status = self.cameraManager?.cameraStatus,
                   (status == .ready || status == .frontOnly || status == .backOnly) {
                    print("🔧 Camera is ready via observer, setting up preview...")
                    self.setupCamera()
                    self.debugCameraManagerState()
                }
            }
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func debugCameraManagerState() {
        guard let cameraManager = self.cameraManager else {
            print("❌ CameraManager is nil")
            return
        }

        print("🔍 Camera Manager Debug:")
        print("  - Front session: \(cameraManager.frontCaptureSession != nil)")
        print("  - Back session: \(cameraManager.backCaptureSession != nil)")
        print("  - Front output: \(cameraManager.frontPhotoOutput != nil)")
        print("  - Back output: \(cameraManager.backPhotoOutput != nil)")
        print("  - Front running: \(cameraManager.frontCaptureSession?.isRunning ?? false)")
        print("  - Back running: \(cameraManager.backCaptureSession?.isRunning ?? false)")
    }

    private func setupImageObserver() {
        // Observe captured image changes immediately for faster response
        self.imageObserver = self.cameraManager?.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }

                // Update UI based on capture phase
                self.updateUIForCapturePhase()

                // Handle completed capture
                if let capturedImage = self.cameraManager?.capturedImage,
                   !self.isShowingPreview,
                   capturedImage.size.width > 0 {
                    print("📸 Observer detected new captured image, showing preview")
                    self.showImagePreview(capturedImage)
                }
            }
        }
    }

    private func updateUIForCapturePhase() {
        guard let phase = cameraManager?.currentCapturePhase else { return }

        switch phase {
        case .readyForBack:
            captureButton?.setTitle("📸 Take Back Photo", for: .normal)
            captureButton?.backgroundColor = UIColor.systemBlue
            captureButton?.isEnabled = true
            // Status removed for clean UI
        case .capturingBack:
            captureButton?.setTitle("📸 Taking Back Photo...", for: .normal)
            captureButton?.backgroundColor = UIColor.systemOrange
            captureButton?.isEnabled = false
            // Status removed for clean UI
        case .readyForFront:
            captureButton?.setTitle("🤳 Take Front Photo", for: .normal)
            captureButton?.backgroundColor = UIColor.systemGreen
            captureButton?.isEnabled = true
            // Status removed for clean UI
        case .capturingFront:
            captureButton?.setTitle("🤳 Taking Front Photo...", for: .normal)
            captureButton?.backgroundColor = UIColor.systemOrange
            captureButton?.isEnabled = false
            // Status removed for clean UI
        case .completed:
            captureButton?.setTitle("✅ Photos Complete", for: .normal)
            captureButton?.backgroundColor = UIColor.systemGray
            captureButton?.isEnabled = false
            // Status removed for clean UI
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black

        // Single camera preview view (full screen)
        let cameraPreviewView = UIView()
        cameraPreviewView.translatesAutoresizingMaskIntoConstraints = false
        cameraPreviewView.tag = 200 // Tag for single camera preview
        cameraPreviewView.backgroundColor = .black
        view.addSubview(cameraPreviewView)

        // Close button (top-left) - Apple style with chevron
        let closeButton = UIButton(type: .system)
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        closeButton.setImage(UIImage(systemName: "chevron.down", withConfiguration: chevronConfig), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Flip camera button (top-right) - Apple style with icon
        let flipButton = UIButton(type: .system)
        let flipConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        flipButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera", withConfiguration: flipConfig), for: .normal)
        flipButton.tintColor = .white
        flipButton.translatesAutoresizingMaskIntoConstraints = false
        flipButton.addTarget(self, action: #selector(flipCameraButtonTapped), for: .touchUpInside)
        view.addSubview(flipButton)

        // Flash toggle button (top-left, below close) - Apple style
        let flashButton = UIButton(type: .system)
        let flashConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        flashButton.setImage(UIImage(systemName: "bolt.slash.fill", withConfiguration: flashConfig), for: .normal)
        flashButton.tintColor = .white
        flashButton.tag = 999 // Tag for easy access
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        view.addSubview(flashButton)

        // Apple-style capture button with outer ring
        let captureButtonContainer = UIView()
        captureButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButtonContainer)

        // Outer ring
        let outerRing = UIView()
        outerRing.backgroundColor = .clear
        outerRing.layer.borderColor = UIColor.white.cgColor
        outerRing.layer.borderWidth = 4
        outerRing.layer.cornerRadius = 40
        outerRing.translatesAutoresizingMaskIntoConstraints = false
        captureButtonContainer.addSubview(outerRing)
        self.outerRingView = outerRing

        // Inner white button
        let captureButton = UIButton(type: .custom)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 32
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        captureButtonContainer.addSubview(captureButton)
        self.captureButton = captureButton

        // Add constraints for capture button
        NSLayoutConstraint.activate([
            captureButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButtonContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButtonContainer.widthAnchor.constraint(equalToConstant: 80),
            captureButtonContainer.heightAnchor.constraint(equalToConstant: 80),

            outerRing.centerXAnchor.constraint(equalTo: captureButtonContainer.centerXAnchor),
            outerRing.centerYAnchor.constraint(equalTo: captureButtonContainer.centerYAnchor),
            outerRing.widthAnchor.constraint(equalToConstant: 80),
            outerRing.heightAnchor.constraint(equalToConstant: 80),

            captureButton.centerXAnchor.constraint(equalTo: captureButtonContainer.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: captureButtonContainer.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 64),
            captureButton.heightAnchor.constraint(equalToConstant: 64)
        ])

        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchToZoom(_:)))
        cameraPreviewView.addGestureRecognizer(pinchGesture)

        // Add tap gesture for focus
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus(_:)))
        cameraPreviewView.addGestureRecognizer(tapGesture)

        // Zoom indicator (like BeReal - "1x" button at bottom)
        let zoomLabel = UILabel()
        zoomLabel.text = "1×"
        zoomLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        zoomLabel.textColor = .white
        zoomLabel.textAlignment = .center
        zoomLabel.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        zoomLabel.layer.cornerRadius = 18
        zoomLabel.clipsToBounds = true
        zoomLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomLabel.tag = 888 // Tag for easy access
        view.addSubview(zoomLabel)

        // Mode selector removed temporarily - VIDEO feature will be added back later

        // Black transition view (initially hidden)
        let blackTransitionView = UIView()
        blackTransitionView.backgroundColor = .black
        blackTransitionView.isHidden = true
        blackTransitionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blackTransitionView)
        self.blackTransitionView = blackTransitionView

        // Final image preview (initially hidden)
        let imagePreviewView = UIImageView()
        imagePreviewView.contentMode = .scaleAspectFill
        imagePreviewView.backgroundColor = .black
        imagePreviewView.isHidden = true
        imagePreviewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imagePreviewView)
        self.imagePreviewView = imagePreviewView

        // Retake X button (top-left of final image)
        let retakeButton = UIButton(type: .system)
        retakeButton.setTitle("✕", for: .normal)
        retakeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        retakeButton.setTitleColor(.white, for: .normal)
        retakeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        retakeButton.layer.cornerRadius = 22
        retakeButton.isHidden = true
        retakeButton.translatesAutoresizingMaskIntoConstraints = false
        retakeButton.addTarget(self, action: #selector(retakeButtonTapped), for: .touchUpInside)
        view.addSubview(retakeButton)
        self.retakeButton = retakeButton

        // Use Photo button
        let usePhotoButton = UIButton(type: .system)
        usePhotoButton.setTitle("Use Photo", for: .normal)
        usePhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        usePhotoButton.backgroundColor = UIColor.white
        usePhotoButton.setTitleColor(.black, for: .normal)
        usePhotoButton.layer.cornerRadius = 25
        usePhotoButton.isHidden = true
        usePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        usePhotoButton.addTarget(self, action: #selector(usePhotoButtonTapped), for: .touchUpInside)
        view.addSubview(usePhotoButton)
        self.usePhotoButton = usePhotoButton

        NSLayoutConstraint.activate([
            // Full screen camera preview
            cameraPreviewView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraPreviewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Close button (top-left)
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            // Flip camera button (top-right)
            flipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            flipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flipButton.widthAnchor.constraint(equalToConstant: 44),
            flipButton.heightAnchor.constraint(equalToConstant: 44),

            // Flash button (top-center)
            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            flashButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44),

            // Zoom indicator label (bottom, above capture button)
            zoomLabel.bottomAnchor.constraint(equalTo: captureButtonContainer.topAnchor, constant: -20),
            zoomLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            zoomLabel.widthAnchor.constraint(equalToConstant: 50),
            zoomLabel.heightAnchor.constraint(equalToConstant: 36),

            // Black transition view (full screen)
            blackTransitionView.topAnchor.constraint(equalTo: view.topAnchor),
            blackTransitionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blackTransitionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blackTransitionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Final image preview (full screen)
            imagePreviewView.topAnchor.constraint(equalTo: view.topAnchor),
            imagePreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imagePreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imagePreviewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Retake button (top-left of final image)
            retakeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            retakeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            retakeButton.widthAnchor.constraint(equalToConstant: 44),
            retakeButton.heightAnchor.constraint(equalToConstant: 44),

            // Use Photo button
            usePhotoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            usePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usePhotoButton.widthAnchor.constraint(equalToConstant: 150),
            usePhotoButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupCamera() {
        print("🔧 Setting up BeReal-style camera...")

        // Add safety check for camera manager
        guard let cameraManager = self.cameraManager else {
            print("❌ Camera manager is nil")
            return
        }

        // Setup single camera system (starts with back camera)
        setupSingleCameraPreview(position: currentCameraPosition)
    }

    private func setupSingleCameraPreview(position: AVCaptureDevice.Position) {
        // Clean up existing preview layer
        cameraPreviewLayer?.removeFromSuperlayer()
        cameraPreviewLayer = nil

        // Get the correct session based on camera position
        let session: AVCaptureSession?
        if position == .back {
            session = cameraManager?.backCaptureSession
        } else {
            session = cameraManager?.frontCaptureSession
        }

        guard let captureSession = session,
              let previewView = view.subviews.first(where: { $0.tag == 200 }) else {
            print("❌ Could not setup camera preview - session or preview view missing")
            print("   Session exists: \(session != nil)")
            print("   Preview view exists: \(view.subviews.first(where: { $0.tag == 200 }) != nil)")
            return
        }

        print("🔧 Creating preview layer for \(position == .back ? "rear" : "front") camera")
        print("   Preview view frame: \(previewView.frame)")
        print("   Preview view bounds: \(previewView.bounds)")

        // Create and setup preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = previewView.bounds  // FIX: Use previewView.bounds, not view.bounds

        previewView.layer.addSublayer(previewLayer)
        self.cameraPreviewLayer = previewLayer

        print("   Preview layer frame: \(previewLayer.frame)")

        // Start the session if not already running
        if !captureSession.isRunning {
            print("📷 Starting capture session...")
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("   Session running: \(captureSession.isRunning)")
                }
            }
        } else {
            print("   Session already running")
        }

        print("✅ Single camera preview setup complete for \(position == .back ? "rear" : "front") camera")
    }

    // Old setupPreviewLayers method removed - replaced with setupSingleCameraPreview
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // If camera is already ready but preview wasn't set up, set it up now
        if cameraPreviewLayer == nil,
           let status = cameraManager?.cameraStatus,
           (status == .ready || status == .frontOnly || status == .backOnly) {
            print("🔧 Camera already ready in viewDidAppear, setting up preview...")
            setupCamera()
        }

        // Update preview layer frames when view appears to handle rotation/resize
        DispatchQueue.main.async {
            self.updatePreviewLayerFrames()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update frames when layout changes
        updatePreviewLayerFrames()
    }

    private func updatePreviewLayerFrames() {
        // Update single camera preview layer frame
        if let previewLayer = cameraPreviewLayer,
           let previewView = view.subviews.first(where: { $0.tag == 200 }) {
            previewLayer.frame = previewView.bounds
        }
    }

    // updateCameraStatus method removed

    // checkFinalCameraStatus method removed

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraManager?.stopCameraSession()
        imageObserver?.cancel()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraManager?.stopCameraSession()
    }
    
    @objc private func captureButtonTapped() {
        print("🔘 Photo capture initiated")

        // Add instant haptic feedback on button press
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        // Animate button press like native iOS camera
        UIView.animate(withDuration: 0.1, animations: {
            self.captureButton?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.captureButton?.transform = .identity
            }
        }

        startBeRealCapture()
    }

    private func startBeRealCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        // Step 1: Capture main camera (whatever is currently shown)
        let mainCameraPosition = currentCameraPosition
        let otherCameraPosition: AVCaptureDevice.Position = mainCameraPosition == .back ? .front : .back

        captureSpecificCamera(position: mainCameraPosition) { [weak self] mainImage in
            guard let self = self, let mainImage = mainImage else {
                self?.isCapturing = false
                return
            }

            print("📸 Main camera (\(mainCameraPosition == .back ? "rear" : "front")) captured successfully")

            // Step 2: Show black screen for 1 second
            self.showBlackScreen {
                // Step 3: Auto-capture other camera
                self.captureSpecificCamera(position: otherCameraPosition) { otherImage in
                    guard let otherImage = otherImage else {
                        print("❌ Other camera capture failed")
                        self.isCapturing = false
                        return
                    }

                    print("📸 Other camera (\(otherCameraPosition == .back ? "rear" : "front")) captured successfully")

                    // Step 4: Assign images based on roles
                    if mainCameraPosition == .back {
                        // Normal: rear main, front overlay
                        self.capturedRearImage = mainImage
                        self.capturedFrontImage = otherImage
                    } else {
                        // Flipped: front main, rear overlay
                        self.capturedFrontImage = mainImage
                        self.capturedRearImage = otherImage
                    }

                    // Step 5: Show final combined result
                    self.showFinalResult()
                }
            }
        }
    }

    private func captureSpecificCamera(position: AVCaptureDevice.Position, completion: @escaping (UIImage?) -> Void) {
        guard let cameraManager = self.cameraManager else {
            print("❌ CameraManager is nil")
            completion(nil)
            return
        }

        // Handle simulator mode - generate mock images instantly
        #if targetEnvironment(simulator)
        print("🤖 Simulator mode: generating mock \(position == .back ? "rear" : "front") camera image")
        let mockImage = self.createMockImage(text: "\(position == .back ? "Rear" : "Front") Camera\nMock Photo", backgroundColor: position == .back ? .systemBlue : .systemGreen)
        completion(mockImage)
        return
        #endif

        // Get the correct session and output for the specified camera position
        let session = position == .back ? cameraManager.backCaptureSession : cameraManager.frontCaptureSession
        let photoOutput = position == .back ? cameraManager.backPhotoOutput : cameraManager.frontPhotoOutput

        print("🔍 Debug - Session available: \(session != nil), Output available: \(photoOutput != nil), Session running: \(session?.isRunning ?? false)")

        guard let captureSession = session,
              let output = photoOutput else {
            print("❌ Camera session or output not available for \(position == .back ? "rear" : "front") camera")
            completion(nil)
            return
        }

        // Ensure session is running
        if !captureSession.isRunning {
            print("🔄 Starting \(position == .back ? "rear" : "front") camera session...")
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                // Retry capture immediately after starting session
                DispatchQueue.main.async {
                    self.captureSpecificCamera(position: position, completion: completion)
                }
            }
            return
        }

        let settings = AVCapturePhotoSettings()

        // Configure flash (only for rear camera, front camera typically doesn't have flash)
        if isFlashOn && position == .back && output.supportedFlashModes.contains(.on) {
            settings.flashMode = .on
        }

        print("📷 Capturing \(position == .back ? "rear" : "front") camera with session running: \(captureSession.isRunning)")
        print("🔍 Photo output available connections: \(output.connections.count)")
        print("🔍 Photo output can capture: \(output.isHighResolutionCaptureEnabled)")

        // Store completion handler BEFORE capture
        // Wrap single-image completion in a closure that ignores second parameter
        self.captureCompletionHandler = { image, _ in
            completion(image)
        }
        print("🔍 Completion handler stored, delegate is: \(type(of: self))")

        // Capture the photo with additional error checking
        print("📷 About to call capturePhoto...")
        output.capturePhoto(with: settings, delegate: self)
        print("📷 capturePhoto call completed")
    }

    private func createMockImage(text: String, backgroundColor: UIColor) -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func showBlackScreen(completion: @escaping () -> Void) {
        print("⚫ Showing black screen transition")

        DispatchQueue.main.async {
            // Show black screen with flash effect (instant feedback)
            self.blackTransitionView?.isHidden = false

            // Add haptic feedback for capture
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            // Quick transition (0.3s instead of 1s for faster UX)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.blackTransitionView?.isHidden = true
                completion()
            }
        }
    }

    // autoCaptureFrontCamera method removed - replaced with captureSpecificCamera

    private func showFinalResult() {
        print("🎉 Showing final BeReal-style result")

        // Determine which image should be main based on current camera position
        let mainImage: UIImage?
        let overlayImage: UIImage?

        if currentCameraPosition == .back {
            // Normal: rear main, front overlay
            mainImage = capturedRearImage
            overlayImage = capturedFrontImage
            print("📸 Final result: Rear main, Front overlay")
        } else {
            // Flipped: front main, rear overlay
            mainImage = capturedFrontImage
            overlayImage = capturedRearImage
            print("📸 Final result: Front main, Rear overlay")
        }

        guard let main = mainImage else {
            print("❌ No main image available")
            return
        }

        DispatchQueue.main.async {
            // Show main image immediately for instant feedback
            self.imagePreviewView?.image = main
            self.imagePreviewView?.isHidden = false

            // Add haptic feedback for successful capture
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Add overlay with quick animation (0.2s delay instead of 3s total)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.addOverlayCameraWithAnimation(overlayImage: overlayImage)

                // Show the retake and use photo buttons
                self.showFinalButtons()

                self.isCapturing = false
            }
        }
    }

    private func addOverlayCameraWithAnimation(overlayImage: UIImage?) {
        guard let overlayImage = overlayImage else { return }

        // Create overlay camera if it doesn't exist
        if frontOverlayImageView == nil {
            let overlayImageView = UIImageView()
            overlayImageView.contentMode = .scaleAspectFill
            overlayImageView.layer.cornerRadius = 10
            overlayImageView.layer.borderColor = UIColor.white.cgColor
            overlayImageView.layer.borderWidth = 3
            overlayImageView.clipsToBounds = true
            overlayImageView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(overlayImageView)
            frontOverlayImageView = overlayImageView

            // Position in top-right corner
            NSLayoutConstraint.activate([
                overlayImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                overlayImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                overlayImageView.widthAnchor.constraint(equalToConstant: 120),
                overlayImageView.heightAnchor.constraint(equalToConstant: 160)
            ])
        }

        // Set the overlay image (could be front or rear depending on flip state)
        frontOverlayImageView?.image = overlayImage

        // Slide in animation from the right
        frontOverlayImageView?.transform = CGAffineTransform(translationX: 200, y: 0)
        frontOverlayImageView?.alpha = 0

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
            self.frontOverlayImageView?.transform = .identity
            self.frontOverlayImageView?.alpha = 1
        }
    }

    private func showFinalButtons() {
        DispatchQueue.main.async {
            self.retakeButton?.isHidden = false
            self.usePhotoButton?.isHidden = false
        }
    }
    
    
    private func takePictureNow() {
        print("📸 takePictureNow called")

        // Add safety checks before attempting capture
        guard let cameraManager = cameraManager else {
            print("❌ Camera manager not available")
            // Status removed
            return
        }

        // Check camera status
        switch cameraManager.cameraStatus {
        case .ready, .frontOnly, .backOnly:
            break // OK to proceed
        case .initializing:
            print("⚠️ Camera still initializing")
            // Status removed
            return
        case .failed:
            print("❌ Camera failed, reinitializing...")
            // Status removed
            cameraManager.setupDualCameraSystem()
            return
        case .capturing:
            print("⚠️ Already capturing")
            return
        }

        // Disable capture button temporarily
        captureButton?.isEnabled = false
        // Status removed

        // Attempt sequential capture
        cameraManager.takeSequentialPhoto()

        // Show flash effect
        showFlashEffect()

        // Re-enable button after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.captureButton?.isEnabled = true
            if cameraManager.cameraError == nil {
                // Status removed
            }
        }
    }

    private func showFlashEffect() {
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = .white
        flashView.alpha = 0
        view.addSubview(flashView)

        UIView.animate(withDuration: 0.1, animations: {
            flashView.alpha = 0.8
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                flashView.alpha = 0
            }, completion: { _ in
                flashView.removeFromSuperview()
            })
        })
    }
    
    @objc private func closeButtonTapped() {
        print("🔘 Close button tapped - dismissing BeReal camera")
        onDismiss?()
    }

    // MARK: - Mode Switching

    @objc private func switchToVideoMode() {
        guard captureMode != .video else { return }
        print("📹 Switching to VIDEO mode")

        captureMode = .video

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Update UI
        UIView.animate(withDuration: 0.2) {
            // Change capture button to red
            self.captureButton?.backgroundColor = .systemRed

            // Update mode button styles
            if let videoButton = self.view.viewWithTag(777) as? UIButton {
                videoButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
                videoButton.setTitleColor(.white, for: .normal)
            }
            if let photoButton = self.view.viewWithTag(666) as? UIButton {
                photoButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                photoButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
            }
        }

        // Setup video outputs if not already configured
        setupVideoOutputs()
    }

    @objc private func switchToPhotoMode() {
        guard captureMode != .photo else { return }
        print("📸 Switching to PHOTO mode")

        captureMode = .photo

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Update UI
        UIView.animate(withDuration: 0.2) {
            // Change capture button to white
            self.captureButton?.backgroundColor = .white

            // Update mode button styles
            if let videoButton = self.view.viewWithTag(777) as? UIButton {
                videoButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                videoButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
            }
            if let photoButton = self.view.viewWithTag(666) as? UIButton {
                photoButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
                photoButton.setTitleColor(.white, for: .normal)
            }
        }
    }

    // MARK: - Video Recording Setup

    private func setupVideoOutputs() {
        guard let cameraManager = cameraManager else {
            print("❌ Camera manager is nil")
            return
        }

        print("🔧 Setting up video outputs...")

        DispatchQueue.main.async {
            // Setup front video output
            if let frontSession = cameraManager.frontCaptureSession {
                if self.frontVideoOutput == nil {
                    let frontOutput = AVCaptureMovieFileOutput()

                    // Set max duration
                    frontOutput.maxRecordedDuration = CMTime(seconds: 30, preferredTimescale: 1)

                    frontSession.beginConfiguration()
                    if frontSession.canAddOutput(frontOutput) {
                        frontSession.addOutput(frontOutput)
                        self.frontVideoOutput = frontOutput
                        print("✅ Front video output configured")
                    } else {
                        print("❌ Cannot add front video output")
                    }
                    frontSession.commitConfiguration()
                } else {
                    print("ℹ️ Front video output already exists")
                }
            } else {
                print("❌ Front capture session not available")
            }

            // Setup back video output
            if let backSession = cameraManager.backCaptureSession {
                if self.backVideoOutput == nil {
                    let backOutput = AVCaptureMovieFileOutput()

                    // Set max duration
                    backOutput.maxRecordedDuration = CMTime(seconds: 30, preferredTimescale: 1)

                    backSession.beginConfiguration()
                    if backSession.canAddOutput(backOutput) {
                        backSession.addOutput(backOutput)
                        self.backVideoOutput = backOutput
                        print("✅ Back video output configured")
                    } else {
                        print("❌ Cannot add back video output")
                    }
                    backSession.commitConfiguration()
                } else {
                    print("ℹ️ Back video output already exists")
                }
            } else {
                print("❌ Back capture session not available")
            }
        }
    }

    // MARK: - Video Recording

    private func startVideoRecording() {
        guard !isRecording else {
            print("⚠️ Already recording")
            return
        }

        print("🎥 Attempting to start video recording...")

        // Ensure video outputs are set up
        if frontVideoOutput == nil || backVideoOutput == nil {
            print("⚠️ Video outputs not ready, setting up now...")
            setupVideoOutputs()

            // Try again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startVideoRecording()
            }
            return
        }

        guard let frontOutput = frontVideoOutput,
              let backOutput = backVideoOutput else {
            print("❌ Video outputs still not available")
            return
        }

        // Check if outputs are recording already
        if frontOutput.isRecording || backOutput.isRecording {
            print("⚠️ Outputs already recording")
            return
        }

        isRecording = true
        recordingDuration = 0

        // Animate button to recording state (rounded square like iOS)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.captureButton?.layer.cornerRadius = 8 // Square with rounded corners
            self.captureButton?.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }

        // Generate unique file URLs
        let frontURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("front_\(UUID().uuidString)")
            .appendingPathExtension("mov")
        let backURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("back_\(UUID().uuidString)")
            .appendingPathExtension("mov")

        // Remove files if they exist
        try? FileManager.default.removeItem(at: frontURL)
        try? FileManager.default.removeItem(at: backURL)

        self.frontVideoURL = frontURL
        self.backVideoURL = backURL

        print("📁 Front video will be saved to: \(frontURL.lastPathComponent)")
        print("📁 Back video will be saved to: \(backURL.lastPathComponent)")

        // Ensure sessions are running
        guard let frontSession = cameraManager?.frontCaptureSession,
              let backSession = cameraManager?.backCaptureSession,
              frontSession.isRunning,
              backSession.isRunning else {
            print("❌ Camera sessions not running")
            isRecording = false
            return
        }

        // Start recording both cameras
        print("🎬 Starting front camera recording...")
        frontOutput.startRecording(to: frontURL, recordingDelegate: self)

        print("🎬 Starting back camera recording...")
        backOutput.startRecording(to: backURL, recordingDelegate: self)

        // Start progress animation
        startRecordingProgressAnimation()

        // Start timer for duration tracking and auto-stop at 30s
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1

            // Auto-stop at 30 seconds
            if self.recordingDuration >= 30.0 {
                self.stopVideoRecording()
            }
        }

        print("✅ Video recording started successfully")
    }

    private func stopVideoRecording() {
        guard isRecording else { return }

        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Animate button back to normal state
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.captureButton?.layer.cornerRadius = 32 // Back to circle
            self.captureButton?.transform = .identity
        }

        // Stop recording both cameras
        frontVideoOutput?.stopRecording()
        backVideoOutput?.stopRecording()

        // Remove progress animation
        stopRecordingProgressAnimation()

        print("🎥 Stopped video recording at \(recordingDuration)s")
    }

    private func startRecordingProgressAnimation() {
        guard let outerRing = outerRingView else { return }

        // Create circular progress layer
        let progressLayer = CAShapeLayer()
        let circularPath = UIBezierPath(
            arcCenter: CGPoint(x: 40, y: 40),
            radius: 38,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )

        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = UIColor.systemRed.cgColor
        progressLayer.lineWidth = 4
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        outerRing.layer.addSublayer(progressLayer)
        self.progressLayer = progressLayer

        // Animate stroke end from 0 to 1 over 30 seconds
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = 1
        animation.duration = 30
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        progressLayer.add(animation, forKey: "progressAnimation")
    }

    private func stopRecordingProgressAnimation() {
        progressLayer?.removeFromSuperlayer()
        progressLayer = nil
    }

    @objc private func flipCameraButtonTapped() {
        print("🔄 Flip camera button tapped")

        // Add haptic feedback for camera flip
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        setupSingleCameraPreview(position: currentCameraPosition)
    }

    @objc private func flashButtonTapped() {
        print("⚡ Flash button tapped")

        // Add haptic feedback for flash toggle
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        isFlashOn.toggle()

        // Update flash icon with proper SF Symbol
        if let flashButton = view.viewWithTag(999) as? UIButton {
            let flashConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            let iconName = isFlashOn ? "bolt.fill" : "bolt.slash.fill"
            flashButton.setImage(UIImage(systemName: iconName, withConfiguration: flashConfig), for: .normal)
            flashButton.tintColor = isFlashOn ? .yellow : .white
        }

        configureFlash()
    }

    private func configureFlash() {
        // Configure flash for current camera position
        guard let cameraManager = self.cameraManager else { return }

        let session = currentCameraPosition == .back ? cameraManager.backCaptureSession : cameraManager.frontCaptureSession

        guard let session = session else { return }

        // Configure flash settings based on current state
        // This will be applied during capture
        print("Flash configured: \(isFlashOn ? "ON" : "OFF") for \(currentCameraPosition == .back ? "rear" : "front") camera")
    }

    // MARK: - Gesture Handlers

    @objc private func handlePinchToZoom(_ gesture: UIPinchGestureRecognizer) {
        guard let cameraManager = self.cameraManager else { return }

        let camera = currentCameraPosition == .back ? cameraManager.backCamera : cameraManager.frontCamera
        guard let device = camera else { return }

        do {
            try device.lockForConfiguration()

            let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0)
            let currentZoom = device.videoZoomFactor

            if gesture.state == .changed {
                let pinchVelocity = gesture.velocity
                var newZoom = currentZoom + (pinchVelocity > 0 ? 0.05 : -0.05)
                newZoom = min(max(newZoom, 1.0), maxZoom)

                device.videoZoomFactor = newZoom

                // Update zoom label
                if let zoomLabel = view.viewWithTag(888) as? UILabel {
                    zoomLabel.text = String(format: "%.1f×", newZoom)
                }

                // Haptic feedback on zoom change
                if abs(newZoom - currentZoom) > 0.1 {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }

            device.unlockForConfiguration()
        } catch {
            print("❌ Error configuring zoom: \(error)")
        }
    }

    @objc private func handleTapToFocus(_ gesture: UITapGestureRecognizer) {
        guard let cameraManager = self.cameraManager else { return }

        let camera = currentCameraPosition == .back ? cameraManager.backCamera : cameraManager.frontCamera
        guard let device = camera else { return }

        let touchPoint = gesture.location(in: view)
        let focusPoint = CGPoint(x: touchPoint.x / view.bounds.width, y: touchPoint.y / view.bounds.height)

        do {
            try device.lockForConfiguration()

            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }

            device.unlockForConfiguration()

            // Visual feedback for tap-to-focus
            showFocusIndicator(at: touchPoint)

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            print("📍 Focus set at: \(focusPoint)")
        } catch {
            print("❌ Error configuring focus: \(error)")
        }
    }

    private func showFocusIndicator(at point: CGPoint) {
        // Create focus indicator square
        let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        focusView.center = point
        focusView.layer.borderColor = UIColor.yellow.cgColor
        focusView.layer.borderWidth = 2
        focusView.alpha = 0
        view.addSubview(focusView)

        // Animate indicator
        UIView.animate(withDuration: 0.3, animations: {
            focusView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, animations: {
                focusView.alpha = 0
            }) { _ in
                focusView.removeFromSuperview()
            }
        }
    }

    private func showImagePreview(_ image: UIImage) {
        print("📸 Showing image preview")
        isShowingPreview = true

        // Add timestamp watermark
        let timestampedImage = cameraManager?.addTimestampWatermark(to: image, taskTitle: taskTitle) ?? image

        // Show the captured image
        imagePreviewView?.image = timestampedImage
        imagePreviewView?.isHidden = false

        // Hide camera preview elements
        captureButton?.isHidden = true

        // Show preview action buttons
        retakeButton?.isHidden = false
        usePhotoButton?.isHidden = false
    }

    @objc private func retakeButtonTapped() {
        print("🔄 Retaking BeReal-style photo")
        isShowingPreview = false

        // Hide all preview UI
        imagePreviewView?.isHidden = true
        imagePreviewView?.image = nil
        frontOverlayImageView?.removeFromSuperview()
        frontOverlayImageView = nil

        // Clear captured images
        capturedRearImage = nil
        capturedFrontImage = nil
        isCapturing = false

        // Show camera preview elements
        captureButton?.isHidden = false

        // Hide preview action buttons
        retakeButton?.isHidden = true
        usePhotoButton?.isHidden = true

        // Keep current camera position (preserve flip state)
        setupSingleCameraPreview(position: currentCameraPosition)
    }

    @objc private func usePhotoButtonTapped() {
        print("✅ Use photo button tapped - Passing back and front images separately")

        guard let rearImage = capturedRearImage,
              let frontImage = capturedFrontImage else {
            print("❌ Missing captured images")
            return
        }

        // Add timestamp watermark to rear (back) image only
        let watermarkedBackImage = cameraManager?.addTimestampWatermark(to: rearImage, taskTitle: taskTitle) ?? rearImage

        print("🔥🔥🔥 CameraViewController: Calling onPhotoTaken with separate back and front images")
        onPhotoTaken?(watermarkedBackImage, frontImage)

        // Automatically dismiss camera after photo is accepted
        print("🚪 Auto-dismissing camera after Use Photo")
        onDismiss?()
    }

    private func createBeRealStyleImage(rearImage: UIImage, frontImage: UIImage) -> UIImage {
        // Determine main and overlay images based on flip state
        let mainImage: UIImage
        let overlayImage: UIImage

        if currentCameraPosition == .back {
            // Normal: rear main, front overlay
            mainImage = rearImage
            overlayImage = frontImage
        } else {
            // Flipped: front main, rear overlay
            mainImage = frontImage
            overlayImage = rearImage
        }

        let renderer = UIGraphicsImageRenderer(size: mainImage.size)

        return renderer.image { context in
            // Draw main image (full background)
            mainImage.draw(at: .zero)

            // Calculate overlay size and position (top-right)
            let overlaySize = CGSize(
                width: mainImage.size.width * 0.25,
                height: mainImage.size.height * 0.25
            )

            let overlayRect = CGRect(
                x: mainImage.size.width - overlaySize.width - 20,
                y: 20,
                width: overlaySize.width,
                height: overlaySize.height
            )

            // Draw white border for overlay
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setLineWidth(4)
            context.cgContext.stroke(overlayRect.insetBy(dx: -2, dy: -2))

            // Draw overlay image
            overlayImage.draw(in: overlayRect)
        }
    }
}

// MARK: - CameraViewController Photo Delegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📷 CameraViewController photo delegate called - Thread: \(Thread.current)")

        if let error = error {
            print("❌ Photo capture error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.captureCompletionHandler?(nil, nil)
                self.captureCompletionHandler = nil
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to process photo data")
            DispatchQueue.main.async {
                self.captureCompletionHandler?(nil, nil)
                self.captureCompletionHandler = nil
            }
            return
        }

        print("✅ Photo captured successfully - Size: \(image.size)")

        // Call the completion handler with the captured image on main thread
        // This is single camera, so second parameter is nil
        DispatchQueue.main.async {
            self.captureCompletionHandler?(image, nil)
            self.captureCompletionHandler = nil
        }
    }
}

// MARK: - CameraViewController Video Delegate
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("✅ 🎥 Started recording to: \(fileURL.lastPathComponent)")

        DispatchQueue.main.async {
            // Visual confirmation that recording started
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("❌ Video recording error: \(error.localizedDescription)")
            print("❌ Error domain: \((error as NSError).domain)")
            print("❌ Error code: \((error as NSError).code)")

            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            return
        }

        print("✅ Finished recording to: \(outputFileURL.lastPathComponent)")

        // Check file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: outputFileURL.path),
           let fileSize = attributes[.size] as? Int64 {
            print("📊 Video file size: \(fileSize / 1024) KB")
        }

        // Check if both videos are complete
        DispatchQueue.main.async {
            if let frontURL = self.frontVideoURL,
               let backURL = self.backVideoURL,
               FileManager.default.fileExists(atPath: frontURL.path),
               FileManager.default.fileExists(atPath: backURL.path) {
                print("🎬 Both videos recorded successfully!")
                print("📁 Front: \(frontURL.lastPathComponent)")
                print("📁 Back: \(backURL.lastPathComponent)")
                self.showVideoPreview()
            } else {
                print("⏳ Waiting for other camera to finish...")
            }
        }
    }

    private func showVideoPreview() {
        print("🎬 Showing video preview")
        // TODO: Implement video preview screen with player
        // For now, just show an alert
        let alert = UIAlertController(title: "✅ Videos Recorded!", message: "Both front and back videos captured successfully", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Social View
struct SocialView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(model.socialPosts) { post in
                        SocialPostView(post: post)
                            .environmentObject(model)
                    }
                    .onDelete(perform: deletePost)
                }
                .padding()
            }
            .navigationTitle("Social")
            .refreshable {
                // Refresh social feed
                model.refreshSocialFeed()
            }
        }
    }

    private func deletePost(at offsets: IndexSet) {
        model.socialPosts.remove(atOffsets: offsets)
        print("🗑️ Deleted social post(s)")
    }
}

struct SocialPostView: View {
    let post: SocialPost
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var showMainAsBack = true
    @State private var showingFullView = false
    @State private var showingComments = false
    @State private var showingEditAlert = false
    @State private var editedTitle = ""

    var userHasLiked: Bool {
        post.likedBy.contains(model.currentUser.id.uuidString)
    }

    var userHasDownvoted: Bool {
        post.downvotedBy.contains(model.currentUser.id.uuidString)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info
            HStack {
                // User avatar
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.userName.prefix(1)).uppercased())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack {
                        Text(post.taskTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(post.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("+\(post.xpEarned) XP")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }

                Spacer()
            }

            // Photo section with Instagram 4:5 ratio
            if let photo = loadSocialPhoto() {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = width * 1.25 // 4:5 ratio

                    ZStack {
                        // Main photo
                        Button(action: { showingFullView = true }) {
                            Image(uiImage: showMainAsBack ? photo.backImage : photo.frontImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: width, height: height)
                                .clipped()
                                .cornerRadius(20)
                        }

                        // Small overlay photo
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { showMainAsBack.toggle() }) {
                                    Image(uiImage: showMainAsBack ? photo.frontImage : photo.backImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 106) // Maintain 4:5 ratio for small image
                                        .clipped()
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                                }
                                .padding(.trailing, 15)
                                .padding(.top, 15)
                            }
                            Spacer()
                        }
                    }
                }
                .aspectRatio(4/5, contentMode: .fit)
            }

            // Interactions section
            HStack(spacing: 20) {
                Button(action: { likePost() }) {
                    HStack(spacing: 4) {
                        Text(userHasLiked ? "🟢" : "⚪")
                        Text("\(post.likes)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(userHasLiked ? .green : .primary)

                Button(action: { downvotePost() }) {
                    HStack(spacing: 4) {
                        Text(userHasDownvoted ? "🔻" : "🔸")
                        Text("\(post.downvotes)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .foregroundColor(userHasDownvoted ? .red : .primary)

                Button(action: { showingComments = true }) {
                    HStack(spacing: 4) {
                        Text("💬")
                        Text("\(post.comments.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                Spacer()
            }
            .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .fullScreenCover(isPresented: $showingFullView) {
            FullImageView(post: post, showMainAsBack: $showMainAsBack)
                .environmentObject(model)
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(post: post)
                .environmentObject(model)
        }
        .contextMenu {
            if post.userId == model.currentUser.id.uuidString {
                Button(action: {
                    editedTitle = post.taskTitle
                    showingEditAlert = true
                }) {
                    Label("Edit Post", systemImage: "pencil")
                }

                Button(action: {
                    model.deleteSocialPost(withId: post.id)
                }) {
                    Label("Delete Post", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
        }
        .alert("Edit Post Title", isPresented: $showingEditAlert) {
            TextField("Task Title", text: $editedTitle)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                model.editSocialPost(withId: post.id, newTitle: editedTitle)
            }
        } message: {
            Text("Enter a new title for this post")
        }
    }

    private func loadSocialPhoto() -> (backImage: UIImage, frontImage: UIImage)? {
        // Try to load from actual task photos first
        if let task = model.recentTasks.first(where: { $0.id == post.taskId }),
           let backPhoto = task.verificationPhoto {
            // Now we store back and front images separately
            // Return them directly for UI overlay display
            let frontPhoto = task.verificationPhotoFront ?? createMockFrontCamera()
            return (backPhoto, frontPhoto)
        }

        // Only show fallback mock images if this post indicates it should have a photo
        guard post.photoFileName != nil else {
            return nil
        }

        // Fallback to mock images for testing (only for posts that should have photos)
        let backImage = createMockBackCamera()
        let frontImage = createMockFrontCamera()
        return (backImage, frontImage)
    }

    private func splitCompositeImage(_ compositeImage: UIImage, hideEmbeddedOverlay: Bool = true) -> (backImage: UIImage, frontImage: UIImage) {
        let imageSize = compositeImage.size

        // Calculate the overlay position and size (must match combineEnhancedDualImages())
        // Overlay is 25% of main image size, positioned 20px from top-right
        let overlaySize = CGSize(
            width: imageSize.width * 0.25,
            height: imageSize.height * 0.25
        )

        let overlayRect = CGRect(
            x: imageSize.width - overlaySize.width - 20,
            y: 20,
            width: overlaySize.width,
            height: overlaySize.height
        )

        // Extract the front camera image from the overlay area
        let frontRenderer = UIGraphicsImageRenderer(size: overlaySize)
        let frontImage = frontRenderer.image { context in
            // Crop the front camera overlay from the composite
            if let cgImage = compositeImage.cgImage?.cropping(to: CGRect(
                x: overlayRect.origin.x * compositeImage.scale,
                y: overlayRect.origin.y * compositeImage.scale,
                width: overlayRect.width * compositeImage.scale,
                height: overlayRect.height * compositeImage.scale
            )) {
                let croppedImage = UIImage(cgImage: cgImage, scale: compositeImage.scale, orientation: compositeImage.imageOrientation)
                croppedImage.draw(in: CGRect(origin: .zero, size: overlaySize))
            }
        }

        // For the back image: Use Core Image blur to reconstruct the area under the overlay
        let backImage: UIImage
        if hideEmbeddedOverlay {
            let borderMargin: CGFloat = 6
            let overlayWithBorder = overlayRect.insetBy(dx: -borderMargin, dy: -borderMargin)

            // Create a mask for the overlay region
            let maskRenderer = UIGraphicsImageRenderer(size: imageSize)
            let maskImage = maskRenderer.image { context in
                // Fill everything with white (keep these areas)
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: imageSize))

                // Fill overlay area with black (remove these areas)
                UIColor.black.setFill()
                context.fill(overlayWithBorder)
            }

            // Use Core Image to blur the entire image, then composite back
            // This creates a natural "filled in" effect
            if let ciImage = CIImage(image: compositeImage),
               let blurFilter = CIFilter(name: "CIGaussianBlur") {
                blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
                blurFilter.setValue(50, forKey: kCIInputRadiusKey) // Heavy blur

                if let blurred = blurFilter.outputImage {
                    let context = CIContext()

                    // Render blurred image
                    let backRenderer = UIGraphicsImageRenderer(size: imageSize)
                    backImage = backRenderer.image { rendererContext in
                        // Draw original image
                        compositeImage.draw(at: .zero)

                        // Draw blurred version only in overlay area
                        let cgContext = rendererContext.cgContext
                        cgContext.saveGState()
                        cgContext.clip(to: overlayWithBorder)

                        if let cgBlurred = context.createCGImage(blurred, from: CGRect(origin: .zero, size: imageSize)) {
                            let blurredUIImage = UIImage(cgImage: cgBlurred)
                            blurredUIImage.draw(at: .zero)
                        }

                        cgContext.restoreGState()
                    }
                } else {
                    backImage = compositeImage
                }
            } else {
                backImage = compositeImage
            }
        } else {
            backImage = compositeImage
        }

        return (backImage, frontImage)
    }

    private func createMockBackCamera() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "📷\n\(post.taskTitle)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func createMockFrontCamera() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "🤳\n\(post.userName)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func createSimplePlaceholder(text: String) -> UIImage {
        let size = CGSize(width: 80, height: 106)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30),
                .foregroundColor: UIColor.clear
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func likePost() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🟢 LIKE BUTTON PRESSED")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        guard let index = model.socialPosts.firstIndex(where: { $0.id == post.id }) else {
            print("❌ ERROR: Could not find post in socialPosts array")
            return
        }

        let currentUserId = model.currentUser.id.uuidString
        let hasLiked = model.socialPosts[index].likedBy.contains(currentUserId)
        let hasDownvoted = model.socialPosts[index].downvotedBy.contains(currentUserId)

        print("📊 Current State BEFORE:")
        print("  - Credibility: \(model.credibilityManager.credibilityScore)")
        print("  - User has liked: \(hasLiked)")
        print("  - User has downvoted: \(hasDownvoted)")
        print("  - Post author ID: \(post.userId)")
        print("  - Current user ID: \(currentUserId)")
        print("  - Is own post: \(post.userId == currentUserId)")

        if hasLiked {
            print("➡️  Action: REMOVING LIKE")
            // User has already liked - remove like
            model.socialPosts[index].likedBy.removeAll { $0 == currentUserId }
            model.socialPosts[index].likes -= 1
            print("✓ Like removed. No credibility change.")
        } else {
            print("➡️  Action: ADDING LIKE")
            // If user has downvoted, remove the downvote first AND restore credibility
            if hasDownvoted {
                print("⚠️  User previously downvoted this post - removing downvote first")
                model.socialPosts[index].downvotedBy.removeAll { $0 == currentUserId }
                model.socialPosts[index].downvotes -= 1

                // Restore credibility if this was a self-downvote
                if post.userId == currentUserId {
                    print("🔄 RESTORING CREDIBILITY (self-downvote undo)")
                    let credibilityBefore = model.credibilityManager.credibilityScore
                    let reviewerId = model.currentUser.id
                    model.credibilityManager.undoDownvote(
                        taskId: post.taskId,
                        reviewerId: reviewerId
                    )

                    // Sync credibility score to currentUser
                    model.currentUser.credibilityScore = Double(model.credibilityManager.credibilityScore)
                    let credibilityAfter = model.credibilityManager.credibilityScore

                    print("💚 Switched from downvote to like - Credibility restored:")
                    print("   BEFORE: \(credibilityBefore)")
                    print("   AFTER: \(credibilityAfter)")
                    print("   CHANGE: +\(credibilityAfter - credibilityBefore)")
                } else {
                    print("ℹ️  Other user's post - no credibility change for you")
                }
            }
            // Add like
            model.socialPosts[index].likedBy.append(currentUserId)
            model.socialPosts[index].likes += 1
            print("✓ Like added successfully")
        }

        print("📊 Final State AFTER:")
        print("  - Credibility: \(model.credibilityManager.credibilityScore)")
        print("  - Tier: \(model.credibilityManager.getCurrentTier().name)")
        print("  - Conversion Rate: \(model.credibilityManager.getFormattedConversionRate())")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }

    private func downvotePost() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔸 DOWNVOTE BUTTON PRESSED")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        guard let index = model.socialPosts.firstIndex(where: { $0.id == post.id }) else {
            print("❌ ERROR: Could not find post in socialPosts array")
            return
        }

        let currentUserId = model.currentUser.id.uuidString
        let hasLiked = model.socialPosts[index].likedBy.contains(currentUserId)
        let hasDownvoted = model.socialPosts[index].downvotedBy.contains(currentUserId)

        print("📊 Current State BEFORE:")
        print("  - Credibility: \(model.credibilityManager.credibilityScore)")
        print("  - User has liked: \(hasLiked)")
        print("  - User has downvoted: \(hasDownvoted)")
        print("  - Post author ID: \(post.userId)")
        print("  - Current user ID: \(currentUserId)")
        print("  - Is own post: \(post.userId == currentUserId)")

        if hasDownvoted {
            print("➡️  Action: REMOVING DOWNVOTE")
            // User has already downvoted - remove downvote and restore credibility
            model.socialPosts[index].downvotedBy.removeAll { $0 == currentUserId }
            model.socialPosts[index].downvotes -= 1

            // Only affect credibility if downvoting your OWN post
            if post.userId == currentUserId {
                print("🔄 RESTORING CREDIBILITY (undo self-downvote)")
                let credibilityBefore = model.credibilityManager.credibilityScore
                // Undo the credibility penalty for self-downvote
                let reviewerId = model.currentUser.id
                model.credibilityManager.undoDownvote(
                    taskId: post.taskId,
                    reviewerId: reviewerId
                )

                // Sync credibility score to currentUser
                model.currentUser.credibilityScore = Double(model.credibilityManager.credibilityScore)
                let credibilityAfter = model.credibilityManager.credibilityScore

                print("↩️  Self-downvote removed - Credibility restored:")
                print("   BEFORE: \(credibilityBefore)")
                print("   AFTER: \(credibilityAfter)")
                print("   CHANGE: +\(credibilityAfter - credibilityBefore)")
            } else {
                print("↩️  Downvote removed from another user's post (no credibility change for you)")
            }
        } else {
            print("➡️  Action: ADDING DOWNVOTE")
            // If user has liked, remove the like first
            if hasLiked {
                print("⚠️  User previously liked this post - removing like first")
                model.socialPosts[index].likedBy.removeAll { $0 == currentUserId }
                model.socialPosts[index].likes -= 1
            }
            // Add downvote
            model.socialPosts[index].downvotedBy.append(currentUserId)
            model.socialPosts[index].downvotes += 1

            // Only affect credibility if downvoting your OWN post (for testing)
            if post.userId == currentUserId {
                print("🔻 APPLYING CREDIBILITY PENALTY (self-downvote)")
                let credibilityBefore = model.credibilityManager.credibilityScore
                // Apply credibility penalty for self-downvote
                let reviewerId = model.currentUser.id
                model.credibilityManager.processDownvote(
                    taskId: post.taskId,
                    reviewerId: reviewerId,
                    notes: "Self-downvoted on social feed"
                )

                // Sync credibility score to currentUser
                model.currentUser.credibilityScore = Double(model.credibilityManager.credibilityScore)
                let credibilityAfter = model.credibilityManager.credibilityScore

                print("🔻 Self-downvote applied:")
                print("   BEFORE: \(credibilityBefore)")
                print("   AFTER: \(credibilityAfter)")
                print("   PENALTY: \(credibilityAfter - credibilityBefore)")
            } else {
                print("🔻 Downvoted another user's post (their credibility would decrease in multi-user system)")
            }
        }

        print("📊 Final State AFTER:")
        print("  - Credibility: \(model.credibilityManager.credibilityScore)")
        print("  - Tier: \(model.credibilityManager.getCurrentTier().name)")
        print("  - Conversion Rate: \(model.credibilityManager.getFormattedConversionRate())")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
}

struct FullImageView: View {
    let post: SocialPost
    @Binding var showMainAsBack: Bool
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let photo = loadSocialPhoto() {
                Image(uiImage: showMainAsBack ? photo.backImage : photo.frontImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                    .onTapGesture {
                        showMainAsBack.toggle()
                    }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }

    private func loadSocialPhoto() -> (backImage: UIImage, frontImage: UIImage)? {
        // Try to load from actual task photos first
        if let task = model.recentTasks.first(where: { $0.id == post.taskId }),
           let verificationPhoto = task.verificationPhoto {
            // The verificationPhoto is a composite image with:
            // - Full-size back camera image as the main image
            // - Front camera image overlaid at 25% size in the top-right corner
            // For full-screen view: show the full composite with embedded overlay
            return splitCompositeImage(verificationPhoto, hideEmbeddedOverlay: false)
        }

        // Only show fallback mock images if this post indicates it should have a photo
        guard post.photoFileName != nil else {
            return nil
        }

        // Fallback to mock images
        let backImage = createMockBackCamera()
        let frontImage = createMockFrontCamera()
        return (backImage, frontImage)
    }

    private func splitCompositeImage(_ compositeImage: UIImage, hideEmbeddedOverlay: Bool = true) -> (backImage: UIImage, frontImage: UIImage) {
        let imageSize = compositeImage.size

        // Calculate the overlay position and size (must match combineEnhancedDualImages())
        // Overlay is 25% of main image size, positioned 20px from top-right
        let overlaySize = CGSize(
            width: imageSize.width * 0.25,
            height: imageSize.height * 0.25
        )

        let overlayRect = CGRect(
            x: imageSize.width - overlaySize.width - 20,
            y: 20,
            width: overlaySize.width,
            height: overlaySize.height
        )

        // Extract the front camera image from the overlay area
        let frontRenderer = UIGraphicsImageRenderer(size: overlaySize)
        let frontImage = frontRenderer.image { context in
            // Crop the front camera overlay from the composite
            if let cgImage = compositeImage.cgImage?.cropping(to: CGRect(
                x: overlayRect.origin.x * compositeImage.scale,
                y: overlayRect.origin.y * compositeImage.scale,
                width: overlayRect.width * compositeImage.scale,
                height: overlayRect.height * compositeImage.scale
            )) {
                let croppedImage = UIImage(cgImage: cgImage, scale: compositeImage.scale, orientation: compositeImage.imageOrientation)
                croppedImage.draw(in: CGRect(origin: .zero, size: overlaySize))
            }
        }

        // For the back image: Use Core Image blur to reconstruct the area under the overlay
        let backImage: UIImage
        if hideEmbeddedOverlay {
            let borderMargin: CGFloat = 6
            let overlayWithBorder = overlayRect.insetBy(dx: -borderMargin, dy: -borderMargin)

            // Create a mask for the overlay region
            let maskRenderer = UIGraphicsImageRenderer(size: imageSize)
            let maskImage = maskRenderer.image { context in
                // Fill everything with white (keep these areas)
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: imageSize))

                // Fill overlay area with black (remove these areas)
                UIColor.black.setFill()
                context.fill(overlayWithBorder)
            }

            // Use Core Image to blur the entire image, then composite back
            // This creates a natural "filled in" effect
            if let ciImage = CIImage(image: compositeImage),
               let blurFilter = CIFilter(name: "CIGaussianBlur") {
                blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
                blurFilter.setValue(50, forKey: kCIInputRadiusKey) // Heavy blur

                if let blurred = blurFilter.outputImage {
                    let context = CIContext()

                    // Render blurred image
                    let backRenderer = UIGraphicsImageRenderer(size: imageSize)
                    backImage = backRenderer.image { rendererContext in
                        // Draw original image
                        compositeImage.draw(at: .zero)

                        // Draw blurred version only in overlay area
                        let cgContext = rendererContext.cgContext
                        cgContext.saveGState()
                        cgContext.clip(to: overlayWithBorder)

                        if let cgBlurred = context.createCGImage(blurred, from: CGRect(origin: .zero, size: imageSize)) {
                            let blurredUIImage = UIImage(cgImage: cgBlurred)
                            blurredUIImage.draw(at: .zero)
                        }

                        cgContext.restoreGState()
                    }
                } else {
                    backImage = compositeImage
                }
            } else {
                backImage = compositeImage
            }
        } else {
            backImage = compositeImage
        }

        return (backImage, frontImage)
    }

    private func createMockBackCamera() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "📷\n\(post.taskTitle)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func createMockFrontCamera() -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "🤳\n\(post.userName)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func createSimplePlaceholder(text: String) -> UIImage {
        let size = CGSize(width: 80, height: 106)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30),
                .foregroundColor: UIColor.clear
            ]

            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

struct CommentsView: View {
    let post: SocialPost
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var newComment = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                // Comments list
                List(post.comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(comment.userName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(comment.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(comment.content)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }

                // Add comment section
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Post") {
                        addComment()
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }

    private func addComment() {
        let comment = SocialComment(
            userId: model.currentUser.id.uuidString,
            userName: model.currentUser.username,
            content: newComment.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: Date()
        )

        if let index = model.socialPosts.firstIndex(where: { $0.id == post.id }) {
            model.socialPosts[index].comments.append(comment)
        }

        newComment = ""
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @StateObject private var themeViewModel = DependencyContainer.shared
        .viewModelFactory.makeThemeSettingsViewModel()
    @ObservedObject private var resetHelper = ResetOnboardingHelper.shared
    @ObservedObject private var deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
    @ObservedObject private var profilePhotoManager = ProfilePhotoManager.shared
    @State private var showingNotificationSettings = false
    @State private var showingEditName = false
    @State private var showingEditAge = false
    @State private var showingProfilePhotoPicker = false
    @State private var tempName: String = ""

    // Persisted user data
    @AppStorage("userName") private var userName: String = "User"
    @AppStorage("userAge") private var userAge: Int = 13

    var body: some View {
        NavigationView {
            profileContent
        }
        .alert("Edit Name", isPresented: $showingEditName) {
            TextField("Enter your name", text: $tempName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !tempName.trimmingCharacters(in: .whitespaces).isEmpty {
                    userName = tempName
                }
            }
        } message: {
            Text("What would you like to be called?")
        }
        .alert("Reset Onboarding?", isPresented: $resetHelper.showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetHelper.performReset()
            }
        } message: {
            Text("This will reset the app and show the welcome screen again. The app will close.")
        }
    }

    private var profileContent: some View {
        List {
            Section {
                // Profile photo display and edit
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // Profile photo display
                        if let profile = deviceModeManager.currentProfile,
                           let photoFileName = profile.profilePhotoFileName,
                           let image = profilePhotoManager.loadProfilePhoto(fileName: photoFileName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.purple, lineWidth: 3)
                                )
                        } else {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text(String(userName.prefix(2)).uppercased())
                                        .font(.system(size: 40, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }

                        Button(action: {
                            showingProfilePhotoPicker = true
                        }) {
                            Text(deviceModeManager.currentProfile?.profilePhotoFileName == nil ? "Add Photo" : "Change Photo")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 8)
                    Spacer()
                }

                // User info
                HStack {
                    VStack(alignment: .leading) {
                        Text(userName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Credibility: \(Int(model.currentUser.credibilityScore))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }

            Section("Personal Information") {
                Button(action: {
                    tempName = userName
                    showingEditName = true
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        Text("Name")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(userName)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    showingEditAge = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("Age")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(userAge)")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Statistics") {
                HStack {
                    Text("Total XP Earned")
                    Spacer()
                    Text("\(model.currentUser.totalXPEarned)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Current XP Balance")
                    Spacer()
                    Text("\(model.currentUser.xpBalance)")
                        .fontWeight(.semibold)
                }

                NavigationLink(destination: FriendsView().environmentObject(model)) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("Friends")
                        Spacer()
                        Text("\(model.friends.count)")
                            .fontWeight(.semibold)
                        if model.pendingFriendRequests.count > 0 {
                            Text("(\(model.pendingFriendRequests.count))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            Section("Settings") {
                // Theme/Appearance Picker
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.blue)
                        Text("Appearance")
                            .foregroundColor(.primary)
                    }

                    Picker("Theme", selection: Binding(
                        get: { themeViewModel.selectedTheme },
                        set: { themeViewModel.selectTheme($0) }
                    )) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            HStack {
                                Image(systemName: mode.icon)
                                Text(mode.displayName)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Current effective theme display
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Current: \(themeViewModel.effectiveThemeDescription())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)

                Button(action: {
                    showingNotificationSettings = true
                }) {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.blue)
                        Text("Notifications")
                        Spacer()
                        if model.notificationManager.hasPermission {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }

                Button(action: {
                    if let url = URL(string: "https://nd-ahl.github.io/Envive/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.blue)
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    if let url = URL(string: "https://nd-ahl.github.io/Envive/terms-of-service") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text("Terms of Service")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Button("Test Friend Activity Notification") {
                    model.simulateFriendActivity()
                }
                .foregroundColor(.blue)
            }

            Section {
                Button(action: {
                    resetHelper.initiateReset()
                }) {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.orange)
                }
            } header: {
                Text("Debug & Testing")
            } footer: {
                Text("Reset onboarding to see the welcome screen again")
                    .font(.caption)
            }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
                .environmentObject(model)
        }
        .sheet(isPresented: $showingEditAge) {
            EditAgeView(userAge: $userAge)
        }
        .sheet(isPresented: $showingProfilePhotoPicker) {
            if let profile = deviceModeManager.currentProfile {
                ProfilePhotoPicker(
                    userId: profile.id,
                    currentPhotoFileName: profile.profilePhotoFileName,
                    onPhotoSelected: { fileName in
                        updateProfilePhoto(fileName: fileName)
                    }
                )
            }
        }
    }

    private func updateProfilePhoto(fileName: String) {
        deviceModeManager.updateProfilePhoto(fileName: fileName.isEmpty ? nil : fileName)
    }
}

// MARK: - Edit Age View
struct EditAgeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userAge: Int

    @State private var editedAge: Int

    init(userAge: Binding<Int>) {
        self._userAge = userAge
        self._editedAge = State(initialValue: userAge.wrappedValue)
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Select Your Age")
                    .font(.headline)
                    .padding(.top, 20)

                Picker("Age", selection: $editedAge) {
                    ForEach(5...100, id: \.self) { age in
                        Text("\(age)").tag(age)
                    }
                }
                .pickerStyle(.wheel)
                .padding()

                Spacer()
            }
            .navigationTitle("Edit Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        userAge = editedAge
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Photo Gallery View
struct PhotoGalleryView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var selectedPhoto: SavedPhoto?
    @State private var showingFullScreenPhoto = false

    var body: some View {
        NavigationView {
            Group {
                if model.cameraManager.savedPhotos.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No photos yet")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Complete tasks with photo verification to see them here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Photo grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 2) {
                            ForEach(model.cameraManager.savedPhotos.reversed()) { photo in
                                PhotoThumbnailView(savedPhoto: photo) {
                                    selectedPhoto = photo
                                    showingFullScreenPhoto = true
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Photo Gallery")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFullScreenPhoto) {
                if let selectedPhoto = selectedPhoto {
                    FullScreenPhotoView(savedPhoto: selectedPhoto, cameraManager: model.cameraManager)
                }
            }
        }
    }
}

struct PhotoThumbnailView: View {
    let savedPhoto: SavedPhoto
    let onTap: () -> Void
    @EnvironmentObject var model: EnhancedScreenTimeModel

    var body: some View {
        Button(action: onTap) {
            Group {
                if let image = model.cameraManager.loadPhoto(savedPhoto: savedPhoto) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FullScreenPhotoView: View {
    let savedPhoto: SavedPhoto
    let cameraManager: CameraManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationView {
            VStack {
                if let image = cameraManager.loadPhoto(savedPhoto: savedPhoto) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Failed to load image")
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(savedPhoto.taskTitle)
                        .font(.headline)

                    Text(savedPhoto.timestamp, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(savedPhoto.timestamp, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .alert("Delete Photo", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    cameraManager.deletePhoto(savedPhoto)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this photo? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Main App Structure
struct ContentView: View {
    @StateObject private var model = EnhancedScreenTimeModel()
    @State private var selectedTab = 0
    @State private var showingNotificationSettings = false
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager

    /// Determines the correct child ID based on the current device mode
    private var currentChildId: UUID {
        switch deviceModeManager.currentMode {
        case .parent:
            return deviceModeManager.getTestChild1Id()  // Shouldn't happen in child view, but default to child 1
        case .child1:
            return deviceModeManager.getTestChild1Id()
        case .child2:
            return deviceModeManager.getTestChild2Id()
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ChildDashboardView(
                viewModel: ChildDashboardViewModel(
                    taskService: DependencyContainer.shared.taskService,
                    xpService: DependencyContainer.shared.xpService,
                    credibilityService: DependencyContainer.shared.credibilityService,
                    childId: currentChildId
                )
            )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                .badge(model.friendActivities.filter { activity in
                    // Show badge for recent activities (last hour)
                    Date().timeIntervalSince(activity.timestamp) < 3600
                }.count)

            EnhancedTasksView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Tasks")
                }
                .tag(1)
            
            SocialView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "heart.circle.fill")
                    Text("Social")
                }
                .tag(2)
            
            ParentDashboardView(
                viewModel: ParentDashboardViewModel(
                    taskService: DependencyContainer.shared.taskService,
                    credibilityService: DependencyContainer.shared.credibilityService,
                    xpService: DependencyContainer.shared.xpService,
                    parentId: UUID(), // TODO: Replace with actual parent ID from user session
                    testChild1Id: DependencyContainer.shared.deviceModeManager.getTestChild1Id(),
                    testChild2Id: DependencyContainer.shared.deviceModeManager.getTestChild2Id(),
                    deviceModeManager: DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
                ),
                appSelectionStore: model.appSelectionStore,
                notificationManager: model.notificationManager
            )
                .tabItem {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Task Approvals")
                }
                .tag(3)

            PhotoGalleryView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Photos")
                }
                .tag(5)
                .badge(model.cameraManager.savedPhotos.count > 0 ? model.cameraManager.savedPhotos.count : 0)

            ProfileView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(6)

            CredibilityTestingView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Credibility")
                }
                .tag(7)
        }
        .onAppear {
            // Request permissions
            model.notificationManager.requestPermission()

            // Clear badge when app opens
            model.notificationManager.clearBadge()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                print("App became active - ensuring screen time restrictions are properly applied")
                model.ensureAppsAreBlocked()
                // Check for pending widget session requests when app becomes active
                model.checkForPendingWidgetSession()
                model.checkForEndSessionRequest()
            case .inactive:
                print("App became inactive")
            case .background:
                print("App moved to background")
            @unknown default:
                break
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
                .environmentObject(model)
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("friendActivityNotifications") private var friendActivityNotifications = true
    @AppStorage("friendRequestNotifications") private var friendRequestNotifications = true
    @AppStorage("milestoneNotifications") private var milestoneNotifications = true
    @AppStorage("dailyReminders") private var dailyReminders = true
    @AppStorage("sessionReminders") private var sessionReminders = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notification Permissions") {
                    HStack {
                        Text("Push Notifications")
                        Spacer()
                        if model.notificationManager.hasPermission {
                            Text("Enabled")
                                .foregroundColor(.green)
                        } else {
                            Button("Enable") {
                                model.notificationManager.requestPermission()
                            }
                        }
                    }
                }
                
                Section("Friend Notifications") {
                    Toggle("Friend Task Completions", isOn: $friendActivityNotifications)
                    Toggle("Friend Requests", isOn: $friendRequestNotifications)
                    Toggle("Location Sharing Updates", isOn: $friendActivityNotifications)
                }
                
                Section("Personal Notifications") {
                    Toggle("Milestone Achievements", isOn: $milestoneNotifications)
                    Toggle("Daily Goal Reminders", isOn: $dailyReminders)
                    Toggle("Session End Reminders", isOn: $sessionReminders)
                }
                
                Section {
                    Button("Test Notification") {
                        model.simulateFriendActivity()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Simple Camera View
struct SimpleCameraView: UIViewControllerRepresentable {
    let onPhotoTaken: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SimpleCameraView

        init(_ parent: SimpleCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                print("📸 Simple camera captured image successfully")
                parent.onPhotoTaken(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📸 Simple camera cancelled")
        }
    }
}

// MARK: - Enhanced Task Row with Camera
struct EnhancedTaskRow: View {
    let taskId: UUID
    let onComplete: () -> Void
    let onCompleteWithPhoto: (UIImage, UIImage?) -> Void // (backCamera, frontCamera)

    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var showingCamera = false
    @State private var showingLocationTracking = false
    @State private var localVerificationPhoto: UIImage? // Local backup for photo state
    @State private var isEditingCompletedTask = false
    @State private var editedTaskTitle = ""

    var task: TaskItem {
        // Always get the current task from the model to ensure live updates
        let foundTask = model.recentTasks.first(where: { $0.id == taskId }) ?? TaskItem(
            title: "Unknown", category: .custom, xpReward: 0, estimatedMinutes: 0,
            isCustom: false, completed: false, createdBy: "", isGroupTask: false,
            participants: [], verificationRequired: true, verificationPhoto: nil, verificationPhotoFront: nil  // ALL tasks require photo
        )

        return foundTask
    }

    // Use local photo state as backup if model photo isn't set
    var hasVerificationPhoto: Bool {
        let modelHasPhoto = task.verificationPhoto != nil
        let localHasPhoto = localVerificationPhoto != nil
        let result = modelHasPhoto || localHasPhoto

        if task.verificationRequired {
            print("🔍 TaskRow - '\(task.title)' model photo: \(modelHasPhoto), local photo: \(localHasPhoto), result: \(result)")
        }

        return result
    }

    var currentPhoto: UIImage? {
        return task.verificationPhoto ?? localVerificationPhoto
    }
    
    var needsLocationTracking: Bool {
        task.category == .outdoor || task.category == .exercise
    }

    func saveEditedTask() {
        if let index = model.recentTasks.firstIndex(where: { $0.id == taskId }) {
            model.recentTasks[index].title = editedTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            isEditingCompletedTask = false

            // Update any associated social posts with the new title
            if let postIndex = model.socialPosts.firstIndex(where: { $0.taskId == taskId }) {
                model.socialPosts[postIndex].taskTitle = editedTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    
    var body: some View {
        HStack {
            Button(action: {
                if !task.completed {
                    if task.verificationRequired {
                        showingCamera = true
                    } else {
                        onComplete()
                    }
                }
            }) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.completed ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(task.completed)

            VStack(alignment: .leading, spacing: 4) {
                if isEditingCompletedTask && task.completed {
                    TextField("Task title", text: $editedTaskTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onAppear {
                            editedTaskTitle = task.title
                        }
                } else {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(task.completed)
                        .foregroundColor(task.completed ? .secondary : .primary)
                }

                HStack {
                    Text(task.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(task.completed ? Color.gray.opacity(0.2) : Color.blue.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(task.completed ? .secondary : .primary)

                    Text("\(task.xpReward) XP")
                        .font(.caption)
                        .foregroundColor(task.completed ? .secondary : .green)

                    Text("~\(task.estimatedMinutes)m")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if task.verificationRequired {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(task.completed ? .secondary : .orange)
                    }
                    
                    if needsLocationTracking {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if task.completed, let photo = task.verificationPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .cornerRadius(8)
                }
            }

            Spacer()

            if !task.completed {
                VStack(spacing: 8) {
                    if task.verificationRequired {
                        if hasVerificationPhoto {
                            Button("✅ Complete") {
                                print("🎯 Complete button pressed for task: \(task.title)")
                                print("🎯 Photo already exists, calling onComplete() directly")
                                onComplete()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(.green)
                        } else {
                            Button("📸 Verify") {
                                print("📸 Verify button pressed for task: \(task.title)")
                                showingCamera = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    if !task.verificationRequired {
                        Button("Complete") {
                            onComplete()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            } else {
                // Completed task controls
                if isEditingCompletedTask {
                    HStack(spacing: 8) {
                        Button("Save") {
                            saveEditedTask()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.blue)

                        Button("Cancel") {
                            isEditingCompletedTask = false
                            editedTaskTitle = task.title
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)

                        Button(action: {
                            isEditingCompletedTask = true
                            editedTaskTitle = task.title
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(
                cameraManager: model.cameraManager,
                isPresented: $showingCamera,
                taskTitle: task.title,
                taskId: task.id,
                onPhotoTaken: { backPhoto, frontPhoto in
                    print("🔥 BEREAL CAMERA: Photos captured for task: \(task.title)")
                    print("🔥 Back photo: \(backPhoto.size), Front photo: \(frontPhoto?.size.debugDescription ?? "none")")

                    // Set both local and model photos
                    localVerificationPhoto = backPhoto

                    if let index = model.recentTasks.firstIndex(where: { $0.id == taskId }) {
                        model.recentTasks[index].verificationPhoto = backPhoto
                        model.recentTasks[index].verificationPhotoFront = frontPhoto
                        model.objectWillChange.send()
                    }

                    // AUTO-COMPLETE: Immediately complete the task after photo
                    print("🎯 AUTO-COMPLETE: Completing task automatically after photo")
                    showingCamera = false
                    onComplete()
                }
            )
            .onDisappear {
                // Clean up when camera closes
                showingCamera = false
            }
        }
    }
}

// MARK: - Enhanced Tasks View
struct EnhancedTasksView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var showingAddTask = false

    var incompleteTasks: [TaskItem] {
        model.recentTasks.filter { !$0.completed }
    }

    var completedTasks: [TaskItem] {
        model.recentTasks.filter { $0.completed }
    }

    var body: some View {
        NavigationView {
            List {
                if !incompleteTasks.isEmpty {
                    Section("To Do") {
                        ForEach(incompleteTasks, id: \.id) { task in
                            // Find the actual task in model.recentTasks to ensure live updates
                            if let originalIndex = model.recentTasks.firstIndex(where: { $0.id == task.id }) {
                                EnhancedTaskRow(
                                    taskId: task.id,
                                onComplete: {
                                    model.completeTask(model.recentTasks[originalIndex])
                                    model.recentTasks[originalIndex].completed = true
                                },
                                onCompleteWithPhoto: { backPhoto, frontPhoto in
                                    print("🚨 onCompleteWithPhoto CALLED for task: \(model.recentTasks[originalIndex].title) with ID: \(model.recentTasks[originalIndex].id)")
                                    print("🚨 Back photo size: \(backPhoto.size), Front photo: \(frontPhoto?.size.debugDescription ?? "none"), originalIndex: \(originalIndex)")

                                    // Save back photo to persistent storage with task ID
                                    let saveSuccess = model.cameraManager.savePhoto(backPhoto, taskTitle: model.recentTasks[originalIndex].title, taskId: model.recentTasks[originalIndex].id)
                                    if saveSuccess {
                                        print("✅ Photo saved to persistent storage with task ID: \(model.recentTasks[originalIndex].id)")
                                    } else {
                                        print("❌ Failed to save photo to persistent storage")
                                    }

                                    // Complete task with photos - this handles XP, social posts, AND streak tracking
                                    print("🎯 COMPLETING TASK WITH PHOTOS: \(model.recentTasks[originalIndex].title)")
                                    model.completeTaskWithPhoto(model.recentTasks[originalIndex], backPhoto: backPhoto, frontPhoto: frontPhoto)

                                    // Force UI refresh
                                    model.objectWillChange.send()

                                    print("📸 Task completion process finished for: \(model.recentTasks[originalIndex].title)")
                                }
                            )
                            }
                        }
                    }
                }

                if !completedTasks.isEmpty {
                    Section("Completed") {
                        ForEach(completedTasks, id: \.id) { task in
                            EnhancedTaskRow(
                                taskId: task.id,
                                onComplete: {},
                                onCompleteWithPhoto: { _, _ in }
                            )
                        }
                    }
                }

                if incompleteTasks.isEmpty && completedTasks.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No tasks yet")
                                .font(.headline)
                            Text("Add your first task to get started!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
                    .environmentObject(model)
            }
        }
    }
}

// MARK: - Friends View with Real Friend System
struct FriendsView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search users...", text: $searchText)
                        .onChange(of: searchText) { _, newValue in
                            model.searchUsers(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            model.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Tab Picker
                Picker("", selection: $selectedTab) {
                    Text("Friends (\(model.friends.count))").tag(0)
                    Text("Requests (\(model.pendingFriendRequests.count))").tag(1)
                    Text("Sent (\(model.sentFriendRequests.count))").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content
                TabView(selection: $selectedTab) {
                    // Friends List Tab
                    friendsListView
                        .tag(0)
                    
                    // Friend Requests Tab
                    friendRequestsView
                        .tag(1)
                    
                    // Sent Requests Tab
                    sentRequestsView
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        model.simulateIncomingFriendRequests()
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
        }
        .overlay(
            ToastView(message: model.toastMessage ?? "", isShowing: $model.showToast)
        )
    }
    
    private var friendsListView: some View {
        List {
            // Search Results Section
            if !searchText.isEmpty {
                Section("Search Results") {
                    if model.isSearching {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Searching...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if model.searchResults.isEmpty {
                        Text("No users found")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(model.searchResults) { user in
                            SearchResultRow(user: user) {
                                model.sendFriendRequest(to: user)
                            }
                        }
                    }
                }
            }
            
            // Current Friends Section
            if !model.friends.isEmpty {
                Section("Friends") {
                    ForEach(Array(model.friends.sorted(by: { $0.totalXPEarned > $1.totalXPEarned }).enumerated()), id: \.element.id) { index, friend in
                        FriendLeaderboardRowWithSwipe(friend: friend, rank: index + 1) {
                            model.removeFriend(friend)
                        }
                    }
                }
            } else if searchText.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No friends yet")
                            .font(.headline)
                        Text("Search for users above to send friend requests")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Recent Activity Section
            if !model.friendActivities.isEmpty {
                Section("Recent Activity") {
                    ForEach(model.friendActivities) { activity in
                        FriendActivityRow(activity: activity)
                    }
                }
            }
        }
    }
    
    private var friendRequestsView: some View {
        List {
            if model.pendingFriendRequests.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No friend requests")
                            .font(.headline)
                        Text("Friend requests will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            } else {
                Section("Friend Requests") {
                    ForEach(model.pendingFriendRequests) { user in
                        FriendRequestRow(user: user,
                                       onAccept: { model.acceptFriendRequest(from: user) },
                                       onDecline: { model.declineFriendRequest(from: user) })
                    }
                }
            }
        }
    }
    
    private var sentRequestsView: some View {
        List {
            if model.sentFriendRequests.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "paperplane")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No sent requests")
                            .font(.headline)
                        Text("Requests you send will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            } else {
                Section("Sent Requests") {
                    ForEach(model.sentFriendRequests) { user in
                        SentRequestRow(user: user) {
                            model.cancelFriendRequest(to: user)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views for Friend System
struct SearchResultRow: View {
    let user: User
    let onAddFriend: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.username.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                )
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(user.totalXPEarned) XP • \(Int(user.credibilityScore))% credibility")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onAddFriend) {
                Label("Add", systemImage: "person.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

struct FriendRequestRow: View {
    let user: User
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.username.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                )
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Wants to be friends")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SentRequestRow: View {
    let user: User
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.username.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                )
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Request sent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Text("Cancel")
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

struct FriendLeaderboardRowWithSwipe: View {
    let friend: User
    let rank: Int
    let onRemoveFriend: (() -> Void)?
    @State private var showingRemoveAlert = false

    init(friend: User, rank: Int, onRemoveFriend: (() -> Void)? = nil) {
        self.friend = friend
        self.rank = rank
        self.onRemoveFriend = onRemoveFriend
    }

    var body: some View {
        FriendLeaderboardRow(friend: friend, rank: rank)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    showingRemoveAlert = true
                } label: {
                    Label("Remove", systemImage: "person.badge.minus")
                }
            }
            .alert("Remove Friend?", isPresented: $showingRemoveAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    onRemoveFriend?()
                }
            } message: {
                Text("Are you sure you would like to remove \(friend.username) as a friend?")
            }
    }
}

struct FriendLeaderboardRow: View {
    let friend: User
    let rank: Int

    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.headline)
                .foregroundColor(rank <= 3 ? .yellow : .secondary)
                .frame(width: 30)

            Circle()
                .fill(Color.purple.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(friend.username.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                )

            VStack(alignment: .leading) {
                Text(friend.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Credibility: \(Int(friend.credibilityScore))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(friend.totalXPEarned)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Total XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FriendActivityRow: View {
    let activity: FriendActivity

    var body: some View {
        HStack(spacing: 12) {
            // Enhanced avatar with gradient background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.6), Color.blue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .overlay(
                    Text(String(activity.username.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if activity.hasVerificationPhoto {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                    }

                    Spacer()

                    Text(timeAgo(activity.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(activity.activity)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                HStack {
                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(activity.xpEarned) XP")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
                }

                if let photo = activity.verificationPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

// MARK: - Enhanced Home View
struct EnhancedHomeView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var selectedDuration = 30
    @State private var showingAddTask = false

    // Real data from services
    @State private var xpBalance: Int = 0
    @State private var credibility: Int = 100
    @State private var completedTasksCount: Int = 0
    @State private var totalXPEarned: Int = 0
    @State private var dayStreak: Int = 0
    @State private var childId: UUID = UUID()
    @State private var assignedTasks: [TaskAssignment] = []

    // Access stored user name
    @AppStorage("userName") private var userName: String = "User"

    // Services
    @ObservedObject private var deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
    private let profilePhotoManager = ProfilePhotoManager.shared
    private let xpService = DependencyContainer.shared.xpService
    private let credibilityService = DependencyContainer.shared.credibilityService
    private let taskService = DependencyContainer.shared.taskService

    private var currentUserLevel: UserLevel {
        UserLevel(totalXP: totalXPEarned)
    }

    /// Determines the correct child ID based on the current device mode
    private var currentChildId: UUID {
        switch deviceModeManager.currentMode {
        case .parent:
            return deviceModeManager.getTestChild1Id()  // Shouldn't happen in child view, but default to child 1
        case .child1:
            return deviceModeManager.getTestChild1Id()
        case .child2:
            return deviceModeManager.getTestChild2Id()
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(userName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        NavigationLink(destination: ProfileView().environmentObject(model)) {
                            // Show profile photo if available, otherwise show initials
                            if let profile = deviceModeManager.currentProfile,
                               let photoFileName = profile.profilePhotoFileName,
                               let image = profilePhotoManager.loadProfilePhoto(fileName: photoFileName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.purple, lineWidth: 2)
                                    )
                            } else {
                                Circle()
                                    .fill(Color.purple.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(userName.prefix(1)))
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    )
                            }
                        }
                    }

                    // Level Progress Bar
                    LevelProgressBar(userLevel: currentUserLevel)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "Screen Time", value: "\(model.totalAvailableMinutes) min", color: .blue, icon: "clock.fill")
                        StatCard(title: "Tasks Done", value: "\(completedTasksCount)", color: .green, icon: "checkmark.circle.fill")
                        StatCard(title: "Day Streak", value: "\(dayStreak)", color: .orange, icon: "flame.fill")
                        StatCard(title: "Credibility", value: "\(credibility)%", color: credibilityColor(score: credibility), icon: "checkmark.seal.fill")
                    }

                    if model.isSessionActive {
                        VStack(spacing: 12) {
                            Text("Spending Screen Time")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Text(timeString(from: model.sessionTimeRemaining))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                            
                            HStack(spacing: 16) {
                                Button("Pause") { model.pauseSession() }
                                    .buttonStyle(.bordered)
                                
                                Button("End Session") { model.endSession() }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    } else if model.isSessionPaused {
                        VStack(spacing: 12) {
                            Text("Session Paused")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)

                            Text(timeString(from: model.sessionTimeRemaining))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)

                            Text("Time Used: \(timeString(from: model.sessionTimeUsed))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 16) {
                                Button("Resume") { model.resumeSession() }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)

                                Button("End Session") { model.endSession() }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    } else if xpBalance > 0 {
                        VStack(spacing: 12) {
                            Text("Start Spending Screen Time")
                                .font(.headline)

                            Text("You have \(model.totalAvailableMinutes) earned minutes available")
                                .foregroundColor(.secondary)
                            
                            Picker("Duration", selection: $selectedDuration) {
                                ForEach([15, 30, 45, 60], id: \.self) { minutes in
                                    Text("\(minutes) min").tag(minutes)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Button("Start Spending Screen Time") {
                                model.startEarnedSession(duration: selectedDuration)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedDuration > xpBalance)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Your Tasks Card (using real assigned tasks)
                    VStack(spacing: 12) {
                        HStack {
                            Text("Your Tasks")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: ChildDashboardView(
                                viewModel: ChildDashboardViewModel(
                                    taskService: taskService,
                                    xpService: xpService,
                                    credibilityService: credibilityService,
                                    childId: childId
                                )
                            )) {
                                Text("See All")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        if assignedTasks.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("No assigned tasks")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Check the task library for tasks you can do!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        } else {
                            VStack(spacing: 8) {
                                ForEach(Array(assignedTasks.prefix(3)), id: \.id) { task in
                                    NavigationLink(destination: ChildTaskDetailView(
                                        assignment: task,
                                        taskService: taskService
                                    )) {
                                        HStack(spacing: 12) {
                                            // Profile photo or icon
                                            if task.isParentAssigned,
                                               let assignerId = task.assignedBy,
                                               let assignerProfile = getAssignerProfile(assignerId) {
                                                // Parent assigned task - show parent's photo
                                                if let photoFileName = assignerProfile.profilePhotoFileName,
                                                   let image = ProfilePhotoManager.shared.loadProfilePhoto(fileName: photoFileName) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 32, height: 32)
                                                        .clipShape(Circle())
                                                } else {
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.2))
                                                        .frame(width: 32, height: 32)
                                                        .overlay(
                                                            Text(String(assignerProfile.name.prefix(1)).uppercased())
                                                                .font(.system(size: 12, weight: .semibold))
                                                                .foregroundColor(.blue)
                                                        )
                                                }
                                            } else {
                                                // Self-created task - show child's photo
                                                if let profile = deviceModeManager.currentProfile,
                                                   let photoFileName = profile.profilePhotoFileName,
                                                   let image = ProfilePhotoManager.shared.loadProfilePhoto(fileName: photoFileName) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 32, height: 32)
                                                        .clipShape(Circle())
                                                } else {
                                                    Circle()
                                                        .fill(Color.green.opacity(0.2))
                                                        .frame(width: 32, height: 32)
                                                        .overlay(
                                                            Image(systemName: "person.fill")
                                                                .font(.system(size: 14))
                                                                .foregroundColor(.green)
                                                        )
                                                }
                                            }

                                            // Task Info
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(task.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)

                                                HStack(spacing: 8) {
                                                    Text(task.assignedLevel.shortName)
                                                        .font(.caption)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.blue.opacity(0.2))
                                                        .foregroundColor(.blue)
                                                        .cornerRadius(4)

                                                    Text("\(task.assignedLevel.baseXP) min")
                                                        .font(.caption)
                                                        .foregroundColor(.green)

                                                    // Status badge
                                                    if task.status == .inProgress {
                                                        HStack(spacing: 4) {
                                                            Image(systemName: "play.circle.fill")
                                                                .font(.caption2)
                                                            Text("In Progress")
                                                        }
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                    }
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Friends Activity Card
                    if !model.friendActivities.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Friends Activity")
                                    .font(.headline)
                                Spacer()
                                NavigationLink(destination: FriendsView().environmentObject(model)) {
                                    Text("See All")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }

                            VStack(spacing: 8) {
                                ForEach(Array(model.friendActivities.prefix(3)), id: \.id) { activity in
                                    HStack {
                                        Circle()
                                            .fill(Color.green.opacity(0.3))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text(String(activity.username.prefix(1)))
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                            )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(activity.username)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(activity.activity)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("+\(activity.xpEarned) XP")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.green)
                                            Text(timeAgo(activity.timestamp))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Envive")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
                    .environmentObject(model)
            }
            .onAppear {
                loadRealData()
            }
            .onChange(of: deviceModeManager.currentMode) { _, _ in
                // Reload data when mode switches between children
                loadRealData()
            }
            .refreshable {
                loadRealData()
            }
        }
    }

    // MARK: - Load Real Data

    private func loadRealData() {
        // Get the current child ID based on the device mode
        childId = currentChildId

        print("🏠 Home screen loading data for child ID: \(childId) (mode: \(deviceModeManager.currentMode.displayName))")

        // Load XP balance (screen time minutes)
        if let balance = xpService.getBalance(userId: childId) {
            xpBalance = balance.currentXP
            totalXPEarned = balance.lifetimeEarned
        } else {
            xpBalance = 0
            totalXPEarned = 0
        }

        // Convert XP to minutes and sync with model.minutesEarned
        // This ensures the home screen and session system use the same value
        let convertedMinutes = credibilityService.calculateXPToMinutes(xpAmount: xpBalance, childId: childId)
        model.minutesEarned = convertedMinutes

        print("🔄 Synced XP to minutes: \(xpBalance) XP = \(convertedMinutes) minutes")

        // Load credibility
        credibility = credibilityService.getCredibilityScore(childId: childId)

        // Load tasks
        let allTasks = taskService.getChildTasks(childId: childId, status: nil)

        // Get assigned tasks (assigned and in-progress)
        assignedTasks = allTasks.filter { $0.status == .assigned || $0.status == .inProgress }

        // Count completed tasks
        completedTasksCount = allTasks.filter { $0.status == .approved }.count

        // Load day streak based on consecutive days with task uploads
        dayStreak = credibilityService.getDailyStreak(childId: childId)

        print("🏠 Loaded: \(xpBalance) XP (\(convertedMinutes) min), \(assignedTasks.count) assigned tasks, \(completedTasksCount) completed tasks, \(credibility)% credibility, \(dayStreak) day streak")
    }

    private func credibilityColor(score: Int) -> Color {
        switch score {
        case 80...100:
            return .green
        case 50...79:
            return .yellow
        default:
            return .red
        }
    }

    /// Get the profile of the user who assigned a task
    private func getAssignerProfile(_ assignerId: UUID) -> UserProfile? {
        let deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager

        // Try to load the actual stored profile
        if let profile = deviceModeManager.getProfile(byId: assignerId) {
            return profile
        }

        // Fallback: Create a default parent profile for display
        return UserProfile(
            id: assignerId,
            name: "Parent",
            mode: .parent
        )
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    Spacer()
                }
                
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Inline Add Task View
struct InlineAddTaskView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var taskTitle = ""
    @State private var selectedCategory: TaskCategory = .custom
    let onCancel: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField("Task title", text: $taskTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Picker("Category", selection: $selectedCategory) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(MenuPickerStyle())

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.secondary)

                Spacer()

                Button("Add Task") {
                    let _ = model.createCustomTask(
                        title: taskTitle,
                        category: selectedCategory
                    )
                    onAdd()
                }
                .disabled(taskTitle.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var taskTitle = ""
    @State private var selectedCategory: TaskCategory = .custom
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $taskTitle)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let _ = model.createCustomTask(
                            title: taskTitle,
                            category: selectedCategory
                        )
                        dismiss()
                    }
                    .disabled(taskTitle.isEmpty)
                }
            }
        }
    }
}

struct SafariTestView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var appSelectionStore = AppSelectionStore()
    @StateObject private var screenTimeManager = ScreenTimeManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Safari Screen Time Test")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 15) {
                    // Authorization Status
                    VStack {
                        Text("Authorization Status")
                            .font(.headline)
                        Text(screenTimeManager.isAuthorized ? "Authorized" : "Not Authorized")
                            .foregroundColor(screenTimeManager.isAuthorized ? .green : .red)
                    }

                    // Request Authorization Button
                    if !screenTimeManager.isAuthorized {
                        Button("Request Screen Time Permission") {
                            Task {
                                try? await screenTimeManager.requestAuthorization()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    // Safari Blocking Controls
                    if screenTimeManager.isAuthorized {
                        VStack(spacing: 10) {
                            Text("Safari Blocking")
                                .font(.headline)

                            HStack(spacing: 20) {
                                Button("Block Safari") {
                                    settingsManager.blockSafariWithCustomShield()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)

                                Button("Unblock Safari") {
                                    settingsManager.unblockSafari()
                                }
                                .buttonStyle(.bordered)
                            }

                            Text("Safari Status: \(settingsManager.isSafariBlocked ? "Blocked" : "Unblocked")")
                                .foregroundColor(settingsManager.isSafariBlocked ? .red : .green)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Safari Test")
        }
    }
}


// MARK: - Enhanced Camera System with Immediate Preview & Social Posting

struct EnhancedCameraView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @Binding var isPresented: Bool
    let taskTitle: String
    let taskId: UUID
    let onPhotoPosted: (UIImage) -> Void

    @State private var currentPhase: CameraPhase = .capture
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    enum CameraPhase {
        case capture
        case preview
        case posting
        case success
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch currentPhase {
            case .capture:
                CameraView(
                    cameraManager: model.cameraManager,
                    isPresented: $isPresented,
                    taskTitle: taskTitle,
                    taskId: taskId,
                    onPhotoTaken: { backImage, frontImage in
                        print("🔥🔥🔥 EnhancedCameraView: onPhotoTaken called with images")
                        self.capturedImage = backImage

                        // DIRECT CALLBACK: Skip the preview/post flow and call callback directly
                        print("🔥🔥🔥 EnhancedCameraView: Calling onPhotoPosted directly")
                        let watermarkedImage = model.cameraManager.addTimestampWatermark(to: backImage, taskTitle: taskTitle)
                        self.onPhotoPosted(watermarkedImage)

                        // Dismiss camera after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.dismissCamera()
                        }
                    }
                )
            case .preview:
                PreviewView(
                    image: capturedImage,
                    onRetake: handleRetake,
                    onPost: handlePost
                )
            case .posting:
                PostingView()
            case .success:
                SuccessView(onDismiss: dismissCamera)
            }

            // Top bar with task title and close button
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Task Verification")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text(taskTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    Button(action: dismissCamera) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Initialize camera system when view appears
            model.cameraManager.setupDualCameraSystem()
        }
        .onDisappear {
            // Stop camera session when view disappears
            model.cameraManager.stopCameraSession()
        }
        .alert("Camera Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func handlePhotoCapture() {
        isProcessing = true

        model.cameraManager.capturePhoto { [self] backImage, frontImage in
            DispatchQueue.main.async {
                self.isProcessing = false

                if let backImage = backImage {
                    self.capturedImage = backImage
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.currentPhase = .preview
                    }
                } else {
                    self.errorMessage = "Failed to capture photo. Please try again."
                    self.showingError = true
                }
            }
        }
    }

    private func handleRetake() {
        // Reset the sequential capture flow
        model.cameraManager.resetCaptureFlow()

        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = .capture
            capturedImage = nil
        }
    }

    private func handlePost() {
        guard let image = capturedImage else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = .posting
        }

        // Apply watermark
        let watermarkedImage = model.cameraManager.addTimestampWatermark(to: image, taskTitle: taskTitle)

        // Save photo to task and dismiss immediately (no auto-completion)
        print("📸 CRITICAL: About to call onPhotoPosted callback with watermarked image")
        print("📸 CRITICAL: Watermarked image size: \(watermarkedImage.size)")
        print("📸 CRITICAL: Task title: \(taskTitle), Task ID: \(taskId)")
        self.onPhotoPosted(watermarkedImage)
        print("📸 CRITICAL: onPhotoPosted callback completed")

        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentPhase = .success
        }

        // Dismiss camera quickly so user can see the "Complete" button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🏁 Dismissing camera - user should now see Complete button")
            print("🏁 About to call dismissCamera() and onPhotoPosted callback")
            self.dismissCamera()
        }
    }

    private func dismissCamera() {
        print("🚪 Dismissing camera view")
        DispatchQueue.main.async {
            self.isPresented = false
            print("✅ Camera dismissed")
        }
    }
}

struct CaptureView: View {
    let onCapture: () -> Void
    @EnvironmentObject var model: EnhancedScreenTimeModel

    var body: some View {
        ZStack {
            // Camera preview background
            Rectangle()
                .fill(Color.black)
                .onAppear {
                    // Ensure camera session is started
                    model.cameraManager.startCameraSession()
                }
                .overlay(
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))

                        Text("Dual Camera Ready")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))

                            .padding(.horizontal)
                    }
                )

            // Camera status indicator
            VStack {
                HStack {
                    Spacer()
                    CameraStatusIndicator(status: model.cameraManager.cameraStatus)
                        .padding()
                }
                Spacer()
            }

            // Capture controls
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button(action: onCapture) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)

                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 70, height: 70)

                            if model.cameraManager.isCapturing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    .disabled(model.cameraManager.isCapturing || model.cameraManager.cameraStatus == .failed)

                    Spacer()
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct PreviewView: View {
    let image: UIImage?
    let onRetake: () -> Void
    let onPost: () -> Void
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var showMainAsBack = true // true = back camera main, false = front camera main

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Main photo and overlay
            if let backImage = model.cameraManager.backCameraImage,
               let frontImage = model.cameraManager.frontCameraImage {

                // Main photo (larger)
                Image(uiImage: showMainAsBack ? backImage : frontImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                // Overlay photo (smaller, top-right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: swapPhotos) {
                            Image(uiImage: showMainAsBack ? frontImage : backImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                    }
                    Spacer()
                }
            } else if let image = image {
                // Fallback to single image if dual photos not available
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
            }

            // Controls
            VStack {
                Spacer()

                HStack(spacing: 40) {
                    // Retake button
                    Button(action: onRetake) {
                        VStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                            Text("Retake")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                    }

                    // Accept button
                    Button(action: onPost) {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Accept")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(12)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }

    private func swapPhotos() {
        showMainAsBack.toggle()
        print("📱 Photos swapped - Main camera: \(showMainAsBack ? "Back" : "Front")")
    }
}

struct PostingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Posting to feed...")
                .font(.headline)
                .foregroundColor(.white)

            Text("Adding watermark and sharing with friends")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

struct SuccessView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 10) {
                Text("Photos Saved!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Click the Complete button to finish your task")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(width: 120, height: 44)
                    .background(Color.white)
                    .cornerRadius(22)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

struct CameraStatusIndicator: View {
    let status: CameraManager.CameraStatus

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch status {
        case .ready:
            return .green
        case .frontOnly, .backOnly:
            return .orange
        case .initializing, .capturing:
            return .yellow
        case .failed:
            return .red
        }
    }

    private var statusText: String {
        switch status {
        case .initializing:
            return "Setting up..."
        case .ready:
            return "Ready"
        case .frontOnly:
            return "Front camera only"
        case .backOnly:
            return "Back camera only"
        case .capturing:
            return "Capturing..."
        case .failed:
            return "Camera error"
        }
    }
}

// MARK: - Toast Notification View
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            if isShowing && !message.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.green)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isShowing)
    }
}

// MARK: - Level System
struct UserLevel {
    let currentLevel: Int
    let currentLevelXP: Int // XP at start of current level
    let nextLevelXP: Int    // XP needed for next level
    let progressInLevel: Int // XP earned in current level
    let totalXP: Int

    init(totalXP: Int) {
        self.totalXP = totalXP

        // Calculate level based on XP thresholds
        // Level 1: 0-100, Level 2: 100-250, Level 3: 250-500, Level 4: 500-1000, etc.
        var level = 1
        var xpForCurrentLevel = 0
        var xpForNextLevel = 100

        while totalXP >= xpForNextLevel {
            level += 1
            xpForCurrentLevel = xpForNextLevel
            xpForNextLevel = xpForCurrentLevel + (level * 100) // Exponential growth
        }

        self.currentLevel = level
        self.currentLevelXP = xpForCurrentLevel
        self.nextLevelXP = xpForNextLevel
        self.progressInLevel = totalXP - xpForCurrentLevel
    }

    var progressPercentage: Double {
        let xpNeededForLevel = nextLevelXP - currentLevelXP
        return Double(progressInLevel) / Double(xpNeededForLevel)
    }
}

// MARK: - Level Progress Bar
struct LevelProgressBar: View {
    let userLevel: UserLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Level \(userLevel.currentLevel)")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text("\(userLevel.progressInLevel)/\(userLevel.nextLevelXP - userLevel.currentLevelXP) XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Progress gradient
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue, .cyan, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * userLevel.progressPercentage, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: userLevel.progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    struct ConfettiPiece: Identifiable {
        let id = UUID()
        let color: Color
        let x: CGFloat
        let y: CGFloat
        let rotation: Double
        let scale: CGFloat
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Circle()
                        .fill(piece.color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(piece.scale)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

        for _ in 0..<50 {
            confettiPieces.append(
                ConfettiPiece(
                    color: colors.randomElement()!,
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: -50...size.height/2),
                    rotation: Double.random(in: 0...360),
                    scale: CGFloat.random(in: 0.5...1.5)
                )
            )
        }
    }
}

// MARK: - Level Up Popup
struct LevelUpPopup: View {
    let level: Int
    @Binding var isShowing: Bool

    private var encouragementMessage: String {
        let messages = [
            "Amazing! You're crushing it! 🎉",
            "Wow! Keep up the incredible work! 🌟",
            "Fantastic! You're on fire! 🔥",
            "Awesome! You're leveling up fast! 🚀",
            "Incredible! Keep going strong! 💪",
            "Outstanding! You're doing great! ⭐",
            "Brilliant! Way to go! 🎊",
            "Superb! You're unstoppable! 🏆"
        ]
        return messages.randomElement() ?? "Great job! 🎉"
    }

    var body: some View {
        if isShowing {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }

                VStack(spacing: 20) {
                    Text("🎉 LEVEL UP! 🎉")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Level \(level)")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundColor(.yellow)

                    Text(encouragementMessage)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button(action: {
                        withAnimation {
                            isShowing = false
                        }
                    }) {
                        Text("Keep Going!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.95), .blue.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(40)
                .scaleEffect(isShowing ? 1.0 : 0.5)
                .opacity(isShowing ? 1.0 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
            }
        }
    }
}

// MARK: - Streak Fire Animation
struct StreakFireAnimation: View {
    let streak: Int
    @Binding var isShowing: Bool

    @State private var flames: [FlameParticle] = []
    @State private var scale: CGFloat = 0.5

    struct FlameParticle: Identifiable {
        let id = UUID()
        let xOffset: CGFloat
        let yOffset: CGFloat
        let size: CGFloat
        let delay: Double
    }

    var body: some View {
        if isShowing {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }

                VStack(spacing: 24) {
                    // Animated flames
                    ZStack {
                        ForEach(flames) { flame in
                            Text("🔥")
                                .font(.system(size: flame.size))
                                .offset(x: flame.xOffset, y: flame.yOffset)
                                .opacity(isShowing ? 1.0 : 0)
                                .animation(
                                    .easeOut(duration: 0.8).delay(flame.delay),
                                    value: isShowing
                                )
                        }
                    }
                    .frame(height: 150)

                    // Streak number
                    Text("\(streak)")
                        .font(.system(size: 80, weight: .heavy))
                        .foregroundColor(.orange)

                    Text("Day Streak!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .scaleEffect(scale)
                .onAppear {
                    // Generate flame particles
                    for i in 0..<8 {
                        let angle = Double(i) * (360.0 / 8.0) * .pi / 180.0
                        let radius: CGFloat = 50
                        flames.append(FlameParticle(
                            xOffset: cos(angle) * radius,
                            yOffset: sin(angle) * radius,
                            size: CGFloat.random(in: 40...60),
                            delay: Double(i) * 0.05
                        ))
                    }

                    // Scale animation
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        scale = 1.0
                    }

                    // Auto-hide after 2.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Streak Lost Alert
struct StreakLostAlert: View {
    let lostStreak: Int
    @Binding var isShowing: Bool
    @State private var dismissing = false
    @State private var finalPosition: CGPoint = .zero

    var body: some View {
        if isShowing {
            ZStack {
                // Background
                if !dismissing {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                // Alert box
                VStack(spacing: 20) {
                    Text("💔")
                        .font(.system(size: 60))

                    Text("Streak Lost")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("You lost your \(lostStreak) day streak")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("Start a new one today!")
                        .font(.subheadline)
                        .foregroundColor(.orange)

                    Button(action: {
                        startDismissAnimation()
                    }) {
                        Text("Got it")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(40)
                .scaleEffect(dismissing ? 0.1 : 1.0)
                .offset(
                    x: dismissing ? finalPosition.x : 0,
                    y: dismissing ? finalPosition.y : 0
                )
                .opacity(dismissing ? 0 : 1)
            }
        }
    }

    private func startDismissAnimation() {
        // Calculate position of streak card (approximate - bottom right area)
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        finalPosition = CGPoint(
            x: screenWidth / 2 - 100,
            y: -screenHeight / 2 + 300 // Approximate position of streak card
        )

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            dismissing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isShowing = false
            dismissing = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
