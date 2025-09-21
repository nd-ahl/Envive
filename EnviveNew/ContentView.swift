import SwiftUI
import FamilyControls
import ManagedSettings
import Combine
import AVFoundation
import UIKit
import CoreLocation
import MapKit
import UserNotifications

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
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            taskCompletedCategory,
            friendRequestCategory
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
    var currentLocation: CLLocationCoordinate2D?
    var isSharingLocation: Bool = false
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
    var location: String?
    var locationCoordinate: CLLocationCoordinate2D?
    var verificationPhoto: UIImage?
    var trackingData: [LocationTrackingPoint] = []
}

struct LocationTrackingPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let altitude: Double?
    let speed: Double?
    let distance: Double?
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
    let location: String?
    let locationCoordinate: CLLocationCoordinate2D?
    let kudos: Int
    let hasVerificationPhoto: Bool
    let verificationPhoto: UIImage?
    let trackingRoute: [CLLocationCoordinate2D]?
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isTracking = false
    @Published var trackingPoints: [LocationTrackingPoint] = []
    @Published var totalDistance: Double = 0
    @Published var currentSpeed: Double = 0
    @Published var averageSpeed: Double = 0
    @Published var currentAltitude: Double = 0
    @Published var trackingDuration: TimeInterval = 0
    @Published var locationError: String?
    @Published var friendLocations: [String: CLLocationCoordinate2D] = [:]
    
    private var trackingTimer: Timer?
    private var startTime: Date?
    private var lastLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        // Comment out background updates - requires special capabilities
        // locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = 5 // Update every 5 meters
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        // For background tracking during activities
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = "Location permission not granted"
            return
        }
        
        isTracking = true
        trackingPoints = []
        totalDistance = 0
        startTime = Date()
        lastLocation = nil
        
        locationManager.startUpdatingLocation()
        
        // Update timer for duration
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let start = self.startTime {
                self.trackingDuration = Date().timeIntervalSince(start)
            }
        }
    }
    
    func stopTracking() -> [LocationTrackingPoint] {
        isTracking = false
        locationManager.stopUpdatingLocation()
        trackingTimer?.invalidate()
        trackingTimer = nil
        
        let finalPoints = trackingPoints
        return finalPoints
    }
    
    func startLocationSharing() {
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationSharing() {
        if !isTracking {
            locationManager.stopUpdatingLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        if isTracking {
            // Calculate distance if we have a previous location
            if let lastLoc = lastLocation {
                let distance = location.distance(from: lastLoc)
                totalDistance += distance
            }
            
            // Update current metrics
            currentSpeed = max(0, location.speed * 3.6) // Convert m/s to km/h
            currentAltitude = location.altitude
            
            // Calculate average speed
            if let start = startTime {
                let duration = Date().timeIntervalSince(start)
                if duration > 0 {
                    averageSpeed = (totalDistance / 1000) / (duration / 3600) // km/h
                }
            }
            
            // Add tracking point
            let point = LocationTrackingPoint(
                coordinate: location.coordinate,
                timestamp: Date(),
                altitude: location.altitude,
                speed: location.speed,
                distance: totalDistance
            )
            trackingPoints.append(point)
            
            lastLocation = location
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = "Location error: \(error.localizedDescription)"
    }
    
    // MARK: - Helper Functions
    func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.2f km", meters / 1000)
        }
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var frontCameraImage: UIImage?
    @Published var backCameraImage: UIImage?
    @Published var isShowingCamera = false
    @Published var cameraError: String?

    var frontCaptureSession: AVCaptureSession?
    var backCaptureSession: AVCaptureSession?
    var frontPhotoOutput: AVCapturePhotoOutput?
    var backPhotoOutput: AVCapturePhotoOutput?

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
        checkCameraPermissions()
    }
    
    func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    DispatchQueue.main.async {
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
    
    func setupDualCamera() {
        frontCaptureSession = AVCaptureSession()
        backCaptureSession = AVCaptureSession()
        
        setupCaptureSession(session: frontCaptureSession!, position: .front)
        setupCaptureSession(session: backCaptureSession!, position: .back)
    }
    
    private func setupCaptureSession(session: AVCaptureSession, position: AVCaptureDevice.Position) {
        session.beginConfiguration()

        defer {
            // Always commit configuration, even if setup fails
            session.commitConfiguration()
        }

        // In simulator, create mock photo outputs without camera devices
        if isSimulator {
            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)

                if position == .front {
                    frontPhotoOutput = photoOutput
                } else {
                    backPhotoOutput = photoOutput
                }
            }
            return
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            cameraError = "Camera not available"
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)

                if position == .front {
                    frontPhotoOutput = photoOutput
                } else {
                    backPhotoOutput = photoOutput
                }
            }

        } catch {
            cameraError = "Camera setup failed: \(error.localizedDescription)"
        }
    }
    
    func takeDualPhoto() {
        // In simulator, generate mock images
        if isSimulator {
            generateMockImages()
            return
        }

        guard let frontOutput = frontPhotoOutput,
              let backOutput = backPhotoOutput else {
            cameraError = "Camera not ready"
            return
        }

        let settings = AVCapturePhotoSettings()

        frontOutput.capturePhoto(with: settings, delegate: self)
        backOutput.capturePhoto(with: settings, delegate: self)
    }

    private func generateMockImages() {
        // Create mock images for simulator testing
        let mockBackImage = createMockImage(text: "Back Camera\nMock Image", backgroundColor: .systemBlue)
        let mockFrontImage = createMockImage(text: "Front Camera\nMock Image", backgroundColor: .systemGreen)

        DispatchQueue.main.async {
            self.backCameraImage = mockBackImage
            self.frontCameraImage = mockFrontImage
            self.capturedImage = self.combineDualImages()
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
    
    func startSession() {
        // Don't start camera sessions in simulator
        guard !isSimulator else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            if let frontSession = self.frontCaptureSession, !frontSession.isRunning {
                frontSession.startRunning()
            }
            if let backSession = self.backCaptureSession, !backSession.isRunning {
                backSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        // Don't stop camera sessions in simulator
        guard !isSimulator else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            if let frontSession = self.frontCaptureSession, frontSession.isRunning {
                frontSession.stopRunning()
            }
            if let backSession = self.backCaptureSession, backSession.isRunning {
                backSession.stopRunning()
            }
        }
    }
    
    func addTimestampWatermark(to image: UIImage, taskTitle: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            image.draw(at: .zero)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            let timestamp = formatter.string(from: Date())
            let watermarkText = "\(taskTitle) • \(timestamp)"
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -1.0
            ]
            
            let textSize = watermarkText.size(withAttributes: attributes)
            let padding: CGFloat = 15
            let textRect = CGRect(
                x: image.size.width - textSize.width - padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )
            
            let backgroundRect = CGRect(
                x: textRect.origin.x - 8,
                y: textRect.origin.y - 4,
                width: textSize.width + 16,
                height: textSize.height + 8
            )
            
            context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 6)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.fillPath()
            
            watermarkText.draw(in: textRect, withAttributes: attributes)
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
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            cameraError = "Failed to capture photo"
            return
        }
        
        DispatchQueue.main.async {
            if output == self.frontPhotoOutput {
                self.frontCameraImage = image
            } else if output == self.backPhotoOutput {
                self.backCameraImage = image
            }
            
            if self.frontCameraImage != nil && self.backCameraImage != nil {
                self.capturedImage = self.combineDualImages()
            }
        }
    }
}

