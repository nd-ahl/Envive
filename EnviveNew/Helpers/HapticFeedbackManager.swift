import UIKit
import AVFoundation

// MARK: - Haptic Feedback Manager

/// Manages haptic and audio feedback throughout the app
class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()

    private var audioPlayer: AVAudioPlayer?

    private init() {
        // Configure audio session for sound effects
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Haptic Feedback

    /// Light impact haptic (for button taps, small interactions)
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact haptic (for standard actions)
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact haptic (for important actions)
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Success haptic (for completed actions)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning haptic (for caution situations)
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error haptic (for failed actions)
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Selection changed haptic (for picker/selector changes)
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // MARK: - Audio Feedback

    /// Play system sound by ID
    func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }

    /// Play rewarding sound effect for task completion
    func playTaskCompletionSound() {
        // Play success haptic
        success()

        // Play system sound (Tink - sounds like coins/success)
        AudioServicesPlaySystemSound(1057)
    }

    /// Play sound for task assignment
    func playTaskAssignedSound() {
        // Play light haptic
        light()

        // Play system sound (Tock - notification sound)
        AudioServicesPlaySystemSound(1306)
    }

    /// Play sound for earning XP/screen time
    func playXPEarnedSound() {
        // Play success haptic
        success()

        // Play system sound (Bloom - uplifting sound)
        AudioServicesPlaySystemSound(1321)
    }

    /// Play sound for starting task
    func playTaskStartSound() {
        // Play medium haptic
        medium()

        // Play system sound (Pop - quick confirmation)
        AudioServicesPlaySystemSound(1306)
    }

    /// Play sound for button press
    func playButtonSound() {
        // Play light haptic
        light()

        // Play system sound (Tock)
        AudioServicesPlaySystemSound(1306)
    }

    // MARK: - Combined Feedback

    /// Task completed - success haptic + rewarding sound
    func taskCompleted() {
        playTaskCompletionSound()
    }

    /// Task started - medium haptic + confirmation sound
    func taskStarted() {
        playTaskStartSound()
    }

    /// Task assigned - light haptic + notification sound
    func taskAssigned() {
        playTaskAssignedSound()
    }

    /// XP earned - success haptic + celebration sound
    func xpEarned() {
        playXPEarnedSound()
    }

    /// Level up - heavy impact + multiple success haptics
    func levelUp() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.success()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.success()
        }
        // Play celebration sound
        AudioServicesPlaySystemSound(1057)
    }

    /// Button tapped - light haptic
    func buttonTapped() {
        light()
    }

    /// Screen time session started
    func sessionStarted() {
        medium()
        AudioServicesPlaySystemSound(1054) // Swoosh sound
    }

    /// Screen time session ended
    func sessionEnded() {
        warning()
        AudioServicesPlaySystemSound(1053) // Tock sound
    }
}

// MARK: - Common System Sound IDs

/*
 Common iOS System Sound IDs:

 1000-1002: New mail sounds
 1003: Sent mail sound
 1004: Voicemail sound
 1005: SMS received
 1006-1007: Calendar alerts
 1008: Low power alert
 1009: SMS sent
 1010: Tweet sent
 1013: Photo shutter
 1014: Push notification
 1015-1023: Various notification sounds
 1052: Tweet sent
 1053: Tock
 1054: Swoosh
 1055: Push notification
 1057: Tink (sounds like success/coins)
 1306: Tock (keyboard click)
 1321: Bloom (notification/success)

 Note: These sound IDs may vary by iOS version and are not officially documented by Apple.
 For production, consider using custom sound files or UNNotificationSound.
 */
