import CoreFoundation
import Foundation
import Security
import Testing
@testable import AccrueOfflineClientApple

struct KeychainCacheKeyTests {
    @Test("explicit ThisDeviceOnly choices map to their exact Security constants")
    func explicitAccessibilityMapsExactly() throws {
        let whenUnlocked = try KeychainCacheKeyDescriptor(service: "com.example.accrue", account: "cache-key", accessibility: .whenUnlockedThisDeviceOnly)
        let afterFirstUnlock = try KeychainCacheKeyDescriptor(service: "com.example.accrue", account: "cache-key", accessGroup: "group.example.accrue", accessibility: .afterFirstUnlockThisDeviceOnly)

        #expect(CFEqual(whenUnlocked.queryAttributes[kSecAttrAccessible] as! CFString, kSecAttrAccessibleWhenUnlockedThisDeviceOnly))
        #expect(CFEqual(afterFirstUnlock.queryAttributes[kSecAttrAccessible] as! CFString, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
        #expect(afterFirstUnlock.queryAttributes[kSecAttrAccessGroup] as? String == "group.example.accrue")
    }

    @Test("descriptor rejects empty host identity and status outcomes remain bounded")
    func validatesHostConfigurationAndClassifiesStatus() {
        #expect(throws: KeychainCacheKeyConfigurationError.invalidService) {
            _ = try KeychainCacheKeyDescriptor(service: "", account: "cache-key", accessibility: .whenUnlockedThisDeviceOnly)
        }
        #expect(throws: KeychainCacheKeyConfigurationError.invalidAccount) {
            _ = try KeychainCacheKeyDescriptor(service: "com.example.accrue", account: "", accessibility: .whenUnlockedThisDeviceOnly)
        }
        #expect(KeychainCacheKeyOutcome.classify(errSecInteractionNotAllowed) == .unavailableBeforeFirstUnlock)
        #expect(KeychainCacheKeyOutcome.classify(errSecItemNotFound) == .missing)
        #expect(KeychainCacheKeyOutcome.classify(errSecSuccess) == .success)
        #expect(KeychainCacheKeyOutcome.classify(errSecAuthFailed) == .failure)
    }

    @Test("policy helper source has no key-custody operation")
    func policyHelperDoesNotOwnKeyBytes() throws {
        let source = try String(contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/AccrueOfflineClientApple/KeychainCacheKey.swift"))
        for operation in ["SecItemAdd", "SecItemUpdate", "SecItemCopyMatching", "SecKeyGeneratePair"] {
            #expect(!source.contains(operation), "policy helper must not perform \(operation)")
        }
    }
}