// MARK: - Enhanced Screen Time Model with Friends
class EnhancedScreenTimeModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var selectedAppsToDiscourage: FamilyActivitySelection = FamilyActivitySelection()
    @Published var authorizationStatus: String = "Not Requested"
    @Published var minutesEarned: Int = 45
    @Published var xpBalance: Int = 0
    @Published var isSessionActive = false
    @Published var sessionTimeRemaining: TimeInterval = 0
    
    // Social Features
    @Published var currentUser: User = User(username: "You", xpBalance: 0, totalXPEarned: 0, credibilityScore: 100.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false, currentLocation: nil, isSharingLocation: false)
    @Published var friends: [User] = []
    @Published var recentTasks: [TaskItem] = []
    @Published var friendActivities: [FriendActivity] = []
    
    // Friend Management
    @Published var searchResults: [User] = []
    @Published var pendingFriendRequests: [User] = []
    @Published var sentFriendRequests: [User] = []
    @Published var allUsers: [User] = []
    @Published var isSearching = false
    
    // Camera
    @Published var cameraManager = CameraManager()
    
    // Location
    @Published var locationManager = LocationManager()

    // Notifications
    @Published var notificationManager = NotificationManager()

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private var sessionTimer: Timer?
    private var sessionWarningTimer: Timer?
    
    init() {
        checkAuthorizationStatus()
        loadMockData()
        setupMockUserDatabase()
        setupLocationTracking()

        // Request notification permission on init
        notificationManager.requestPermission()
    }
    
    // MARK: - Location Methods
    func setupLocationTracking() {
        // Request location permission on init
        locationManager.requestPermission()
    }
    
    func startLocationSharing() {
        currentUser.isSharingLocation = true
        locationManager.startLocationSharing()
        
        // Update current location
        if let location = locationManager.currentLocation {
            currentUser.currentLocation = location.coordinate
        }
    }
    
    func stopLocationSharing() {
        currentUser.isSharingLocation = false
        locationManager.stopLocationSharing()
    }
    
    func startTrackingForTask(_ task: TaskItem) {
        locationManager.startTracking()
    }
    
    func stopTrackingForTask(_ task: TaskItem) -> [LocationTrackingPoint] {
        return locationManager.stopTracking()
    }
    
    // MARK: - Friend Management
    func setupMockUserDatabase() {
        // Adding location coordinates for mock users (around Salt Lake City area)
        allUsers = [
            User(username: "Oliver", xpBalance: 120, totalXPEarned: 580, credibilityScore: 95.0, friends: [], pendingFriendRequests: [], isParentallyManaged: true, 
                 currentLocation: CLLocationCoordinate2D(latitude: 40.7608, longitude: -111.8910), isSharingLocation: true),
            User(username: "Emma", xpBalance: 85, totalXPEarned: 420, credibilityScore: 88.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false,
                 currentLocation: CLLocationCoordinate2D(latitude: 40.7500, longitude: -111.8833), isSharingLocation: false),
            User(username: "Jake", xpBalance: 200, totalXPEarned: 750, credibilityScore: 92.0, friends: [], pendingFriendRequests: [], isParentallyManaged: true,
                 currentLocation: CLLocationCoordinate2D(latitude: 40.7780, longitude: -111.8882), isSharingLocation: true),
            User(username: "Sophia", xpBalance: 150, totalXPEarned: 650, credibilityScore: 90.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false,
                 currentLocation: CLLocationCoordinate2D(latitude: 40.7400, longitude: -111.8700), isSharingLocation: true),
            User(username: "Alex", xpBalance: 75, totalXPEarned: 300, credibilityScore: 85.0, friends: [], pendingFriendRequests: [], isParentallyManaged: true),
            User(username: "Maya", xpBalance: 180, totalXPEarned: 820, credibilityScore: 97.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false,
                 currentLocation: CLLocationCoordinate2D(latitude: 40.7550, longitude: -111.8900), isSharingLocation: true),
            User(username: "Noah", xpBalance: 95, totalXPEarned: 480, credibilityScore: 87.0, friends: [], pendingFriendRequests: [], isParentallyManaged: true),
            User(username: "Zoe", xpBalance: 220, totalXPEarned: 900, credibilityScore: 94.0, friends: [], pendingFriendRequests: [], isParentallyManaged: false,
                 currentLocation: CLLocationCoordinate2D(latitude: 40.7650, longitude: -111.8850), isSharingLocation: true)
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
        friends.removeAll { $0.username == user.username }
        currentUser.friends.removeAll { $0 == user.username }
        
        if let index = allUsers.firstIndex(where: { $0.username == user.username }) {
            allUsers[index].friends.removeAll { $0 == currentUser.username }
        }
        
        print("Removed \(user.username) from friends")
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
    func completeTaskWithPhoto(_ task: TaskItem, photo: UIImage?) {
        let credibilityMultiplier = currentUser.credibilityScore / 100.0
        let earnedXP = Int(Double(task.xpReward) * credibilityMultiplier)
        
        xpBalance += earnedXP
        currentUser.xpBalance += earnedXP
        currentUser.totalXPEarned += earnedXP
        
        if let index = recentTasks.firstIndex(where: { $0.id == task.id }) {
            recentTasks[index].verificationPhoto = photo
            recentTasks[index].completed = true
            recentTasks[index].completedAt = Date()
        }
        
        let activity = FriendActivity(
            userId: currentUser.id.uuidString,
            username: currentUser.username,
            activity: "Completed: \(task.title)",
            xpEarned: earnedXP,
            timestamp: Date(),
            location: task.location,
            locationCoordinate: task.locationCoordinate,
            kudos: 0,
            hasVerificationPhoto: photo != nil,
            verificationPhoto: photo,
            trackingRoute: nil
        )
        
        friendActivities.insert(activity, at: 0)
        
        print("Completed task: \(task.title) for \(earnedXP) XP with photo verification")

        // Send notification to friends about task completion
        notificationManager.sendFriendCompletedTaskNotification(
            friendName: currentUser.username,
            taskTitle: task.title,
            xpEarned: earnedXP,
            hasPhoto: photo != nil
        )
    }
    
    // MARK: - Original Methods
    func loadMockData() {
        recentTasks = [
            TaskItem(title: "Morning run", category: .exercise, xpReward: 25, estimatedMinutes: 30, isCustom: false, completed: false, createdBy: currentUser.id.uuidString, isGroupTask: false, participants: [], verificationRequired: true, location: nil, locationCoordinate: nil, verificationPhoto: nil, trackingData: []),
            TaskItem(title: "Clean room", category: .chores, xpReward: 15, estimatedMinutes: 20, isCustom: false, completed: false, createdBy: currentUser.id.uuidString, isGroupTask: false, participants: [], verificationRequired: true, location: nil, locationCoordinate: nil, verificationPhoto: nil, trackingData: []),
            TaskItem(title: "Study math", category: .study, xpReward: 30, estimatedMinutes: 45, isCustom: false, completed: false, createdBy: currentUser.id.uuidString, isGroupTask: false, participants: [], verificationRequired: false, location: nil, locationCoordinate: nil, verificationPhoto: nil, trackingData: [])
        ]
        
        friendActivities = [
            FriendActivity(userId: "1", username: "Oliver", activity: "Completed a 5-mile hike", xpEarned: 40, timestamp: Date().addingTimeInterval(-3600), location: "Little Cottonwood Canyon", locationCoordinate: CLLocationCoordinate2D(latitude: 40.5734, longitude: -111.7551), kudos: 3, hasVerificationPhoto: true, verificationPhoto: nil, trackingRoute: nil),
            FriendActivity(userId: "2", username: "Emma", activity: "Finished homework", xpEarned: 25, timestamp: Date().addingTimeInterval(-7200), location: nil, locationCoordinate: nil, kudos: 1, hasVerificationPhoto: false, verificationPhoto: nil, trackingRoute: nil),
            FriendActivity(userId: "3", username: "Jake", activity: "Helped with dishes", xpEarned: 15, timestamp: Date().addingTimeInterval(-10800), location: nil, locationCoordinate: nil, kudos: 2, hasVerificationPhoto: true, verificationPhoto: nil, trackingRoute: nil)
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
        guard isAuthorized else { return }
        store.clearAllSettings()
        
        if !selectedAppsToDiscourage.applications.isEmpty {
            let applicationTokens = Set(selectedAppsToDiscourage.applications.compactMap { $0.token })
            store.shield.applications = applicationTokens
        }
        
        if !selectedAppsToDiscourage.categories.isEmpty {
            let categoryTokens = Set(selectedAppsToDiscourage.categories.compactMap { $0.token })
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(categoryTokens)
        }
    }
    
    func removeAppRestrictions() {
        guard isAuthorized else { return }
        store.clearAllSettings()
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
            location: task.location,
            locationCoordinate: task.locationCoordinate,
            kudos: 0,
            hasVerificationPhoto: task.verificationRequired,
            verificationPhoto: nil,
            trackingRoute: nil
        )
        
        friendActivities.insert(activity, at: 0)
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
            verificationRequired: category == .exercise || category == .chores,
            location: nil,
            locationCoordinate: nil,
            verificationPhoto: nil,
            trackingData: []
        )
        
        recentTasks.insert(newTask, at: 0)
        return newTask
    }
    
    func calculateXPForTask(category: TaskCategory, minutes: Int) -> Int {
        let baseXPPerMinute: Double
        
        switch category {
        case .exercise:
            baseXPPerMinute = 1.2
        case .study:
            baseXPPerMinute = 1.5
        case .chores:
            baseXPPerMinute = 0.8
        case .creative:
            baseXPPerMinute = 1.0
        case .outdoor:
            baseXPPerMinute = 1.3
        case .health:
            baseXPPerMinute = 1.1
        case .social:
            baseXPPerMinute = 0.7
        case .custom:
            baseXPPerMinute = 1.0
        }
        
        return max(5, Int(Double(minutes) * baseXPPerMinute))
    }
    
    func convertXPToMinutes(conversionRate: Int = 5) {
        let newMinutes = xpBalance / conversionRate
        let usedXP = newMinutes * conversionRate
        
        minutesEarned += newMinutes
        xpBalance -= usedXP
        currentUser.xpBalance -= usedXP
    }
    
    func startEarnedSession(duration: Int) {
        guard duration <= minutesEarned, !isSessionActive else { return }
        
        removeAppRestrictions()
        isSessionActive = true
        sessionTimeRemaining = TimeInterval(duration * 60)
        minutesEarned -= duration
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.sessionTimeRemaining > 0 {
                    self.sessionTimeRemaining -= 1
                } else {
                    self.endSession()
                }
            }
        }
    }
    
    func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        isSessionActive = false
        sessionTimeRemaining = 0
        startAppRestrictions()
    }
    
    func pauseSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        sessionWarningTimer?.invalidate()
        sessionWarningTimer = nil
        isSessionActive = false
        startAppRestrictions()
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
            location: nil,
            locationCoordinate: nil,
            kudos: 0,
            hasVerificationPhoto: Bool.random(),
            verificationPhoto: nil,
            trackingRoute: nil
        )

        friendActivities.insert(friendActivity, at: 0)
    }
}

