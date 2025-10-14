import SwiftUI
import Combine

// MARK: - Emergency Grant Models

struct EmergencyGrant: Identifiable, Codable {
    let id: UUID
    let parentId: UUID
    let childId: UUID
    let amount: Int
    let reason: String
    let timestamp: Date
    let expiresAt: Date?

    init(
        id: UUID = UUID(),
        parentId: UUID,
        childId: UUID,
        amount: Int,
        reason: String,
        timestamp: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.parentId = parentId
        self.childId = childId
        self.amount = amount
        self.reason = reason
        self.timestamp = timestamp
        self.expiresAt = expiresAt
    }
}

enum GrantReason: String, CaseIterable {
    case emergency = "Emergency situation"
    case special = "Special occasion"
    case technical = "Technical issue"
    case reward = "Extra reward"
    case makeup = "Make up for lost time"
    case other = "Other reason"

    var icon: String {
        switch self {
        case .emergency: return "exclamationmark.triangle.fill"
        case .special: return "star.fill"
        case .technical: return "wrench.fill"
        case .reward: return "gift.fill"
        case .makeup: return "clock.arrow.circlepath"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Emergency Grant Manager

class EmergencyGrantManager: ObservableObject {
    @Published var isProcessing = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var grantHistory: [EmergencyGrant] = []

    private let xpService: XPService

    init(xpService: XPService? = nil) {
        self.xpService = xpService ?? DependencyContainer.shared.xpService
    }

    func grantXP(
        parentId: UUID,
        childId: UUID,
        amount: Int,
        reason: String
    ) {
        guard amount > 0 && amount <= 500 else {
            errorMessage = "Grant amount must be between 1 and 500 XP"
            showError = true
            return
        }

        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please provide a reason for this grant"
            showError = true
            return
        }

        isProcessing = true

        // Simulate processing delay (would be async API call in production)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            // Grant XP directly using the service method
            let success = self.xpService.grantXPDirect(
                userId: childId,
                amount: amount,
                reason: reason
            )

            if success {
                // Record the grant
                let grant = EmergencyGrant(
                    parentId: parentId,
                    childId: childId,
                    amount: amount,
                    reason: reason
                )

                self.grantHistory.insert(grant, at: 0)
                self.showSuccess = true
                self.isProcessing = false
            } else {
                self.errorMessage = "Failed to grant XP"
                self.showError = true
                self.isProcessing = false
            }
        }
    }

    func loadGrantHistory(childId: UUID) {
        // In production, this would load from repository
        // For now, using in-memory history
    }

    func dismissMessages() {
        showSuccess = false
        showError = false
        errorMessage = nil
    }
}

// MARK: - Emergency Grant View

struct EmergencyGrantView: View {
    let childId: UUID
    let childName: String
    let parentId: UUID

    @StateObject private var manager = EmergencyGrantManager()
    @State private var grantAmount: Double = 30
    @State private var selectedReason: GrantReason = .emergency
    @State private var customReason: String = ""
    @State private var showingConfirmation = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning Banner
                    warningBanner

                    // Child Info
                    childInfoCard

                    // Amount Selector
                    amountSelector

                    // Reason Selector
                    reasonSelector

                    // Custom Reason Field (if "Other" selected)
                    if selectedReason == .other {
                        customReasonField
                    }

                    // Grant Button
                    grantButton

                    // Recent Grants
                    if !manager.grantHistory.isEmpty {
                        recentGrantsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Emergency XP Grant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Grant Successful", isPresented: $manager.showSuccess) {
                Button("Done") {
                    manager.dismissMessages()
                    dismiss()
                }
            } message: {
                Text("Successfully granted \(Int(grantAmount)) XP to \(childName)")
            }
            .alert("Error", isPresented: $manager.showError) {
                Button("OK") {
                    manager.dismissMessages()
                }
            } message: {
                if let errorMessage = manager.errorMessage {
                    Text(errorMessage)
                }
            }
            .confirmationDialog(
                "Confirm Emergency Grant",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Grant \(Int(grantAmount)) XP", role: .destructive) {
                    let reason = selectedReason == .other ? customReason : selectedReason.rawValue
                    manager.grantXP(
                        parentId: parentId,
                        childId: childId,
                        amount: Int(grantAmount),
                        reason: reason
                    )
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will immediately add \(Int(grantAmount)) XP to \(childName)'s balance. This action cannot be undone.")
            }
        }
        .onAppear {
            manager.loadGrantHistory(childId: childId)
        }
    }

    // MARK: - Warning Banner

    private var warningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Use Sparingly")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Emergency grants bypass the credibility system and should only be used in special circumstances.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Child Info Card

    private var childInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(childName)
                        .font(.headline)
                    Text("Emergency XP Grant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Amount Selector

    private var amountSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Grant Amount")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(grantAmount))")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.blue)
                    Text("XP")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                Text("= \(Int(grantAmount)) minutes of screen time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Slider(value: $grantAmount, in: 5...500, step: 5)
                    .tint(.blue)

                HStack {
                    Text("5 XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("500 XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Quick amount buttons
            HStack(spacing: 12) {
                quickAmountButton(amount: 15, label: "15 min")
                quickAmountButton(amount: 30, label: "30 min")
                quickAmountButton(amount: 60, label: "1 hour")
                quickAmountButton(amount: 120, label: "2 hours")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func quickAmountButton(amount: Int, label: String) -> some View {
        Button(action: {
            grantAmount = Double(amount)
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Int(grantAmount) == amount ? .white : .blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Int(grantAmount) == amount ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }

    // MARK: - Reason Selector

    private var reasonSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reason for Grant")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(GrantReason.allCases, id: \.self) { reason in
                    reasonButton(reason: reason)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func reasonButton(reason: GrantReason) -> some View {
        Button(action: {
            selectedReason = reason
        }) {
            HStack(spacing: 12) {
                Image(systemName: reason.icon)
                    .font(.title3)
                    .foregroundColor(selectedReason == reason ? .white : .blue)
                    .frame(width: 30)

                Text(reason.rawValue)
                    .font(.subheadline)
                    .foregroundColor(selectedReason == reason ? .white : .primary)

                Spacer()

                if selectedReason == reason {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(selectedReason == reason ? Color.blue : Color(.systemGray6))
            .cornerRadius(10)
        }
    }

    // MARK: - Custom Reason Field

    private var customReasonField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Please specify the reason:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Enter reason...", text: $customReason, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Grant Button

    private var grantButton: some View {
        Button(action: {
            showingConfirmation = true
        }) {
            HStack {
                if manager.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "gift.fill")
                    Text("Grant \(Int(grantAmount)) XP")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canGrant ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canGrant || manager.isProcessing)
    }

    private var canGrant: Bool {
        if selectedReason == .other {
            return !customReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    // MARK: - Recent Grants Section

    private var recentGrantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Grants")
                .font(.headline)

            ForEach(manager.grantHistory.prefix(5)) { grant in
                grantHistoryRow(grant: grant)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func grantHistoryRow(grant: EmergencyGrant) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(grant.reason)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(grant.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("+\(grant.amount) XP")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Preview

struct EmergencyGrantView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyGrantView(
            childId: UUID(),
            childName: "Alex",
            parentId: UUID()
        )
    }
}
