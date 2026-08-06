import Foundation
import Security

/// The only Keychain accessibility choices the package will describe. Both choices
/// are device-bound; select After First Unlock only when the host needs background recovery.
public enum KeychainAccessibility: Sendable, Equatable {
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly

    fileprivate var securityValue: CFString {
        switch self {
        case .whenUnlockedThisDeviceOnly: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}

public enum KeychainCacheKeyConfigurationError: Error, Sendable, Equatable {
    case invalidService
    case invalidAccount
}

/// Host-selected Keychain query attributes. This descriptor neither reads nor writes key bytes.
public struct KeychainCacheKeyDescriptor {
    public let service: String
    public let account: String
    public let accessGroup: String?
    public let accessibility: KeychainAccessibility

    public init(service: String, account: String, accessGroup: String? = nil, accessibility: KeychainAccessibility) throws {
        guard !service.isEmpty else { throw KeychainCacheKeyConfigurationError.invalidService }
        guard !account.isEmpty else { throw KeychainCacheKeyConfigurationError.invalidAccount }
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
        self.accessibility = accessibility
    }

    public var queryAttributes: [CFString: Any] {
        var attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: accessibility.securityValue
        ]
        if let accessGroup { attributes[kSecAttrAccessGroup] = accessGroup }
        return attributes
    }
}

/// Bounded results for a host-performed Keychain operation; raw OSStatus values do not escape.
public enum KeychainCacheKeyOutcome: Sendable, Equatable {
    case success
    case unavailableBeforeFirstUnlock
    case missing
    case failure

    public static func classify(_ status: OSStatus) -> KeychainCacheKeyOutcome {
        switch status {
        case errSecSuccess: .success
        case errSecInteractionNotAllowed: .unavailableBeforeFirstUnlock
        case errSecItemNotFound: .missing
        default: .failure
        }
    }
}
