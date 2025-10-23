//
//  LegalConsentService.swift
//  EnviveNew
//
//  Service for managing legal consent and COPPA compliance
//

import Foundation

// MARK: - Legal Consent Service Protocol

protocol LegalConsentService {
    /// Record legal consent for a user
    func recordConsent(_ consent: LegalConsent) throws

    /// Verify if user has valid consent
    func verifyConsent(for userId: UUID) -> ConsentVerification

    /// Get consent record for user
    func getConsent(for userId: UUID) -> LegalConsent?

    /// Check if user needs parental consent (COPPA - under 13)
    func needsParentalConsent(age: Int) -> Bool

    /// Create parental consent request
    func createParentalConsentRequest(childUserId: UUID, childName: String, childAge: Int) throws -> ParentalConsentRequest

    /// Approve parental consent request
    func approveParentalConsent(requestId: UUID, parentId: UUID) throws

    /// Get pending consent requests for parent
    func getPendingConsentRequests(for parentId: UUID) -> [ParentalConsentRequest]

    /// Revoke consent (for account deletion, etc.)
    func revokeConsent(for userId: UUID) throws
}

// MARK: - Legal Consent Service Implementation

class LegalConsentServiceImpl: LegalConsentService {
    private let storage: StorageService
    private let consentsKey = "legal_consents"
    private let consentRequestsKey = "parental_consent_requests"

    init(storage: StorageService) {
        self.storage = storage
    }

    func recordConsent(_ consent: LegalConsent) throws {
        var allConsents = getAllConsents()

        // Remove any existing consent for this user
        allConsents.removeAll { $0.userId == consent.userId }

        // Add new consent
        allConsents.append(consent)

        // Save
        storage.save(allConsents, forKey: consentsKey)

        print("✅ Recorded legal consent for user \(consent.userId)")
        print("   Privacy Policy: v\(consent.privacyPolicyVersion)")
        print("   Terms of Service: v\(consent.termsOfServiceVersion)")
        print("   Parental Consent Required: \(consent.parentalConsentRequired)")
        print("   Parental Consent Given: \(consent.parentalConsentGiven)")
    }

    func verifyConsent(for userId: UUID) -> ConsentVerification {
        guard let consent = getConsent(for: userId) else {
            return ConsentVerification(
                hasConsent: false,
                consentRecord: nil,
                needsUpdate: false,
                blockedReason: "No consent record found. Please accept Privacy Policy and Terms of Service."
            )
        }

        // Check if document versions have been updated
        let needsUpdate = consent.privacyPolicyVersion != LegalDocumentVersions.currentPrivacyPolicyVersion ||
                         consent.termsOfServiceVersion != LegalDocumentVersions.currentTermsOfServiceVersion

        if needsUpdate {
            return ConsentVerification(
                hasConsent: true,
                consentRecord: consent,
                needsUpdate: true,
                blockedReason: "Our Privacy Policy or Terms of Service have been updated. Please review and accept the new version."
            )
        }

        // Check parental consent for children under 13
        if consent.parentalConsentRequired && !consent.parentalConsentGiven {
            return ConsentVerification(
                hasConsent: false,
                consentRecord: consent,
                needsUpdate: false,
                blockedReason: "This account requires parental consent. Please have your parent approve access."
            )
        }

        return ConsentVerification(
            hasConsent: true,
            consentRecord: consent,
            needsUpdate: false,
            blockedReason: nil
        )
    }

    func getConsent(for userId: UUID) -> LegalConsent? {
        let allConsents = getAllConsents()
        return allConsents.first { $0.userId == userId }
    }

    func needsParentalConsent(age: Int) -> Bool {
        // COPPA compliance: children under 13 require parental consent
        return age < 13
    }

    func createParentalConsentRequest(childUserId: UUID, childName: String, childAge: Int) throws -> ParentalConsentRequest {
        let request = ParentalConsentRequest(
            childUserId: childUserId,
            childName: childName,
            childAge: childAge
        )

        var allRequests = getAllConsentRequests()
        allRequests.append(request)
        storage.save(allRequests, forKey: consentRequestsKey)

        print("📝 Created parental consent request for \(childName), age \(childAge)")

        return request
    }

    func approveParentalConsent(requestId: UUID, parentId: UUID) throws {
        var allRequests = getAllConsentRequests()

        guard let index = allRequests.firstIndex(where: { $0.id == requestId }) else {
            throw LegalConsentError.requestNotFound
        }

        // Update request status
        allRequests[index].status = .approved
        allRequests[index].approvedAt = Date()
        allRequests[index].approvedByParentId = parentId
        storage.save(allRequests, forKey: consentRequestsKey)

        // Update child's consent record
        let childUserId = allRequests[index].childUserId
        if var consent = getConsent(for: childUserId) {
            var updatedConsent = consent
            updatedConsent = LegalConsent(
                userId: consent.userId,
                userType: consent.userType,
                privacyPolicyVersion: consent.privacyPolicyVersion,
                termsOfServiceVersion: consent.termsOfServiceVersion,
                acceptedAt: consent.acceptedAt,
                ipAddress: consent.ipAddress,
                parentalConsentRequired: true,
                parentalConsentGiven: true,
                parentUserId: parentId
            )
            try recordConsent(updatedConsent)
        }

        print("✅ Approved parental consent for request \(requestId) by parent \(parentId)")
    }

    func getPendingConsentRequests(for parentId: UUID) -> [ParentalConsentRequest] {
        // In a real app, this would filter by household or parent relationship
        // For now, return all pending requests
        let allRequests = getAllConsentRequests()
        return allRequests.filter { $0.status == .pending }
    }

    func revokeConsent(for userId: UUID) throws {
        var allConsents = getAllConsents()
        allConsents.removeAll { $0.userId == userId }
        storage.save(allConsents, forKey: consentsKey)

        print("🗑️ Revoked consent for user \(userId)")
    }

    // MARK: - Private Helpers

    private func getAllConsents() -> [LegalConsent] {
        return storage.load(forKey: consentsKey) ?? []
    }

    private func getAllConsentRequests() -> [ParentalConsentRequest] {
        return storage.load(forKey: consentRequestsKey) ?? []
    }
}

// MARK: - Legal Consent Error

enum LegalConsentError: Error, LocalizedError {
    case requestNotFound
    case consentAlreadyExists
    case invalidAge

    var errorDescription: String? {
        switch self {
        case .requestNotFound:
            return "Parental consent request not found"
        case .consentAlreadyExists:
            return "Consent record already exists for this user"
        case .invalidAge:
            return "Invalid age provided"
        }
    }
}
