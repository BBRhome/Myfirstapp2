import Foundation
import AuthenticationServices
import Combine
import UIKit

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var appleUserID: String?

    private let keychainKey = "appleUserIdentifier"

    override init() {
        super.init()
        if let id = try? KeychainHelper.shared.read(service: keychainKey, account: "user") {
            self.appleUserID = id
            self.isAuthenticated = true
        }
    }

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func continueWithoutSignIn() {
        self.appleUserID = nil
        self.isAuthenticated = true
    }

    func signOut() {
        try? KeychainHelper.shared.delete(service: keychainKey, account: "user")
        self.appleUserID = nil
        self.isAuthenticated = false
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let userID = appleIDCredential.user
            try? KeychainHelper.shared.save(userID, service: keychainKey, account: "user")
            self.appleUserID = userID
            self.isAuthenticated = true

            if let fullName = appleIDCredential.fullName {
                let formatted = PersonNameComponentsFormatter().string(from: fullName).trimmingCharacters(in: .whitespacesAndNewlines)
                if !formatted.isEmpty {
                    UserDefaults.standard.set(formatted, forKey: "profile_name")
                }
            }
            if let email = appleIDCredential.email {
                UserDefaults.standard.set(email, forKey: "profile_email")
            }

        default:
            break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple error: \(error)")
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Ищем активное окно среди всех сцен (совместимо с iOS/iPadOS)
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return window
        }
        // Фолбэк, если ключевое окно не найдено
        return UIWindow()
    }
}
