import SwiftUI

struct RecordTableView: View {
    @EnvironmentObject private var store: FitDocumentStore

    private let columns: [(String, CGFloat)] = [
        ("#", 54),
        (L10n.tr("column.timestamp"), 205),
        (L10n.tr("column.latitude"), 118),
        (L10n.tr("column.longitude"), 118),
        (L10n.tr("column.distance"), 104),
        (L10n.tr("column.speed"), 88),
        (L10n.tr("column.altitude"), 94),
        (L10n.tr("column.hr"), 54),
        (L10n.tr("column.cadence"), 54),
        (L10n.tr("column.power"), 62),
        (L10n.tr("column.temperature"), 62)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if store.records.isEmpty {
                EmptyStateView(
                    title: L10n.tr("records.empty.title"),
                    systemImage: "doc.badge.plus",
                    description: L10n.tr("records.empty.description")
                )
            } else {
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            ForEach(store.records) { row in
                                RecordRowView(row: row, selected: store.selectedRecordID == row.id, columns: columns)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        store.selectedRecordID = row.id
                                        store.inspectorMode = .record
                                    }
                            }
                        } header: {
                            tableHeader
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.tr("records.title"))
                    .font(.headline)
                Text(L10n.tr("records.count", store.records.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let summary = store.summary {
                Text(summary.fileCRCOk ? L10n.tr("records.strava.ok") : L10n.tr("records.crc.error"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(summary.fileCRCOk ? .green : .red)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background((summary.fileCRCOk ? Color.green : Color.red).opacity(0.12), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                Text(column.0)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: column.1, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(.bar)
    }
}

struct RecordRowView: View {
    var row: FitRecordRow
    var selected: Bool
    var columns: [(String, CGFloat)]

    private var values: [String] {
        [
            "\(row.recordIndex)",
            row.timestamp,
            row.latitude,
            row.longitude,
            row.distance,
            row.speed,
            row.altitude,
            row.heartRate,
            row.cadence,
            row.power,
            row.temperature
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                Text(value.isEmpty ? "-" : value)
                    .font(.system(size: 12, design: index == 1 ? .default : .monospaced))
                    .foregroundStyle(value.isEmpty ? .tertiary : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: columns[index].1, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(selected ? Color.accentColor.opacity(0.15) : Color.clear)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
