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

// MARK: - CredentialProviderViewController

class CredentialProviderViewController: ASCredentialProviderViewController {

    private var serviceIdentifiers: [ASCredentialServiceIdentifier] = []
    private var filterResults: [[String: String]] = []
    private var tableView: UITableView?
    private let credentialService = CredentialKeychainService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    // MARK: - QuickType Autofill (no user interaction)

    override func provideCredentialWithoutUserInteraction(
        for credentialIdentity: ASPasswordCredentialIdentity
    ) {
        guard let recordId = credentialIdentity.recordIdentifier else {
            cancelWithUserInteractionRequired()
            return
        }

        guard let entry = credentialService.findCredentialById(recordId),
              let username = entry["username"],
              let password = entry["password"] else {
            cancelWithUserInteractionRequired()
            return
        }

        let credential = ASPasswordCredential(user: username, password: password)
        extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }

    // MARK: - Credential List UI

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        self.serviceIdentifiers = serviceIdentifiers
        filterResults = matchingCredentials()
        setupTableView()
    }

    override func prepareInterfaceToProvideCredential(
        for credentialIdentity: ASPasswordCredentialIdentity
    ) {
        guard let recordId = credentialIdentity.recordIdentifier,
              let entry = credentialService.findCredentialById(recordId),
              let username = entry["username"],
              let password = entry["password"] else {
            cancelWithError(message: "Credential not found")
            return
        }

        let credential = ASPasswordCredential(user: username, password: password)
        extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }

    // MARK: - Helpers

    private func matchingCredentials() -> [[String: String]] {
        let allCredentials = credentialService.readCredentials()

        guard !serviceIdentifiers.isEmpty else {
            return allCredentials
        }

        var matched: [[String: String]] = []
        var seen = Set<String>()

        for serviceId in serviceIdentifiers {
            let domain = serviceId.identifier.lowercased()
            for cred in allCredentials {
                guard let id = cred["id"], !seen.contains(id) else { continue }
                guard let website = cred["website"]?.lowercased() else { continue }

                if website.contains(domain) || domain.contains(website) {
                    matched.append(cred)
                    seen.insert(id)
                }
            }
        }

        if matched.isEmpty {
            matched = allCredentials
        }

        return matched
    }

    private func setupTableView() {
        let navBar = UINavigationBar(frame: .zero)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        let navItem = UINavigationItem(title: "THISECURE")
        navItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancel(_:))
        )
        navBar.setItems([navItem], animated: false)
        view.addSubview(navBar)

        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        self.tableView = tableView

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        if filterResults.isEmpty {
            let label = UILabel()
            label.text = "No matching credentials"
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            label.sizeToFit()
            tableView.backgroundView = label
        }
    }

    private func cancelWithUserInteractionRequired() {
        extensionContext.cancelRequest(
            withError: NSError(
                domain: ASExtensionErrorDomain,
                code: ASExtensionError.userInteractionRequired.rawValue
            )
        )
    }

    private func cancelWithError(message: String) {
        extensionContext.cancelRequest(
            withError: NSError(
                domain: ASExtensionErrorDomain,
                code: ASExtensionError.failed.rawValue,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        )
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        extensionContext.cancelRequest(
            withError: NSError(
                domain: ASExtensionErrorDomain,
                code: ASExtensionError.userCanceled.rawValue
            )
        )
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension CredentialProviderViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let entry = filterResults[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = entry["title"] ?? entry["website"] ?? "Unknown"
        config.secondaryText = entry["username"] ?? ""
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = filterResults[indexPath.row]

        guard let username = entry["username"], let password = entry["password"] else {
            return
        }

        let credential = ASPasswordCredential(user: username, password: password)
        extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }
}
