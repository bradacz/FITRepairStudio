import AppKit
import Foundation

enum AppWindowID {
    static let legalInfo = "legal-info"
}

enum AppLegal {
    static let companyName = "Localio Labs s.r.o."
    static let companyAddress = "Štefánikova 100, Újezd u Brna, 664 53, Česká republika"
    static let companyID = "24338770"
    static let vatID = "CZ24338770"
    static let duns = "773919757"
    static let companyRegistration = "Společnost zapsána u Krajského soudu v Brně, odd. C 149437."
    static let contactEmail = "info@mylocalio.com"
    static let bankName = "ČSOB a.s."
    static let bankAccountCZK = "6086033045/0300"
    static let bankAccountEUR = "366649154/0300"
    static let iban = "CZ4703000000000366649154"
    static let bic = "CEKOCZPP"

    static let productWebsite = URL(string: "https://fitrepairstudio.site/")!
    static let companyWebsite = URL(string: "https://www.mylocalio.com/")!
    static let privacy = URL(string: "https://mylocalio.com/gdpr")!
    static let terms = URL(string: "https://mylocalio.com/obchodni-podminky")!
    static let sourceCode = URL(string: "https://github.com/bradacz/FITRepairStudio")!
    static let supportEmail = URL(string: "mailto:info@mylocalio.com")!

    static func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    static var versionText: String {
        AppVersion.displayText
    }
}
