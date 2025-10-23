# Custom Sound Effects System

## Overview

The Envive app now features a custom sound effects system that generates unique, pleasant sounds programmatically. These sounds are designed to be **distinct from system notifications** (SMS, email, etc.) to avoid confusion and provide a better user experience.

## Features

### ✅ Custom Sound Generation
- **Programmatic synthesis** using AVFoundation
- Generates `.caf` audio files stored in the app's documents directory
- Musical tones based on major scales for pleasant, harmonious sounds
- Fade-in/fade-out envelopes for smooth, non-jarring playback

### ✅ Automatic Fallback
- If custom sounds fail to load, the system automatically falls back to iOS system sounds
- Robust error handling ensures sounds always play

### ✅ Performance Optimized
- Preloading of frequently used sounds for instant playback
- Background generation to avoid blocking the UI
- Lightweight audio files (< 50KB each)

### ✅ Configurable
- Toggle between custom and system sounds
- Adjustable volume (0.0 - 1.0)
- Enable/disable sound effects entirely
- Force regeneration if needed

## Sound Categories

### Task Events
- **task_assigned**: Gentle ascending chime (C5 → E5 → G5)
- **task_start**: Quick upward swoosh (A4 → C#5)
- **task_complete**: Satisfying completion chime (C5 → E5 → G5)
- **task_approved**: Happy, bright ascending sound (E5 → G5 → C6)
- **task_declined**: Gentle descending tone (C5 → G4)

### XP and Rewards
- **xp_earned**: Quick positive chime (E5 → G5)
- **xp_big_earned**: Exciting ascending arpeggio (C5 → E5 → G5 → C6)
- **level_up**: Victory fanfare (C5 → E5 → G5 → C6)
- **streak_increment**: Quick upbeat beep (A5 → C6)
- **achievement**: Celebratory fanfare (E5 → G5 → C6 → E6)

### Credibility
- **credibility_up**: Positive upward chime (C5 → G5)
- **credibility_down**: Gentle downward tone (C5 → F4)
- **perfect_score**: Special celebration (G5 → C6 → E6 → G6)

### Screen Time
- **screentime_earned**: Rewarding ascending tones (E5 → G5 → C6)
- **session_start**: Friendly start chime (C5 → E5)
- **session_end**: Gentle descending end tone (E5 → C5)
- **low_time_warning**: Attention-getting but not alarming (D5 × 2)

### UI Interactions
- **button_tap**: Subtle click (A5, very short)
- **button_success**: Quick success beep (E5 → G5)
- **swipe**: Quick whoosh (A4 → C#5)
- **toggle**: Simple switch sound (E5)

### Special Sounds
- **celebration**: Joyful ascending sequence (C5 → E5 → G5 → C6 → E6)
- **fanfare**: Triumphant fanfare (E5 → G5 → C6 → E6)
- **error**: Gentle error tone (G4 → F4)
- **warning**: Attention tone (C5 × 2)

## Usage

### Basic Usage

```swift
// Play a sound with haptic feedback
SoundEffectsManager.shared.play(.taskCompleted, withHaptic: .success)

// Play with delay
SoundEffectsManager.shared.playWithDelay(.xpEarned, delay: 0.2)
```

### Convenience Methods

```swift
// Task completion with XP earned sequence
SoundEffectsManager.shared.playTaskComplete()

// Task approval with dynamic celebration for big rewards
SoundEffectsManager.shared.playTaskApproved(xpAmount: 75)

// Task declined with credibility feedback
SoundEffectsManager.shared.playTaskDeclined()

// Credibility change
SoundEffectsManager.shared.playCredibilityChange(increase: true, newScore: 95)

// Streak with milestone celebration
SoundEffectsManager.shared.playStreak(count: 7)

// Screen time earned with celebration for big rewards
SoundEffectsManager.shared.playScreenTimeEarned(minutes: 45)
```

### SwiftUI View Extensions

```swift
Button("Complete Task") {
    // action
}
.withSound(.buttonTap, haptic: .light)

Button("Approve") {
    // action
}
.withHaptic(.success)
```

### Settings

```swift
// Enable/disable sounds
SoundEffectsManager.shared.setEnabled(true)

// Adjust volume (0.0 - 1.0)
SoundEffectsManager.shared.setVolume(0.8)

// Toggle custom vs system sounds
SoundEffectsManager.shared.setUseCustomSounds(true)

// Force regenerate all sounds
SoundEffectsManager.shared.regenerateSounds()
```

## Technical Details

### Sound Generation
- **Sample Rate**: 44.1 kHz
- **Format**: PCM Float32, mono
- **File Format**: CAF (Core Audio Format)
- **Synthesis**: Sine wave generation with envelope shaping

### Envelope Shaping
- **Fade In**: First 5% of samples for smooth start
- **Fade Out**: Last 30% of samples for smooth end (configurable per sound)
- Prevents clicks and pops

### Musical Frequencies Used
- **C4**: 261.63 Hz
- **F4**: 349.23 Hz
- **G4**: 392.00 Hz
- **A4**: 440.00 Hz
- **C5**: 523.25 Hz
- **E5**: 659.25 Hz
- **G5**: 783.99 Hz
- **A5**: 880.00 Hz
- **C6**: 1046.50 Hz
- **E6**: 1318.51 Hz
- **G6**: 1567.98 Hz

All sounds use major scale intervals for pleasant, harmonious tones.

## File Locations

### Source Code
- `EnviveNew/Services/SoundGenerator.swift`: Sound generation engine
- `EnviveNew/Services/SoundEffectsManager.swift`: Sound playback manager

### Generated Audio Files
- Stored in: `Documents/Sounds/*.caf`
- Automatically generated on first launch
- Can be regenerated via settings or API call

## Benefits Over System Sounds

### 1. **No Confusion**
System sounds like SMS tones and email alerts can confuse users into checking their messages. Custom sounds eliminate this problem.

### 2. **Consistent Branding**
Unique sounds create a cohesive audio identity for the app.

### 3. **Pleasant User Experience**
Musically harmonious tones using major scales are more pleasant than arbitrary system sounds.

### 4. **Context-Appropriate**
Each sound is specifically designed for its purpose:
- Success sounds are uplifting
- Error sounds are gentle, not alarming
- Rewards sounds are celebratory

### 5. **Customizable**
Easy to adjust volume, disable, or modify without changing system settings.

## Testing

### Manual Testing
1. Launch the app - sounds generate automatically on first run
2. Complete a task - should hear custom task completion sequence
3. Get a task approved - should hear approval + XP sounds
4. Adjust volume in settings - should affect all custom sounds
5. Toggle custom/system sounds - should switch seamlessly

### Debugging
- Check console logs for sound generation progress
- Look for warnings about missing or failed sounds
- Use `regenerateSounds()` if sounds get corrupted

### Sound Generation Time
- Full generation takes approximately 1-2 seconds
- Happens on background thread to avoid UI blocking
- Progress logged to console

## Future Enhancements

### Potential Additions
1. **User-selectable sound themes** (e.g., "Gentle", "Energetic", "Minimal")
2. **Different instruments** (piano, bell, marimba)
3. **Adaptive volume** based on time of day
4. **Sound preview** in settings
5. **Custom upload** of user sounds
6. **3D spatial audio** for immersive effects

### Accessibility
- Consider adding visual indicators alongside sounds
- Provide captions for sound events
- Ensure sounds are not required for app functionality

## Troubleshooting

### Sounds Not Playing
1. Check if sounds are enabled: `SoundEffectsManager.shared.isEffectsEnabled()`
2. Check volume: `SoundEffectsManager.shared.getVolume()`
3. Regenerate sounds: `SoundEffectsManager.shared.regenerateSounds()`
4. Check console for error messages

### Poor Sound Quality
- Sounds are generated programmatically, so quality depends on algorithm
- Adjust envelope parameters in `SoundGenerator.swift` if needed
- Consider increasing sample rate for higher quality

### Sounds Too Loud/Quiet
- Adjust global volume: `SoundEffectsManager.shared.setVolume(0.5)`
- Adjust per-sound volume in `SoundGenerator.swift` (tone volume parameter)

## Credits

Custom sound generation system implemented using:
- **AVFoundation** for audio playback
- **Accelerate** framework for DSP (if needed for advanced effects)
- **Core Audio** for low-level audio file writing

---

**Last Updated**: 2025-01-22
**Version**: 1.0
**Author**: Envive Development Team
