import Foundation
import KeychainAccess
import ReactiveSwift
import Fetch

public class CredentialsController {
    
    private init() {}
    public static let shared = CredentialsController()
    
    private let keychain = Keychain(service: Config.keyPrefix)
    private let credentialStorageKey = Config.Keychain.credentialStorageKey
    private var cachedCredentials: Credentials?
    
    private var currentCredentialsChangedSignalObserver = Signal<(), Never>.pipe()
    public var currentCredentialsChangedSignal: Signal<(), Never> {
        return currentCredentialsChangedSignalObserver.output
    }
    
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    public var currentCredentials: Credentials? {
        get {
            if let credentialsData = keychain[data: credentialStorageKey],
                let credentials = try? jsonDecoder.decode(Credentials.self, from: credentialsData), cachedCredentials == nil {
                cachedCredentials = credentials
                return credentials
            } else {
                return cachedCredentials
            }
        }
        set {
            if let credentials = newValue {
                keychain[data: credentialStorageKey] = try? jsonEncoder.encode(credentials)
                cachedCredentials = credentials
            } else {
                cachedCredentials = nil
                _ = try? keychain.remove(credentialStorageKey)
            }
            currentCredentialsChangedSignalObserver.input.send(value: ())
        }
    }
    
    public func resetOnNewInstallations() {
        if let installationDate = UserDefaults.standard.value(forKey: "installationDate") as? Date {
            print("existing installation, app installed: \(installationDate)")
        } else {
            print("new installation, resetting credentials in keychain")
            currentCredentials = nil
            UserDefaults.standard.set(Date(), forKey: "installationDate")
        }
    }
    
}

public struct Credentials: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: TimeInterval
    
    public init(accessToken: String, refreshToken: String?, expiresIn: TimeInterval?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken ?? ""
        self.expiresIn = expiresIn ?? NSDate.distantFuture.timeIntervalSinceReferenceDate
    }
}