// MARK: - Location Tracking View
struct LocationTrackingView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7608, longitude: -111.8910),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingShareOptions = false
    let taskTitle: String
    let onStop: ([LocationTrackingPoint]) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Map View
            Map(coordinateRegion: $region, 
                showsUserLocation: true,
                annotationItems: locationManager.trackingPoints) { point in
                MapPin(coordinate: point.coordinate, tint: .blue)
            }
            .frame(height: 300)
            .overlay(
                VStack {
                    HStack {
                        Label(taskTitle, systemImage: "location.fill")
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            )
            
            // Stats Dashboard
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    StatBox(
                        title: "Distance",
                        value: locationManager.formatDistance(locationManager.totalDistance),
                        icon: "ruler",
                        color: .blue
                    )
                    
                    StatBox(
                        title: "Duration",
                        value: locationManager.formatDuration(locationManager.trackingDuration),
                        icon: "clock",
                        color: .green
                    )
                }
                
                HStack(spacing: 20) {
                    StatBox(
                        title: "Speed",
                        value: String(format: "%.1f km/h", locationManager.currentSpeed),
                        icon: "speedometer",
                        color: .orange
                    )
                    
                    StatBox(
                        title: "Altitude",
                        value: String(format: "%.0f m", locationManager.currentAltitude),
                        icon: "mountain.2",
                        color: .purple
                    )
                }
                
                HStack(spacing: 20) {
                    StatBox(
                        title: "Avg Speed",
                        value: String(format: "%.1f km/h", locationManager.averageSpeed),
                        icon: "gauge",
                        color: .teal
                    )
                    
                    StatBox(
                        title: "Points",
                        value: "\(locationManager.trackingPoints.count)",
                        icon: "mappin.circle",
                        color: .indigo
                    )
                }
                
                // Control Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        showingShareOptions = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        let points = locationManager.stopTracking()
                        onStop(points)
                    }) {
                        Label("Stop Tracking", systemImage: "stop.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.top)
            }
            .padding()
            
            Spacer()
        }
        .onAppear {
            if let location = locationManager.currentLocation {
                region.center = location.coordinate
            }
        }
        .onReceive(locationManager.$currentLocation) { location in
            if let loc = location {
                withAnimation {
                    region.center = loc.coordinate
                }
            }
        }
        .sheet(isPresented: $showingShareOptions) {
            ShareLocationView(trackingPoints: locationManager.trackingPoints)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ShareLocationView: View {
    let trackingPoints: [LocationTrackingPoint]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        // Share to friends
                    }) {
                        Label("Share with Friends", systemImage: "person.2")
                    }
                    
                    Button(action: {
                        // Export GPX
                    }) {
                        Label("Export as GPX", systemImage: "doc.text")
                    }
                    
                    Button(action: {
                        // Share screenshot
                    }) {
                        Label("Share Screenshot", systemImage: "camera")
                    }
                }
            }
            .navigationTitle("Share Activity")
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

