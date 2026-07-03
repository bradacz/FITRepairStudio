import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class FitDocumentStore: ObservableObject {
    @Published var fileURL: URL?
    @Published var fileName: String = L10n.tr("store.no.file")
    @Published var summary: FitSummary?
    @Published var records: [FitRecordRow] = []
    @Published var sessionMessages: [FitMessage] = []
    @Published var activityMessages: [FitMessage] = []
    @Published var fileMessages: [FitMessage] = []
    @Published var selectedRecordID: Int?
    @Published var inspectorMode: InspectorMode = .record
    @Published var statusMessage: String = ""
    @Published var errorMessage: String?

    private var data: Data?
    private var messages: [FitMessage] = []

    var selectedRecord: FitRecordRow? {
        guard let selectedRecordID else { return nil }
        return records.first { $0.id == selectedRecordID }
    }

    var canEdit: Bool {
        data != nil
    }

    func openFilePanel() {
        let panel = NSOpenPanel()
        panel.title = L10n.tr("panel.open.title")
        panel.allowedContentTypes = [Self.fitContentType]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            load(url: url)
        }
    }

    func load(url: URL) {
        do {
            let loaded = try Data(contentsOf: url)
            try load(data: loaded, fileName: url.lastPathComponent, fileURL: url)
            statusMessage = L10n.tr("status.loaded", url.lastPathComponent)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func load(data: Data, fileName: String, fileURL: URL? = nil) throws {
        let parse = try FitParser.parse(data)
        self.data = data
        self.fileURL = fileURL
        self.fileName = fileName
        apply(parse: parse, data: data, fileName: fileName)
    }

    func repairCRC() {
        guard let data else { return }
        do {
            let repaired = try FitParser.repairCRC(data)
            try load(data: repaired, fileName: fileName, fileURL: fileURL)
            statusMessage = L10n.tr("status.crc.repaired")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func edit(messageIndex: Int, fieldName: String, value: String) {
        guard let data else { return }
        do {
            let edited = try FitParser.editField(data: data, messageIndex: messageIndex, fieldName: fieldName, value: value)
            let selected = selectedRecordID
            try load(data: edited, fileName: fileName, fileURL: fileURL)
            selectedRecordID = selected
            statusMessage = L10n.tr("status.field.saved", fieldName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveAsPanel() {
        guard let data else { return }
        let panel = NSSavePanel()
        panel.title = L10n.tr("panel.save.title")
        panel.nameFieldStringValue = defaultSaveName()
        panel.allowedContentTypes = [Self.fitContentType]
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url, options: .atomic)
                statusMessage = L10n.tr("status.saved", url.lastPathComponent)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func apply(parse: FitParseResult, data: Data, fileName: String) {
        messages = parse.messages
        summary = FitParser.summary(for: fileName, data: data, parseResult: parse)

        let recordMessages = parse.messages.filter { $0.globalNumber == 20 }
        records = recordMessages.enumerated().map { index, message in
            FitRecordRow(recordIndex: index, message: message)
        }
        sessionMessages = parse.messages.filter { $0.globalNumber == 18 }
        activityMessages = parse.messages.filter { $0.globalNumber == 34 }
        fileMessages = parse.messages.filter { $0.globalNumber == 0 }

        if selectedRecordID == nil {
            selectedRecordID = records.first?.id
        }
    }

    private func defaultSaveName() -> String {
        let stem = (fileName as NSString).deletingPathExtension
        return "\(stem.isEmpty ? "activity" : stem).edited.fit"
    }

    private static var fitContentType: UTType {
        UTType(filenameExtension: "fit") ?? .data
    }
}

enum InspectorMode: String, CaseIterable, Identifiable {
    case record
    case session
    case activity
    case file

    var id: String { rawValue }

    var title: String {
        switch self {
        case .record:
            return L10n.tr("mode.record")
        case .session:
            return L10n.tr("mode.session")
        case .activity:
            return L10n.tr("mode.activity")
        case .file:
            return L10n.tr("mode.file")
        }
    }
}
