import Foundation

/// Global set of configuration values for this application.
public struct Config {
    static let keyPrefix = "at.allaboutapps"

    // MARK: Keychain

    public struct Keychain {
        static let credentialStorageKey = "CredentialsStorage"
        static let credentialsKey = "credentials"
    }
}
