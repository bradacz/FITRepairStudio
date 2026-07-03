import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: FitDocumentStore

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: 286)

            Divider()

            RecordTableView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            InspectorView()
                .frame(width: 340)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.openFilePanel()
                } label: {
                    Label(L10n.tr("toolbar.open"), systemImage: "folder")
                }

                Button {
                    store.repairCRC()
                } label: {
                    Label(L10n.tr("toolbar.repair.crc"), systemImage: "arrow.clockwise")
                }
                .disabled(!store.canEdit)

                Button {
                    store.saveAsPanel()
                } label: {
                    Label(L10n.tr("toolbar.save"), systemImage: "square.and.arrow.down")
                }
                .disabled(!store.canEdit)
            }
        }
    }
}
