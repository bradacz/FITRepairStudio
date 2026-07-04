import SwiftUI

struct LegalCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(L10n.tr("menu.about.legal")) {
                openWindow(id: AppWindowID.legalInfo)
            }
        }

        CommandMenu(L10n.tr("menu.legal")) {
            Button(L10n.tr("menu.about.legal")) {
                openWindow(id: AppWindowID.legalInfo)
            }

            Divider()

            Button(L10n.tr("legal.link.privacy")) {
                AppLegal.open(AppLegal.privacy)
            }

            Button(L10n.tr("legal.link.terms")) {
                AppLegal.open(AppLegal.terms)
            }

            Button(L10n.tr("legal.link.product.website")) {
                AppLegal.open(AppLegal.productWebsite)
            }

            Button(L10n.tr("legal.link.source")) {
                AppLegal.open(AppLegal.sourceCode)
            }
        }
    }
}
