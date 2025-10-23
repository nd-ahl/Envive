//
//  LegalConsent.swift
//  EnviveNew
//
//  Legal consent tracking for privacy policy and terms of service
//  Includes COPPA compliance for children under 13
//

import Foundation

// MARK: - Legal Consent Record

struct LegalConsent: Codable {
    let userId: UUID
    let userType: UserConsentType  // parent or child
    let privacyPolicyVersion: String
    let termsOfServiceVersion: String
    let acceptedAt: Date
    let ipAddress: String?  // Optional for compliance tracking
    let parentalConsentRequired: Bool
    let parentalConsentGiven: Bool
    let parentUserId: UUID?  // For child accounts requiring parental consent

    init(
        userId: UUID,
        userType: UserConsentType,
        privacyPolicyVersion: String,
        termsOfServiceVersion: String,
        acceptedAt: Date = Date(),
        ipAddress: String? = nil,
        parentalConsentRequired: Bool = false,
        parentalConsentGiven: Bool = false,
        parentUserId: UUID? = nil
    ) {
        self.userId = userId
        self.userType = userType
        self.privacyPolicyVersion = privacyPolicyVersion
        self.termsOfServiceVersion = termsOfServiceVersion
        self.acceptedAt = acceptedAt
        self.ipAddress = ipAddress
        self.parentalConsentRequired = parentalConsentRequired
        self.parentalConsentGiven = parentalConsentGiven
        self.parentUserId = parentUserId
    }
}

// MARK: - User Consent Type

enum UserConsentType: String, Codable {
    case parent = "parent"
    case childOver13 = "child_over_13"  // Can consent for themselves
    case childUnder13 = "child_under_13"  // Requires parental consent (COPPA)
}

// MARK: - Legal Document Versions

struct LegalDocumentVersions {
    static let currentPrivacyPolicyVersion = "1.0"
    static let currentTermsOfServiceVersion = "1.0"
    static let privacyPolicyURL = "https://nd-ahl.github.io/Envive/privacy-policy"
    static let termsOfServiceURL = "https://nd-ahl.github.io/Envive/terms-of-service"
}

// MARK: - Parental Consent Request

struct ParentalConsentRequest: Codable {
    let id: UUID
    let childUserId: UUID
    let childName: String
    let childAge: Int
    let requestedAt: Date
    var approvedAt: Date?
    var approvedByParentId: UUID?
    var status: ConsentStatus

    enum ConsentStatus: String, Codable {
        case pending = "pending"
        case approved = "approved"
        case denied = "denied"
    }

    init(
        id: UUID = UUID(),
        childUserId: UUID,
        childName: String,
        childAge: Int,
        requestedAt: Date = Date(),
        approvedAt: Date? = nil,
        approvedByParentId: UUID? = nil,
        status: ConsentStatus = .pending
    ) {
        self.id = id
        self.childUserId = childUserId
        self.childName = childName
        self.childAge = childAge
        self.requestedAt = requestedAt
        self.approvedAt = approvedAt
        self.approvedByParentId = approvedByParentId
        self.status = status
    }
}

// MARK: - Consent Verification Result

struct ConsentVerification {
    let hasConsent: Bool
    let consentRecord: LegalConsent?
    let needsUpdate: Bool  // If document versions have changed
    let blockedReason: String?

    var canAccessApp: Bool {
        return hasConsent && !needsUpdate
    }
}
