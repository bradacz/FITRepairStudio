import Foundation

enum L10n {
    static func tr(_ key: String, _ arguments: CVarArg...) -> String {
        let mainValue = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        let format = mainValue == key ? Bundle.module.localizedString(forKey: key, value: nil, table: nil) : mainValue
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale.current, arguments: arguments)
    }
}
