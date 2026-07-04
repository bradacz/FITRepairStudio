import AppKit
import SwiftUI

@main
struct FITRepairStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = FitDocumentStore()

    var body: some Scene {
        WindowGroup(L10n.tr("app.window.title")) {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1180, minHeight: 720)
                .alert(L10n.tr("alert.error.title"), isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.clearError() } }
                )) {
                    Button(L10n.tr("button.ok")) { store.clearError() }
                } message: {
                    Text(store.errorMessage ?? "")
                }
                .onReceive(NotificationCenter.default.publisher(for: .openFitFile)) { notification in
                    guard let path = notification.object as? String else { return }
                    store.load(url: URL(fileURLWithPath: path))
                }
        }
        .commands {
            LegalCommands()

            CommandGroup(replacing: .newItem) {
                Button(L10n.tr("menu.open.fit")) {
                    store.openFilePanel()
                }
                .keyboardShortcut("o")
            }

            CommandGroup(after: .saveItem) {
                Button(L10n.tr("menu.save.as")) {
                    store.saveAsPanel()
                }
                .keyboardShortcut("s")
                .disabled(!store.canEdit)

                Button(L10n.tr("menu.repair.crc")) {
                    store.repairCRC()
                }
                .keyboardShortcut("r")
                .disabled(!store.canEdit)
            }
        }

        Window(L10n.tr("legal.window.title"), id: AppWindowID.legalInfo) {
            LegalInfoView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        NotificationCenter.default.post(name: .openFitFile, object: filename)
        return true
    }
}
