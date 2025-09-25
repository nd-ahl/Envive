import DeviceActivity
import Foundation
import FamilyControls
import Combine

class ActivityScheduler: ObservableObject {
    private let center = DeviceActivityCenter()
    @Published var isMonitoring = false
    @Published var activeSessionEndTime: Date?
    @Published var remainingMinutes: Int = 0

    private var sessionTimer: Timer?

    func startScreenTimeSession(durationMinutes: Int) {
        // Stop any existing monitoring first
        center.stopMonitoring()

        let activityName = DeviceActivityName("screenTimeSession")

        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)!

        activeSessionEndTime = endTime
        remainingMinutes = durationMinutes

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(
                hour: Calendar.current.component(.hour, from: startTime),
                minute: Calendar.current.component(.minute, from: startTime),
                second: Calendar.current.component(.second, from: startTime)
            ),
            intervalEnd: DateComponents(
                hour: Calendar.current.component(.hour, from: endTime),
                minute: Calendar.current.component(.minute, from: endTime),
                second: Calendar.current.component(.second, from: endTime)
            ),
            repeats: false
        )

        print("🔓 Starting screen time session: \(startTime) to \(endTime)")
        print("📱 Activity name: \(activityName)")

        do {
            try center.startMonitoring(activityName, during: schedule)
            isMonitoring = true
            startSessionTimer()
            print("✅ Screen time session started successfully for \(durationMinutes) minutes")
        } catch {
            print("❌ Failed to start screen time session monitoring: \(error)")
            isMonitoring = false
        }
    }

    func startTimerBasedRestrictions(durationMinutes: Int) {
        let activityName = DeviceActivityName("timerRestriction")

        let startTime = Date()
        let endTime = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startTime)!

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(
                hour: Calendar.current.component(.hour, from: startTime),
                minute: Calendar.current.component(.minute, from: startTime)
            ),
            intervalEnd: DateComponents(
                hour: Calendar.current.component(.hour, from: endTime),
                minute: Calendar.current.component(.minute, from: endTime)
            ),
            repeats: false
        )

        do {
            try center.startMonitoring(activityName, during: schedule)
            isMonitoring = true
            print("Started timer-based restrictions for \(durationMinutes) minutes")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    func startDailySchedule(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        let activityName = DeviceActivityName("dailyRestriction")

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMinute),
            intervalEnd: DateComponents(hour: endHour, minute: endMinute),
            repeats: true
        )

        do {
            try center.startMonitoring(activityName, during: schedule)
            isMonitoring = true
            print("Started daily schedule from \(startHour):\(startMinute) to \(endHour):\(endMinute)")
        } catch {
            print("Failed to start daily monitoring: \(error)")
        }
    }

    func stopAllMonitoring() {
        center.stopMonitoring()
        isMonitoring = false
        activeSessionEndTime = nil
        remainingMinutes = 0
        sessionTimer?.invalidate()
        sessionTimer = nil
        print("Stopped all monitoring")
    }

    func startUsageThresholdMonitoring(thresholdMinutes: Int, for selection: FamilyActivitySelection) {
        let activityName = DeviceActivityName("usageThreshold")
        let eventName = DeviceActivityEvent.Name("thresholdReached")

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: thresholdMinutes)
        )

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        do {
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
            isMonitoring = true
            print("Started usage threshold monitoring for \(thresholdMinutes) minutes")
        } catch {
            print("Failed to start threshold monitoring: \(error)")
        }
    }

    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateRemainingTime()
        }
    }

    private func updateRemainingTime() {
        guard let endTime = activeSessionEndTime else {
            sessionTimer?.invalidate()
            sessionTimer = nil
            return
        }

        let now = Date()
        if now >= endTime {
            remainingMinutes = 0
            activeSessionEndTime = nil
            sessionTimer?.invalidate()
            sessionTimer = nil
        } else {
            remainingMinutes = Int(endTime.timeIntervalSince(now) / 60)
        }
    }

    var isSessionActive: Bool {
        activeSessionEndTime != nil && Date() < activeSessionEndTime!
    }
}