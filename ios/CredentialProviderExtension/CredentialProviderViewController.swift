import AuthenticationServices

class CredentialProviderViewController: ASCredentialProviderViewController {

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        // Open the main app to let user select credentials
        self.extensionContext.cancelRequest(
            withError: NSError(
                domain: ASExtensionErrorDomain,
                code: ASExtensionError.userInteractionRequired.rawValue
            )
        )
    }

    override func provideCredentialWithoutUserInteraction(
        for credentialIdentity: ASPasswordCredentialIdentity
    ) {
        let username = credentialIdentity.user

        if let sharedDefaults = UserDefaults(suiteName: "group.com.thisjowi.thisecure"),
           let passwordsData = sharedDefaults.data(forKey: "shared_passwords"),
           let passwords = try? JSONSerialization.jsonObject(with: passwordsData) as? [[String: String]] {

            for entry in passwords {
                if entry["username"] == username {
                    let credential = ASPasswordCredential(
                        user: username,
                        password: entry["password"] ?? ""
                    )
                    self.extensionContext.completeRequest(
                        withSelectedCredential: credential,
                        completionHandler: nil
                    )
                    return
                }
            }
        }

        self.extensionContext.cancelRequest(
            withError: NSError(
                domain: ASExtensionErrorDomain,
                code: ASExtensionError.userInteractionRequired.rawValue
            )
        )
    }

    override func prepareInterfaceToProvideCredential(
        for credentialIdentity: ASPasswordCredentialIdentity
    ) {
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        self.extensionContext.cancelRequest(
            withError: NSError(
                domain: ASExtensionErrorDomain,
                code: ASExtensionError.userCanceled.rawValue
            )
        )
    }
}
