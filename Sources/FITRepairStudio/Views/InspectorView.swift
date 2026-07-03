import SwiftUI

struct InspectorView: View {
    @EnvironmentObject private var store: FitDocumentStore

    var body: some View {
        VStack(spacing: 0) {
            Picker(L10n.tr("inspector.title"), selection: $store.inspectorMode) {
                ForEach(InspectorMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(currentMessages) { message in
                        MessageInspectorCard(message: message)
                    }

                    if currentMessages.isEmpty {
                        EmptyStateView(title: L10n.tr("inspector.empty.title"), systemImage: "sidebar.right", description: emptyText)
                            .frame(maxWidth: .infinity, minHeight: 240)
                    }
                }
                .padding(14)
            }
        }
        .background(.regularMaterial)
    }

    private var currentMessages: [FitMessage] {
        switch store.inspectorMode {
        case .record:
            return store.selectedRecord.map { [$0.message] } ?? []
        case .session:
            return store.sessionMessages
        case .activity:
            return store.activityMessages
        case .file:
            return store.fileMessages
        }
    }

    private var emptyText: String {
        switch store.inspectorMode {
        case .record:
            return L10n.tr("inspector.empty.record")
        case .session:
            return L10n.tr("inspector.empty.session")
        case .activity:
            return L10n.tr("inspector.empty.activity")
        case .file:
            return L10n.tr("inspector.empty.file")
        }
    }
}

struct MessageInspectorCard: View {
    @EnvironmentObject private var store: FitDocumentStore
    var message: FitMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.typeName)
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.tr("inspector.index.offset", message.index, message.offset))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(L10n.tr("inspector.global", Int(message.globalNumber)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.background.opacity(0.65))

            Divider()

            VStack(spacing: 0) {
                ForEach(message.fields) { field in
                    EditableFieldRow(messageIndex: message.index, field: field)
                    Divider()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.secondary.opacity(0.18))
        }
    }
}

struct EditableFieldRow: View {
    @EnvironmentObject private var store: FitDocumentStore
    var messageIndex: Int
    var field: FitFieldRow

    @State private var draft: String

    init(messageIndex: Int, field: FitFieldRow) {
        self.messageIndex = messageIndex
        self.field = field
        _draft = State(initialValue: field.value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(field.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if !field.isEditable {
                    Text(L10n.tr("inspector.read.only"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack(spacing: 8) {
                TextField("", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .disabled(!field.isEditable)
                    .onSubmit {
                        commit()
                    }

                Button {
                    commit()
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.bordered)
                .disabled(!field.isEditable || draft == field.value)
                .help(L10n.tr("inspector.save.field.help"))
            }
        }
        .padding(10)
        .onChange(of: field.value) { newValue in
            draft = newValue
        }
    }

    private func commit() {
        guard field.isEditable, draft != field.value else { return }
        store.edit(messageIndex: messageIndex, fieldName: field.name, value: draft)
    }
}
