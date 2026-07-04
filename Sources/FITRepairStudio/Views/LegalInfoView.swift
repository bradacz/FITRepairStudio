import SwiftUI

struct LegalInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                LegalSection(title: L10n.tr("legal.section.version")) {
                    LegalInfoRow(title: L10n.tr("version.number"), value: "v\(AppVersion.current.version)")
                    LegalInfoRow(title: L10n.tr("version.build"), value: AppVersion.current.build)
                    LegalInfoRow(title: L10n.tr("version.release.date.title"), value: AppVersion.releaseDateText)
                    Text(L10n.tr("version.summary"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(AppVersion.highlightKeys, id: \.self) { key in
                        LegalBullet(text: L10n.tr(key))
                    }
                }

                LegalSection(title: L10n.tr("legal.section.creator")) {
                    LegalInfoRow(title: L10n.tr("legal.company.name"), value: AppLegal.companyName)
                    LegalInfoRow(title: L10n.tr("legal.company.address"), value: AppLegal.companyAddress)
                    LegalInfoRow(title: L10n.tr("legal.company.id"), value: AppLegal.companyID)
                    LegalInfoRow(title: L10n.tr("legal.company.vat"), value: AppLegal.vatID)
                    LegalInfoRow(title: L10n.tr("legal.company.duns"), value: AppLegal.duns)
                    LegalInfoRow(title: L10n.tr("legal.company.registration"), value: AppLegal.companyRegistration)
                    LegalInfoRow(title: L10n.tr("legal.company.contact"), value: AppLegal.contactEmail)
                }

                LegalSection(title: L10n.tr("legal.section.documents")) {
                    Text(L10n.tr("legal.documents.description"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 10)], spacing: 10) {
                        LegalLinkButton(
                            title: L10n.tr("legal.link.privacy"),
                            systemImage: "hand.raised",
                            url: AppLegal.privacy
                        )
                        LegalLinkButton(
                            title: L10n.tr("legal.link.terms"),
                            systemImage: "doc.text",
                            url: AppLegal.terms
                        )
                        LegalLinkButton(
                            title: L10n.tr("legal.link.product.website"),
                            systemImage: "safari",
                            url: AppLegal.productWebsite
                        )
                        LegalLinkButton(
                            title: L10n.tr("legal.link.source"),
                            systemImage: "chevron.left.forwardslash.chevron.right",
                            url: AppLegal.sourceCode
                        )
                        LegalLinkButton(
                            title: L10n.tr("legal.link.support"),
                            systemImage: "envelope",
                            url: AppLegal.supportEmail
                        )
                    }
                }

                LegalSection(title: L10n.tr("legal.section.privacy")) {
                    LegalBullet(text: L10n.tr("legal.privacy.local"))
                    LegalBullet(text: L10n.tr("legal.privacy.no.upload"))
                    LegalBullet(text: L10n.tr("legal.privacy.website"))
                    LegalBullet(text: L10n.tr("legal.privacy.payments"))
                }

                LegalSection(title: L10n.tr("legal.section.bank")) {
                    LegalInfoRow(title: L10n.tr("legal.bank.name"), value: AppLegal.bankName)
                    LegalInfoRow(title: L10n.tr("legal.bank.czk"), value: AppLegal.bankAccountCZK)
                    LegalInfoRow(title: L10n.tr("legal.bank.eur"), value: AppLegal.bankAccountEUR)
                    LegalInfoRow(title: "IBAN", value: AppLegal.iban)
                    LegalInfoRow(title: "BIC/SWIFT", value: AppLegal.bic)
                }

                LegalSection(title: L10n.tr("legal.section.disclaimer")) {
                    Text(L10n.tr("legal.disclaimer.repair"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.tr("legal.disclaimer.affiliation"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 650)
        .frame(minHeight: 640)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.14))
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.tr("legal.title"))
                    .font(.title2.weight(.semibold))
                Text(AppVersion.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(L10n.tr("legal.subtitle"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct LegalSection<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                content
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.18))
        }
    }
}

private struct LegalInfoRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 145, alignment: .leading)
            Text(value)
                .font(.callout)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

private struct LegalBullet: View {
    var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.top, 3)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LegalLinkButton: View {
    var title: String
    var systemImage: String
    var url: URL

    var body: some View {
        Button {
            AppLegal.open(url)
        } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }
}
