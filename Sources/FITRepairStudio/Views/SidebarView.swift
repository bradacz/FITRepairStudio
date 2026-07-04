import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: FitDocumentStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.tr("app.window.title"))
                    .font(.headline)
                Text(store.fileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    actionPanel
                    diagnosticsPanel
                    summaryPanel
                    messageCountsPanel
                }
                .padding(14)
            }
        }
        .background(.regularMaterial)
    }

    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            PanelTitle(L10n.tr("sidebar.file"))

            Button {
                store.openFilePanel()
            } label: {
                Label(L10n.tr("sidebar.open.fit"), systemImage: "folder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderedProminent)

            Button {
                store.repairCRC()
            } label: {
                Label(L10n.tr("sidebar.repair.crc"), systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(!store.canEdit)

            Button {
                store.saveAsPanel()
            } label: {
                Label(L10n.tr("sidebar.save.as"), systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(!store.canEdit)

            if !store.statusMessage.isEmpty {
                Text(store.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
        }
    }


    private var diagnosticsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(L10n.tr("sidebar.diagnostics"))

            if let summary = store.summary {
                StatusRow(title: "Header CRC", ok: summary.headerCRCOk)
                StatusRow(title: "File CRC", ok: summary.fileCRCOk)
                StatusRow(title: "Parser", ok: summary.parseErrors.isEmpty)
                StatusRow(title: L10n.tr("status.time"), ok: summary.timestampBackwardsCount == 0)
                StatusRow(title: "GPS", ok: summary.badCoordinateCount == 0)

                ForEach(summary.warnings, id: \.self) { warning in
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text(L10n.tr("sidebar.load.fit.file"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summaryPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            PanelTitle(L10n.tr("sidebar.activity"))

            if let summary = store.summary {
                KeyValueRow(L10n.tr("summary.records"), "\(summary.recordCount)")
                KeyValueRow(L10n.tr("summary.session"), "\(summary.sessionCount)")
                KeyValueRow(L10n.tr("summary.activity"), "\(summary.activityCount)")
                KeyValueRow(L10n.tr("summary.size"), "\(summary.actualSize) B")
                KeyValueRow(L10n.tr("summary.profile"), "\(summary.protocolVersion) / \(summary.profileVersion)")
                KeyValueRow(L10n.tr("summary.start"), summary.firstRecordTime)
                KeyValueRow(L10n.tr("summary.end"), summary.lastRecordTime)
                if let duration = summary.durationSeconds {
                    KeyValueRow(L10n.tr("summary.duration"), L10n.tr("summary.duration.seconds", duration))
                }
                KeyValueRow("Latitude", summary.latitudeRange)
                KeyValueRow("Longitude", summary.longitudeRange)
            } else {
                Text(L10n.tr("sidebar.no.data"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var messageCountsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            PanelTitle(L10n.tr("sidebar.messages"))

            if let summary = store.summary {
                ForEach(summary.messageCounts.prefix(12), id: \.0) { name, count in
                    KeyValueRow(name, "\(count)")
                }
            } else {
                Text(L10n.tr("sidebar.no.messages"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PanelTitle: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

struct KeyValueRow: View {
    var key: String
    var value: String

    init(_ key: String, _ value: String) {
        self.key = key
        self.value = value
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value.isEmpty ? "-" : value)
                .font(.caption.monospacedDigit())
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct StatusRow: View {
    var title: String
    var ok: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(ok ? L10n.tr("status.ok") : L10n.tr("status.error"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(ok ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background((ok ? Color.green : Color.red).opacity(0.12), in: Capsule())
        }
    }
}
