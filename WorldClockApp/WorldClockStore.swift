import SwiftUI
import AppKit
import Combine
import WidgetKit

@MainActor
final class WorldClockStore: ObservableObject {
    @Published var preferences: WorldClockPreferences {
        didSet {
            WorldClockStorage.shared.save(preferences)
        }
    }

    @Published var currentDate: Date = Date()
    @Published var isDesktopOverlayVisible: Bool = false

    private var timerCancellable: AnyCancellable?
    private var desktopPanel: NSPanel?

    init() {
        self.preferences = WorldClockStorage.shared.load()
        startClockTimer()
    }

    private func startClockTimer() {
        timerCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.currentDate = now
            }
    }

    func addClock(from entry: TimeZoneCatalogEntry, customLabel: String? = nil) {
        let newClock = ClockItem(
            cityName: entry.cityName,
            countryOrRegion: entry.countryOrRegion,
            timeZoneIdentifier: entry.timeZoneIdentifier,
            customLabel: customLabel
        )
        preferences.clocks.append(newClock)
    }

    func updateCustomLabel(for id: UUID, label: String?) {
        guard let index = preferences.clocks.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        preferences.clocks[index].customLabel = (trimmed?.isEmpty == false) ? trimmed : nil
    }

    func removeClock(id: UUID) {
        preferences.clocks.removeAll { $0.id == id }
    }

    func moveClocks(from source: IndexSet, to destination: Int) {
        preferences.clocks.move(fromOffsets: source, toOffset: destination)
    }

    func moveClockUp(at index: Int) {
        guard index > 0 else { return }
        preferences.clocks.swapAt(index, index - 1)
    }

    func moveClockDown(at index: Int) {
        guard index < preferences.clocks.count - 1 else { return }
        preferences.clocks.swapAt(index, index + 1)
    }

    func resetToDefaults() {
        preferences = WorldClockPreferences()
    }

    // MARK: - Pin-to-Desktop Live Widget Panel

    func toggleDesktopWidgetPanel() {
        if isDesktopOverlayVisible {
            hideDesktopWidgetPanel()
        } else {
            showDesktopWidgetPanel()
        }
    }

    func showDesktopWidgetPanel() {
        if desktopPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 420),
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true

            if let screen = NSScreen.main {
                let visibleFrame = screen.visibleFrame
                let x = visibleFrame.maxX - 380
                let y = visibleFrame.maxY - 450
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }

            let hostingView = NSHostingView(rootView: DesktopFloatingWidgetView(store: self))
            panel.contentView = hostingView
            self.desktopPanel = panel
        }

        desktopPanel?.makeKeyAndOrderFront(nil)
        isDesktopOverlayVisible = true
    }

    func hideDesktopWidgetPanel() {
        desktopPanel?.orderOut(nil)
        isDesktopOverlayVisible = false
    }
}