// MARK: - Friend Map View (Updated for iOS 17)
struct FriendMapView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7608, longitude: -111.8910),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedFriend: User?
    
    var sharingFriends: [User] {
        model.friends.filter { $0.isSharingLocation && $0.currentLocation != nil }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Simple Map without annotations for iOS 17
                Map(coordinateRegion: $region, showsUserLocation: true)
                    .overlay(
                        VStack {
                            HStack {
                                if model.currentUser.isSharingLocation {
                                    Label("Sharing Location", systemImage: "location.fill")
                                        .padding(8)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                } else {
                                    Label("Location Off", systemImage: "location.slash")
                                        .padding(8)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding()
                    )
                
                // Friend List with Location
                List {
                    Section("Friends Sharing Location") {
                        ForEach(sharingFriends) { friend in
                            HStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(friend.username.prefix(1)))
                                            .fontWeight(.semibold)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text(friend.username)
                                        .fontWeight(.medium)
                                    if let location = friend.currentLocation {
                                        Text("Lat: \(location.latitude, specifier: "%.4f"), Lon: \(location.longitude, specifier: "%.4f")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if let location = friend.currentLocation {
                                        withAnimation {
                                            region.center = location
                                            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        }
                                    }
                                }) {
                                    Image(systemName: "location.circle")
                                }
                                .buttonStyle(.borderless)
                            }
                            .onTapGesture {
                                selectedFriend = friend
                            }
                        }
                    }
                    
                    Section {
                        Toggle("Share My Location", isOn: Binding(
                            get: { model.currentUser.isSharingLocation },
                            set: { newValue in
                                if newValue {
                                    model.startLocationSharing()
                                } else {
                                    model.stopLocationSharing()
                                }
                            }
                        ))
                    }
                }
                .frame(height: 250)
            }
            .navigationTitle("Friend Locations")
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend)
            }
        }
    }
}

