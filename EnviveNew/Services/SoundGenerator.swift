import Foundation
import AVFoundation
import Accelerate

// MARK: - Sound Generator

/// Generates custom sound effects programmatically using AVFoundation
/// This allows us to create unique sounds that won't be confused with system notifications
class SoundGenerator {
    static let shared = SoundGenerator()

    private let sampleRate: Double = 44100.0
    private let soundsDirectory: URL

    private init() {
        // Create sounds directory in app's documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        soundsDirectory = documentsPath.appendingPathComponent("Sounds")

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: soundsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Generate All Sounds

    /// Generate all custom sound effects
    func generateAllSounds() {
        print("🎵 Generating custom sound effects...")

        // Task sounds - distinctive and non-intrusive
        generateTaskAssigned()
        generateTaskStarted()
        generateTaskCompleted()
        generateTaskApproved()
        generateTaskDeclined()

        // XP and rewards - positive and rewarding
        generateXPEarned()
        generateXPBigEarned()
        generateLevelUp()
        generateStreakIncrement()
        generateAchievementUnlocked()

        // Credibility sounds
        generateCredibilityUp()
        generateCredibilityDown()
        generatePerfectScore()

        // Screen time sounds
        generateScreenTimeEarned()
        generateSessionStart()
        generateSessionEnd()
        generateLowTimeWarning()

        // UI sounds - subtle
        generateButtonTap()
        generateButtonSuccess()
        generateSwipe()
        generateToggle()

        // Special sounds
        generateCelebration()
        generateFanfare()
        generateError()
        generateWarning()

        print("✅ Generated all custom sound effects")
    }

    // MARK: - Task Sounds

    private func generateTaskAssigned() {
        // Gentle ascending chime - friendly notification
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.08, 0.3),  // C5
            (659.25, 0.08, 0.35), // E5
            (783.99, 0.12, 0.4)   // G5
        ]
        generateMultiToneSound(name: "task_assigned", tones: tones, fadeOut: true)
    }

    private func generateTaskStarted() {
        // Quick upward swoosh
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (440.0, 0.06, 0.3),   // A4
            (554.37, 0.06, 0.35)  // C#5
        ]
        generateMultiToneSound(name: "task_start", tones: tones, fadeOut: true)
    }

    private func generateTaskCompleted() {
        // Satisfying completion chime - ascending major triad
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.1, 0.4),   // C5
            (659.25, 0.1, 0.45),  // E5
            (783.99, 0.15, 0.5)   // G5
        ]
        generateMultiToneSound(name: "task_complete", tones: tones, fadeOut: true)
    }

    private func generateTaskApproved() {
        // Happy, bright ascending sound
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (659.25, 0.08, 0.35), // E5
            (783.99, 0.08, 0.4),  // G5
            (1046.50, 0.12, 0.45) // C6
        ]
        generateMultiToneSound(name: "task_approved", tones: tones, fadeOut: true)
    }

    private func generateTaskDeclined() {
        // Gentle descending tone - not harsh
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.1, 0.3),   // C5
            (392.00, 0.12, 0.25)  // G4
        ]
        generateMultiToneSound(name: "task_declined", tones: tones, fadeOut: true)
    }

    // MARK: - XP and Reward Sounds

    private func generateXPEarned() {
        // Quick positive chime
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (659.25, 0.08, 0.35), // E5
            (783.99, 0.1, 0.4)    // G5
        ]
        generateMultiToneSound(name: "xp_earned", tones: tones, fadeOut: true)
    }

    private func generateXPBigEarned() {
        // Exciting ascending arpeggio
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.07, 0.35), // C5
            (659.25, 0.07, 0.4),  // E5
            (783.99, 0.07, 0.45), // G5
            (1046.50, 0.15, 0.5)  // C6
        ]
        generateMultiToneSound(name: "xp_big_earned", tones: tones, fadeOut: true)
    }

    private func generateLevelUp() {
        // Victory fanfare
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.1, 0.4),   // C5
            (659.25, 0.1, 0.45),  // E5
            (783.99, 0.1, 0.5),   // G5
            (1046.50, 0.2, 0.55)  // C6
        ]
        generateMultiToneSound(name: "level_up", tones: tones, fadeOut: true)
    }

    private func generateStreakIncrement() {
        // Quick upbeat beep
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (880.0, 0.08, 0.35),   // A5
            (1046.50, 0.1, 0.4)    // C6
        ]
        generateMultiToneSound(name: "streak_increment", tones: tones, fadeOut: true)
    }

    private func generateAchievementUnlocked() {
        // Celebratory fanfare
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (659.25, 0.1, 0.4),   // E5
            (783.99, 0.1, 0.45),  // G5
            (1046.50, 0.1, 0.5),  // C6
            (1318.51, 0.2, 0.55)  // E6
        ]
        generateMultiToneSound(name: "achievement", tones: tones, fadeOut: true)
    }

    // MARK: - Credibility Sounds

    private func generateCredibilityUp() {
        // Positive upward chime
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.08, 0.35), // C5
            (783.99, 0.12, 0.4)   // G5
        ]
        generateMultiToneSound(name: "credibility_up", tones: tones, fadeOut: true)
    }

    private func generateCredibilityDown() {
        // Gentle downward tone
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.1, 0.3),   // C5
            (349.23, 0.12, 0.25)  // F4
        ]
        generateMultiToneSound(name: "credibility_down", tones: tones, fadeOut: true)
    }

    private func generatePerfectScore() {
        // Special celebratory sequence
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (783.99, 0.08, 0.45),  // G5
            (1046.50, 0.08, 0.5),  // C6
            (1318.51, 0.08, 0.55), // E6
            (1567.98, 0.15, 0.6)   // G6
        ]
        generateMultiToneSound(name: "perfect_score", tones: tones, fadeOut: true)
    }

    // MARK: - Screen Time Sounds

    private func generateScreenTimeEarned() {
        // Rewarding ascending tones
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (659.25, 0.08, 0.4),  // E5
            (783.99, 0.08, 0.45), // G5
            (1046.50, 0.12, 0.5)  // C6
        ]
        generateMultiToneSound(name: "screentime_earned", tones: tones, fadeOut: true)
    }

    private func generateSessionStart() {
        // Friendly start chime
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.1, 0.35),  // C5
            (659.25, 0.12, 0.4)   // E5
        ]
        generateMultiToneSound(name: "session_start", tones: tones, fadeOut: true)
    }

    private func generateSessionEnd() {
        // Gentle descending end tone
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (659.25, 0.1, 0.35),  // E5
            (523.25, 0.12, 0.3)   // C5
        ]
        generateMultiToneSound(name: "session_end", tones: tones, fadeOut: true)
    }

    private func generateLowTimeWarning() {
        // Attention-getting but not alarming
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (587.33, 0.15, 0.4),  // D5
            (587.33, 0.15, 0.35)  // D5 (repeat)
        ]
        generateMultiToneSound(name: "low_time_warning", tones: tones, fadeOut: true)
    }

    // MARK: - UI Sounds

    private func generateButtonTap() {
        // Subtle click
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (880.0, 0.03, 0.2)    // A5 - very short
        ]
        generateMultiToneSound(name: "button_tap", tones: tones, fadeOut: false)
    }

    private func generateButtonSuccess() {
        // Quick success beep
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (659.25, 0.05, 0.25), // E5
            (783.99, 0.07, 0.3)   // G5
        ]
        generateMultiToneSound(name: "button_success", tones: tones, fadeOut: true)
    }

    private func generateSwipe() {
        // Quick whoosh
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (440.0, 0.04, 0.15),  // A4
            (554.37, 0.04, 0.12)  // C#5
        ]
        generateMultiToneSound(name: "swipe", tones: tones, fadeOut: true)
    }

    private func generateToggle() {
        // Simple switch sound
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (659.25, 0.04, 0.25)  // E5
        ]
        generateMultiToneSound(name: "toggle", tones: tones, fadeOut: false)
    }

    // MARK: - Special Sounds

    private func generateCelebration() {
        // Joyful ascending sequence
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.08, 0.4),   // C5
            (659.25, 0.08, 0.45),  // E5
            (783.99, 0.08, 0.5),   // G5
            (1046.50, 0.08, 0.55), // C6
            (1318.51, 0.15, 0.6)   // E6
        ]
        generateMultiToneSound(name: "celebration", tones: tones, fadeOut: true)
    }

    private func generateFanfare() {
        // Triumphant fanfare
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (659.25, 0.12, 0.45),  // E5
            (783.99, 0.12, 0.5),   // G5
            (1046.50, 0.12, 0.55), // C6
            (1318.51, 0.2, 0.6)    // E6
        ]
        generateMultiToneSound(name: "fanfare", tones: tones, fadeOut: true)
    }

    private func generateError() {
        // Gentle error tone - not harsh
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (392.00, 0.12, 0.3),   // G4
            (349.23, 0.15, 0.25)   // F4
        ]
        generateMultiToneSound(name: "error", tones: tones, fadeOut: true)
    }

    private func generateWarning() {
        // Attention tone
        let tones: [(frequency: Double, duration: Double, volume: Double)] = [
            (523.25, 0.12, 0.35),  // C5
            (523.25, 0.12, 0.3)    // C5 (repeat)
        ]
        generateMultiToneSound(name: "warning", tones: tones, fadeOut: true)
    }

    // MARK: - Sound Generation Helpers

    private func generateMultiToneSound(name: String, tones: [(frequency: Double, duration: Double, volume: Double)], fadeOut: Bool) {
        var allSamples: [Float] = []

        for (index, tone) in tones.enumerated() {
            let isLastTone = index == tones.count - 1
            let samples = generateSineTone(
                frequency: tone.frequency,
                duration: tone.duration,
                volume: tone.volume,
                fadeOut: fadeOut && isLastTone
            )
            allSamples.append(contentsOf: samples)
        }

        saveSoundToFile(name: name, samples: allSamples)
    }

    private func generateSineTone(frequency: Double, duration: Double, volume: Double, fadeOut: Bool) -> [Float] {
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let time = Double(i) / sampleRate
            var sample = Float(sin(2.0 * Double.pi * frequency * time) * volume)

            // Apply fade in (first 5% of samples)
            if i < sampleCount / 20 {
                let fadeInFactor = Float(i) / Float(sampleCount / 20)
                sample *= fadeInFactor
            }

            // Apply fade out (last 30% of samples) if requested
            if fadeOut && i > sampleCount * 7 / 10 {
                let fadeOutSamples = sampleCount - (sampleCount * 7 / 10)
                let fadeOutPosition = i - (sampleCount * 7 / 10)
                let fadeOutFactor = 1.0 - (Float(fadeOutPosition) / Float(fadeOutSamples))
                sample *= fadeOutFactor
            }

            samples[i] = sample
        }

        return samples
    }

    private func saveSoundToFile(name: String, samples: [Float]) {
        let fileURL = soundsDirectory.appendingPathComponent("\(name).caf")

        // Create audio format
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        // Create audio buffer
        let frameCount = AVAudioFrameCount(samples.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("❌ Failed to create audio buffer for \(name)")
            return
        }

        buffer.frameLength = frameCount

        // Copy samples to buffer
        guard let channelData = buffer.floatChannelData else {
            print("❌ Failed to get channel data for \(name)")
            return
        }

        for i in 0..<samples.count {
            channelData[0][i] = samples[i]
        }

        // Write to file
        do {
            let audioFile = try AVAudioFile(
                forWriting: fileURL,
                settings: format.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )

            try audioFile.write(from: buffer)
            print("✅ Generated: \(name).caf")
        } catch {
            print("❌ Failed to write audio file \(name): \(error)")
        }
    }

    // MARK: - Public Methods

    func getSoundURL(for effect: String) -> URL? {
        let fileURL = soundsDirectory.appendingPathComponent("\(effect).caf")
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    func soundsExist() -> Bool {
        let testFile = soundsDirectory.appendingPathComponent("task_complete.caf")
        return FileManager.default.fileExists(atPath: testFile.path)
    }
}
