import Foundation
import AVFoundation
import UIKit

// MARK: - Sound Effect Types

enum SoundEffect: String {
    // UI Interactions
    case buttonTap = "button_tap"
    case buttonSuccess = "button_success"
    case swipe = "swipe"
    case toggle = "toggle"

    // Task Events
    case taskAssigned = "task_assigned"
    case taskStarted = "task_start"
    case taskCompleted = "task_complete"
    case taskApproved = "task_approved"
    case taskDeclined = "task_declined"

    // XP and Rewards
    case xpEarned = "xp_earned"
    case xpBigEarned = "xp_big_earned"
    case levelUp = "level_up"
    case streakIncrement = "streak_increment"
    case achievementUnlocked = "achievement"

    // Credibility
    case credibilityUp = "credibility_up"
    case credibilityDown = "credibility_down"
    case perfectScore = "perfect_score"

    // Screen Time
    case screenTimeEarned = "screentime_earned"
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    case lowTime = "low_time_warning"

    // Notifications
    case notificationPositive = "notification_positive"
    case notificationNeutral = "notification_neutral"
    case notificationNegative = "notification_negative"

    // Special
    case celebration = "celebration"
    case fanfare = "fanfare"
    case error = "error"
    case warning = "warning"
}

// MARK: - Haptic Feedback Types

enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}

// MARK: - Sound Effects Manager

class SoundEffectsManager {
    static let shared = SoundEffectsManager()

    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var isEnabled: Bool = true
    private var volume: Float = 0.7

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    private init() {
        setupAudioSession()
        preloadCommonSounds()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Failed to setup audio session: \(error)")
        }
    }

    private func preloadCommonSounds() {
        // Preload frequently used sounds for instant playback
        let commonSounds: [SoundEffect] = [
            .buttonTap,
            .taskCompleted,
            .xpEarned,
            .credibilityUp
        ]

        for sound in commonSounds {
            preloadSound(sound)
        }
    }

    private func preloadSound(_ sound: SoundEffect) {
        // For now, we'll use system sounds as placeholders
        // In production, replace with custom sound files
        _ = getSystemSoundID(for: sound)
    }

    // MARK: - Playback

    func play(_ sound: SoundEffect, withHaptic haptic: HapticStyle? = nil) {
        guard isEnabled else { return }

        // Play haptic feedback if specified
        if let haptic = haptic {
            playHaptic(haptic)
        }

        // Play sound
        playSystemSound(for: sound)
    }

    func playWithDelay(_ sound: SoundEffect, delay: TimeInterval, withHaptic haptic: HapticStyle? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.play(sound, withHaptic: haptic)
        }
    }

    private func playSystemSound(for sound: SoundEffect) {
        let soundID = getSystemSoundID(for: sound)
        AudioServicesPlaySystemSound(soundID)
    }

    // MARK: - System Sound Mapping

    private func getSystemSoundID(for sound: SoundEffect) -> SystemSoundID {
        // Map our sound effects to iOS system sounds as placeholders
        // Replace with custom sounds in production
        switch sound {
        // UI Interactions
        case .buttonTap:
            return 1104 // Tock
        case .buttonSuccess:
            return 1057 // SMS Received
        case .swipe:
            return 1105 // Swipe
        case .toggle:
            return 1306 // Key Press

        // Task Events
        case .taskAssigned:
            return 1003 // Text Tone (Tri-tone)
        case .taskStarted:
            return 1000 // New Mail
        case .taskCompleted:
            return 1016 // SMS Received 5
        case .taskApproved:
            return 1054 // SMS Received 3
        case .taskDeclined:
            return 1053 // SMS Received 2

        // XP and Rewards
        case .xpEarned:
            return 1107 // Payment Success
        case .xpBigEarned:
            return 1013 // SMS Received 4
        case .levelUp:
            return 1025 // Anticipate
        case .streakIncrement:
            return 1009 // Fanfare
        case .achievementUnlocked:
            return 1111 // Ringtone (Apex)

        // Credibility
        case .credibilityUp:
            return 1013 // Positive ding
        case .credibilityDown:
            return 1006 // Tweet (alert-like)
        case .perfectScore:
            return 1009 // Fanfare

        // Screen Time
        case .screenTimeEarned:
            return 1107 // Payment Success
        case .sessionStart:
            return 1025 // Anticipate
        case .sessionEnd:
            return 1008 // Glass (end tone)
        case .lowTime:
            return 1023 // Alert

        // Notifications
        case .notificationPositive:
            return 1003 // Positive notification
        case .notificationNeutral:
            return 1000 // Neutral
        case .notificationNegative:
            return 1053 // Warning-ish

        // Special
        case .celebration:
            return 1009 // Fanfare
        case .fanfare:
            return 1111 // Apex
        case .error:
            return 1073 // Alarm
        case .warning:
            return 1023 // Alert
        }
    }

    // MARK: - Haptic Feedback

    func playHaptic(_ style: HapticStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        case .selection:
            selectionFeedback.selectionChanged()
        }
    }

    // MARK: - Convenience Methods

    func playTaskComplete() {
        play(.taskCompleted, withHaptic: .success)
        playWithDelay(.xpEarned, delay: 0.2, withHaptic: .light)
    }

    func playTaskApproved(xpAmount: Int) {
        play(.taskApproved, withHaptic: .success)

        if xpAmount >= 50 {
            // Big reward!
            playWithDelay(.xpBigEarned, delay: 0.3, withHaptic: .heavy)
            playWithDelay(.celebration, delay: 0.6)
        } else {
            playWithDelay(.xpEarned, delay: 0.3, withHaptic: .light)
        }
    }

    func playTaskDeclined() {
        play(.taskDeclined, withHaptic: .warning)
        playWithDelay(.credibilityDown, delay: 0.2)
    }

    func playCredibilityChange(increase: Bool, newScore: Int) {
        if increase {
            play(.credibilityUp, withHaptic: .success)

            if newScore == 100 {
                playWithDelay(.perfectScore, delay: 0.3, withHaptic: .heavy)
            }
        } else {
            play(.credibilityDown, withHaptic: .warning)
        }
    }

    func playStreak(count: Int) {
        play(.streakIncrement, withHaptic: .medium)

        // Extra celebration for milestones
        if count % 7 == 0 {
            playWithDelay(.celebration, delay: 0.3, withHaptic: .heavy)
        }
    }

    func playScreenTimeEarned(minutes: Int) {
        play(.screenTimeEarned, withHaptic: .success)

        if minutes >= 30 {
            playWithDelay(.celebration, delay: 0.2)
        }
    }

    // MARK: - Settings

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "soundEffectsEnabled")
    }

    func isEffectsEnabled() -> Bool {
        return isEnabled
    }

    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        UserDefaults.standard.set(self.volume, forKey: "soundEffectsVolume")
    }

    func getVolume() -> Float {
        return volume
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Add sound effect to button tap
    func withSound(_ sound: SoundEffect, haptic: HapticStyle? = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                SoundEffectsManager.shared.play(sound, withHaptic: haptic)
            }
        )
    }

    /// Add haptic feedback only
    func withHaptic(_ style: HapticStyle) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                SoundEffectsManager.shared.playHaptic(style)
            }
        )
    }
}