struct FriendDetailView: View {
    let friend: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(friend.username.prefix(1)))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(friend.username)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("\(friend.totalXPEarned) Total XP")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Stats") {
                    HStack {
                        Text("Current XP")
                        Spacer()
                        Text("\(friend.xpBalance)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Credibility")
                        Spacer()
                        Text("\(Int(friend.credibilityScore))%")
                            .fontWeight(.semibold)
                    }
                    
                    if friend.isSharingLocation {
                        HStack {
                            Text("Location")
                            Spacer()
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                            Text("Sharing")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle(friend.username)
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
struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var cameraManager: CameraManager
    @Binding var isPresented: Bool
    let taskTitle: String
    let onPhotoTaken: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.cameraManager = cameraManager
        controller.taskTitle = taskTitle
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
    var onPhotoTaken: ((UIImage) -> Void)?
    var onDismiss: (() -> Void)?
    
    private var frontPreviewLayer: AVCaptureVideoPreviewLayer?
    private var backPreviewLayer: AVCaptureVideoPreviewLayer?
    private var countdownLabel: UILabel?
    private var captureButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        let backPreviewView = UIView()
        backPreviewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backPreviewView)
        
        let frontPreviewView = UIView()
        frontPreviewView.translatesAutoresizingMaskIntoConstraints = false
        frontPreviewView.layer.borderColor = UIColor.white.cgColor
        frontPreviewView.layer.borderWidth = 2
        frontPreviewView.layer.cornerRadius = 10
        frontPreviewView.clipsToBounds = true
        view.addSubview(frontPreviewView)
        
        let captureButton = UIButton(type: .system)
        captureButton.setTitle("📸 Capture", for: .normal)
        captureButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        captureButton.backgroundColor = UIColor.systemBlue
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.layer.cornerRadius = 25
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        view.addSubview(captureButton)
        self.captureButton = captureButton
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        let taskLabel = UILabel()
        taskLabel.text = "Verifying: \(taskTitle)"
        taskLabel.textColor = .white
        taskLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        taskLabel.textAlignment = .center
        taskLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        taskLabel.layer.cornerRadius = 8
        taskLabel.clipsToBounds = true
        taskLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(taskLabel)
        
        let countdownLabel = UILabel()
        countdownLabel.text = ""
        countdownLabel.textColor = .white
        countdownLabel.font = UIFont.systemFont(ofSize: 72, weight: .bold)
        countdownLabel.textAlignment = .center
        countdownLabel.alpha = 0
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(countdownLabel)
        self.countdownLabel = countdownLabel
        
        NSLayoutConstraint.activate([
            backPreviewView.topAnchor.constraint(equalTo: view.topAnchor),
            backPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backPreviewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            frontPreviewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            frontPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            frontPreviewView.widthAnchor.constraint(equalToConstant: 120),
            frontPreviewView.heightAnchor.constraint(equalToConstant: 160),
            
            taskLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            taskLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            taskLabel.heightAnchor.constraint(equalToConstant: 40),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.leadingAnchor.constraint(equalTo: taskLabel.trailingAnchor, constant: 10),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 150),
            captureButton.heightAnchor.constraint(equalToConstant: 50),
            
            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            countdownLabel.widthAnchor.constraint(equalToConstant: 200),
            countdownLabel.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        if let frontSession = cameraManager?.frontCaptureSession {
            frontPreviewLayer = AVCaptureVideoPreviewLayer(session: frontSession)
            frontPreviewLayer?.videoGravity = .resizeAspectFill
            frontPreviewLayer?.frame = frontPreviewView.bounds
            frontPreviewView.layer.addSublayer(frontPreviewLayer!)
        }
        
        if let backSession = cameraManager?.backCaptureSession {
            backPreviewLayer = AVCaptureVideoPreviewLayer(session: backSession)
            backPreviewLayer?.videoGravity = .resizeAspectFill
            backPreviewLayer?.frame = backPreviewView.bounds
            backPreviewView.layer.addSublayer(backPreviewLayer!)
        }
    }
    
    private func setupCamera() {
        cameraManager?.setupDualCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraManager?.startSession()
        
        DispatchQueue.main.async {
            self.frontPreviewLayer?.frame = self.view.subviews[1].bounds
            self.backPreviewLayer?.frame = self.view.subviews[0].bounds
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cameraManager?.stopSession()
    }
    
    @objc private func captureButtonTapped() {
        startCountdown()
    }
    
    private func startCountdown() {
        captureButton?.isEnabled = false
        captureButton?.alpha = 0.5
        
        var count = 3
        
        func showNextNumber() {
            if count > 0 {
                countdownLabel?.text = "\(count)"
                countdownLabel?.alpha = 1.0
                countdownLabel?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                
                UIView.animate(withDuration: 0.6, animations: {
                    self.countdownLabel?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.4, animations: {
                        self.countdownLabel?.alpha = 0
                        self.countdownLabel?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }, completion: { _ in
                        count -= 1
                        showNextNumber()
                    })
                })
            } else {
                self.countdownLabel?.text = "CLICK!"
                self.countdownLabel?.alpha = 1.0
                self.countdownLabel?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.countdownLabel?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.2, animations: {
                        self.countdownLabel?.alpha = 0
                        self.countdownLabel?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }, completion: { _ in
                        self.takePictureNow()
                    })
                })
            }
        }
        
        showNextNumber()
    }
    
    private func takePictureNow() {
        cameraManager?.takeDualPhoto()
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let combinedImage = self.cameraManager?.capturedImage {
                let timestampedImage = self.cameraManager?.addTimestampWatermark(to: combinedImage, taskTitle: self.taskTitle) ?? combinedImage
                self.onPhotoTaken?(timestampedImage)
                self.onDismiss?()
            }
            
            self.captureButton?.isEnabled = true
            self.captureButton?.alpha = 1.0
        }
    }
    
    @objc private func closeButtonTapped() {
        onDismiss?()
    }
}

