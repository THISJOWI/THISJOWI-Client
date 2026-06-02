import Flutter
import UIKit
import AuthenticationServices
import Security
import os.log

// MARK: - Shared Keychain Service (used by both Runner and CredentialProviderExtension)

class CredentialKeychainService {
    static let shared = CredentialKeychainService()

    private let service = "com.thisjowi.shared.credentials"

    private var accessGroup: String {
        let teamId = Bundle.main.infoDictionary?["AppIdentifierPrefix"] as? String ?? ""
        return "\(teamId)group.com.thisjowi.thisecure"
    }

    func readCredentials() -> [[String: String]] {
        let query: [String: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: service,
            kSecAttrAccessGroup: accessGroup,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [String: Any]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status != errSecItemNotFound {
                os_log("Keychain read error: %d", log: .default, type: .error, status)
            }
            return []
        }

        do {
            let credentials = try JSONSerialization.jsonObject(with: data) as? [[String: String]]
            return credentials ?? []
        } catch {
            os_log("Keychain JSON decode error: %@", log: .default, type: .error, error.localizedDescription)
            return []
        }
    }

    func saveCredentials(_ credentials: [[String: String]]) -> Bool {
        guard let data = try? JSONSerialization.data(withJSONObject: credentials, options: .prettyPrinted) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: service,
            kSecAttrAccessGroup: accessGroup,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData: data
        ] as [String: Any]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            os_log("Keychain save error: %d", log: .default, type: .error, status)
            return false
        }

        return true
    }

    func clearCredentials() -> Bool {
        let query: [String: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: service,
            kSecAttrAccessGroup: accessGroup
        ] as [String: Any]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    func findCredentialById(_ id: String) -> [String: String]? {
        let credentials = readCredentials()
        return credentials.first { $0["id"] == id }
    }

    func findCredentialsForDomain(_ domain: String) -> [[String: String]] {
        let credentials = readCredentials()
        return credentials.filter { cred in
            guard let website = cred["website"]?.lowercased() else { return false }
            return website.contains(domain.lowercased())
        }
    }
}

// MARK: - Flutter AppDelegate

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CredentialSharingPlugin") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.thisjowi/credentials",
      binaryMessenger: registrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }

      switch call.method {
      case "syncPasswordsToAppGroup":
        guard let args = call.arguments as? [String: Any],
              let passwordsJson = args["passwords"] as? String,
              let data = passwordsJson.data(using: .utf8),
              let credentials = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid passwords data", details: nil))
          return
        }
        let forceRegister = args["forceRegisterIdentities"] as? Bool ?? false
        let saved = CredentialKeychainService.shared.saveCredentials(credentials)
        if saved && forceRegister {
          self.registerIdentities(credentials)
        }
        result(saved)

      case "registerCredentialIdentities":
        guard let args = call.arguments as? [String: Any],
              let credentialsJson = args["credentials"] as? String,
              let data = credentialsJson.data(using: .utf8),
              let credentials = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid credentials data", details: nil))
          return
        }
        self.registerIdentities(credentials)
        result(true)

      case "clearCredentialIdentities":
        CredentialKeychainService.shared.clearCredentials()
        ASCredentialIdentityStore.shared.removeAllCredentialIdentities { _, _ in }
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func registerIdentities(_ credentials: [[String: String]]) {
    let identities = credentials.compactMap { cred -> ASPasswordCredentialIdentity? in
      guard let username = cred["username"], let website = cred["website"], !username.isEmpty else {
        return nil
      }
      let serviceId: ASCredentialServiceIdentifier
      if URL(string: website) != nil {
        serviceId = ASCredentialServiceIdentifier(identifier: website, type: .URL)
      } else {
        serviceId = ASCredentialServiceIdentifier(identifier: website, type: .domain)
      }
      return ASPasswordCredentialIdentity(
        serviceIdentifier: serviceId,
        user: username,
        recordIdentifier: cred["id"]
      )
    }

    ASCredentialIdentityStore.shared.saveCredentialIdentities(identities) { _, _ in }
  }
}
