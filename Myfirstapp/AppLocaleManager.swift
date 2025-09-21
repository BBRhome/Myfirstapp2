import SwiftUI
import Combine

final class AppLocaleManager: ObservableObject {
    @AppStorage("app_locale") var code: String = Locale.preferredLanguages.first?.hasPrefix("ru") == true ? "ru" : "en" {
        didSet {
            // Notify observers when language code changes so SwiftUI refreshes views.
            objectWillChange.send()
        }
    }

    var locale: Locale {
        Locale(identifier: code)
    }

    // ObservableObject provides objectWillChange via Combine by default.
    // We import Combine above to make it available.
}