// MARK: - Screen Time View
struct ScreenTimeView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var isPickerPresented = false

    var body: some View {
        NavigationView {
            List {
                Section("Authorization") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(model.authorizationStatus)
                            .foregroundColor(model.isAuthorized ? .green : .orange)
                    }

                    if !model.isAuthorized {
                        Button("Request Screen Time Permission") {
                            Task {
                                await model.requestAuthorization()
                            }
                        }
                    }
                }

                if model.isAuthorized {
                    Section("App Selection") {
                        Button("Choose Apps to Restrict") {
                            isPickerPresented = true
                        }
                        .familyActivityPicker(
                            isPresented: $isPickerPresented,
                            selection: $model.selectedAppsToDiscourage
                        )
                    }

                    Section("Manual Controls") {
                        Button("Apply Restrictions Now") {
                            model.startAppRestrictions()
                        }
                        .foregroundColor(.red)

                        Button("Remove All Restrictions") {
                            model.removeAppRestrictions()
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Screen Time")
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var showingNotificationSettings = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(model.currentUser.username.prefix(1)))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            )

                        VStack(alignment: .leading) {
                            Text(model.currentUser.username)
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

                    HStack {
                        Text("Friends")
                        Spacer()
                        Text("\(model.friends.count)")
                            .fontWeight(.semibold)
                    }
                }

                Section("Settings") {
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

                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.blue)
                        Text("Location Sharing")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { model.currentUser.isSharingLocation },
                            set: { newValue in
                                if newValue {
                                    model.startLocationSharing()
                                } else {
                                    model.stopLocationSharing()
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                }

                Section {
                    Button("Test Friend Activity Notification") {
                        model.simulateFriendActivity()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
                    .environmentObject(model)
            }
        }
    }
}

// MARK: - Main App Structure
struct ContentView: View {
    @StateObject private var model = EnhancedScreenTimeModel()
    @State private var selectedTab = 0
    @State private var showingNotificationSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EnhancedHomeView()
                .environmentObject(model)
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
            
            FriendsView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
                .tag(2)
                .badge(model.pendingFriendRequests.count)
            
            FriendMapView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(3)
            
            ScreenTimeView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "hourglass")
                    Text("Screen Time")
                }
                .tag(4)
            
            ProfileView()
                .environmentObject(model)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(5)
        }
        .onAppear {
            // Request permissions
            model.locationManager.requestPermission()
            model.notificationManager.requestPermission()
            
            // Clear badge when app opens
            model.notificationManager.clearBadge()
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

// MARK: - Enhanced Task Row with Camera
struct EnhancedTaskRow: View {
    let task: TaskItem
    let onComplete: () -> Void
    let onCompleteWithPhoto: (UIImage) -> Void
    
    @EnvironmentObject var model: EnhancedScreenTimeModel
    @State private var showingCamera = false
    @State private var showingLocationTracking = false
    
    var needsLocationTracking: Bool {
        task.category == .outdoor || task.category == .exercise
    }
    
    var body: some View {
        HStack {
            Button(action: {
                if !task.completed {
                    if task.verificationRequired {
                        showingCamera = true
                    } else if needsLocationTracking {
                        model.startTrackingForTask(task)
                        showingLocationTracking = true
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
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.completed)
                
                HStack {
                    Text(task.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("\(task.xpReward) XP")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("~\(task.estimatedMinutes)m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if task.verificationRequired {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
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
                
                if task.completed && !task.trackingData.isEmpty {
                    HStack {
                        Image(systemName: "map")
                            .font(.caption)
                        Text("\(task.trackingData.count) location points tracked")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            if !task.completed {
                VStack(spacing: 8) {
                    if needsLocationTracking {
                        Button(action: {
                            model.startTrackingForTask(task)
                            showingLocationTracking = true
                        }) {
                            Label("Track", systemImage: "location.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.blue)
                    }

                    if task.verificationRequired {
                        Button("📸 Verify") {
                            showingCamera = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    if !needsLocationTracking && !task.verificationRequired {
                        Button("Complete") {
                            onComplete()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(
                cameraManager: model.cameraManager,
                isPresented: $showingCamera,
                taskTitle: task.title
            ) { photo in
                onCompleteWithPhoto(photo)
            }
        }
        .fullScreenCover(isPresented: $showingLocationTracking) {
            LocationTrackingView(
                locationManager: model.locationManager,
                taskTitle: task.title
            ) { trackingPoints in
                // Save tracking data and complete task
                if let index = model.recentTasks.firstIndex(where: { $0.id == task.id }) {
                    model.recentTasks[index].trackingData = trackingPoints
                    model.recentTasks[index].completed = true
                    model.recentTasks[index].completedAt = Date()
                    
                    // Award XP with bonus for distance
                    let distance = model.locationManager.totalDistance
                    let bonusXP = Int(distance / 100) // 1 XP per 100 meters
                    let totalXP = task.xpReward + bonusXP
                    
                    model.xpBalance += totalXP
                    model.currentUser.xpBalance += totalXP
                    model.currentUser.totalXPEarned += totalXP
                    
                    // Add to activity feed
                    let activity = FriendActivity(
                        userId: model.currentUser.id.uuidString,
                        username: model.currentUser.username,
                        activity: "Completed: \(task.title) (\(model.locationManager.formatDistance(distance)))",
                        xpEarned: totalXP,
                        timestamp: Date(),
                        location: task.location,
                        locationCoordinate: trackingPoints.last?.coordinate,
                        kudos: 0,
                        hasVerificationPhoto: false,
                        verificationPhoto: nil,
                        trackingRoute: trackingPoints.map { $0.coordinate }
                    )
                    
                    model.friendActivities.insert(activity, at: 0)
                }
                showingLocationTracking = false
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
                        ForEach(incompleteTasks.indices, id: \.self) { index in
                            let task = incompleteTasks[index]
                            EnhancedTaskRow(
                                task: task,
                                onComplete: {
                                    if let originalIndex = model.recentTasks.firstIndex(where: { $0.id == task.id }) {
                                        model.completeTask(model.recentTasks[originalIndex])
                                        model.recentTasks[originalIndex].completed = true
                                    }
                                },
                                onCompleteWithPhoto: { photo in
                                    if let originalIndex = model.recentTasks.firstIndex(where: { $0.id == task.id }) {
                                        model.completeTaskWithPhoto(model.recentTasks[originalIndex], photo: photo)
                                    }
                                }
                            )
                        }
                    }
                }

                if !completedTasks.isEmpty {
                    Section("Completed") {
                        ForEach(completedTasks, id: \.id) { task in
                            EnhancedTaskRow(
                                task: task,
                                onComplete: {},
                                onCompleteWithPhoto: { _ in }
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
                        FriendLeaderboardRow(friend: friend, rank: index + 1) {
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

struct FriendLeaderboardRow: View {
    let friend: User
    let rank: Int
    let onRemoveFriend: (() -> Void)?
    
    init(friend: User, rank: Int, onRemoveFriend: (() -> Void)? = nil) {
        self.friend = friend
        self.rank = rank
        self.onRemoveFriend = onRemoveFriend
    }
    
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
            
            if let onRemoveFriend = onRemoveFriend {
                Button(action: onRemoveFriend) {
                    Image(systemName: "person.badge.minus")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
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
                    if let location = activity.location {
                        Label(location, systemImage: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }

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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(model.currentUser.username)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(String(model.currentUser.username.prefix(1)))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            )
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "XP Balance", value: "\(model.currentUser.xpBalance)", color: .blue, icon: "star.fill")
                        StatCard(title: "Minutes Earned", value: "\(model.minutesEarned)", color: .green, icon: "clock.fill")
                        StatCard(title: "Total XP", value: "\(model.currentUser.totalXPEarned)", color: .orange, icon: "trophy.fill")
                        StatCard(title: "Credibility", value: "\(Int(model.currentUser.credibilityScore))%", color: .purple, icon: "checkmark.seal.fill")
                    }
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Quick Actions")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { showingAddTask = true }) {
                                Label("Add Task", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            if model.xpBalance >= 5 {
                                Button(action: { model.convertXPToMinutes() }) {
                                    Label("Convert XP", systemImage: "arrow.triangle.2.circlepath")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    if model.isSessionActive {
                        VStack(spacing: 12) {
                            Text("Session Active")
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
                    } else if model.minutesEarned > 0 {
                        VStack(spacing: 12) {
                            Text("Start Screen Time Session")
                                .font(.headline)
                            
                            Text("You have \(model.minutesEarned) minutes available")
                                .foregroundColor(.secondary)
                            
                            Picker("Duration", selection: $selectedDuration) {
                                ForEach([15, 30, 45, 60], id: \.self) { minutes in
                                    Text("\(minutes) min").tag(minutes)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Button("Start Session") {
                                model.startEarnedSession(duration: selectedDuration)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedDuration > model.minutesEarned)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }

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

                    // Current Tasks Card
                    VStack(spacing: 12) {
                        HStack {
                            Text("Your Tasks")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: EnhancedTasksView().environmentObject(model)) {
                                Text("See All")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        let incompleteTasks = model.recentTasks.filter { !$0.completed }
                        let completedTasks = model.recentTasks.filter { $0.completed }

                        if incompleteTasks.isEmpty && completedTasks.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("No tasks yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button("Add your first task") {
                                    showingAddTask = true
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                            .padding()
                        } else {
                            VStack(spacing: 8) {
                                if !incompleteTasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("To Do (\(incompleteTasks.count))")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        ForEach(Array(incompleteTasks.prefix(3)), id: \.id) { task in
                                            HStack {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.gray)
                                                    .font(.title3)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(task.title)
                                                        .font(.subheadline)
                                                        .lineLimit(1)
                                                    HStack {
                                                        Text(task.category.rawValue)
                                                            .font(.caption)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(Color.blue.opacity(0.2))
                                                            .cornerRadius(4)
                                                        Text("\(task.xpReward) XP")
                                                            .font(.caption)
                                                            .foregroundColor(.green)
                                                    }
                                                }

                                                Spacer()
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                }

                                if !completedTasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Completed (\(completedTasks.count))")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)

                                        ForEach(Array(completedTasks.prefix(2)), id: \.id) { task in
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                    .font(.title3)

                                                Text(task.title)
                                                    .font(.subheadline)
                                                    .strikethrough()
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)

                                                Spacer()

                                                Text("+\(task.xpReward) XP")
                                                    .font(.caption)
                                                    .foregroundColor(.green)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

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
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
