import SwiftUI
import AppKit

@main
struct WorldClockApp: App {
    @StateObject private var store = WorldClockStore()

    var body: some Scene {
        WindowGroup("World Clock") {
            ContentView(store: store)
                .frame(minWidth: 820, minHeight: 540)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About World Clock") {
                    let credits = NSAttributedString(
                        string: "Created by Eric K & Contributors\n\nMulti-Timezone Digital Clocks & macOS Desktop Widget",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                            .foregroundColor: NSColor.labelColor
                        ]
                    )
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "World Clock",
                            .applicationVersion: "1.2",
                            .version: "Build 3",
                            .credits: credits,
                            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2026 Eric K • Released under the MIT License"
                        ]
                    )
                }
            }
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Clocks") {
                Button(store.isDesktopOverlayVisible ? "Hide Floating Desktop Widget" : "Pin Floating Desktop Widget") {
                    store.toggleDesktopWidgetPanel()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Divider()

                Button("Toggle 12H / 24H Format") {
                    store.preferences.use24HourFormat.toggle()
                }
                .keyboardShortcut("t", modifiers: [.command])

                Button("Toggle Seconds Display") {
                    store.preferences.showSeconds.toggle()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}

