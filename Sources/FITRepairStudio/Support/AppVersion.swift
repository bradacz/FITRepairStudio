import Foundation

struct AppVersionInfo: Decodable {
    var version: String
    var build: String
    var releaseDate: String
}

enum AppVersion {
    static let current = load()
    static let highlightKeys = [
        "version.highlight.crc",
        "version.highlight.records",
        "version.highlight.privacy",
        "version.highlight.legal"
    ]

    static var displayText: String {
        L10n.tr("legal.version", current.version, current.build)
    }

    static var releaseDateText: String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"

        guard let date = parser.date(from: current.releaseDate) else {
            return current.releaseDate
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static func load() -> AppVersionInfo {
        let urls = [
            Bundle.main.url(forResource: "AppVersion", withExtension: "json"),
            Bundle.module.url(forResource: "AppVersion", withExtension: "json")
        ].compactMap { $0 }

        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(AppVersionInfo.self, from: data)
            } catch {
                continue
            }
        }

        return AppVersionInfo(version: "1.0.1", build: "2", releaseDate: "2026-07-04")
    }
}
