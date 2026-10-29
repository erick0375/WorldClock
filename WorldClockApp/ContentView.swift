import SwiftUI
import WidgetKit

struct ContentView: View {
    @ObservedObject var store: WorldClockStore
    @State private var showingAddCitySheet = false
    @State private var editingClockItem: ClockItem?
    @State private var editingLabelText: String = ""
    @State private var selectedPreviewFamily: WidgetFamilyPreview = .large

    enum WidgetFamilyPreview: String, CaseIterable, Identifiable {
        case small = "Small (2 Clocks)"
        case medium = "Medium (4 Clocks)"
        case large = "Large (6 Clocks)"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationSplitView {
            sidebarView
                .navigationSplitViewColumnWidth(min: 280, ideal: 310, max: 380)
        } detail: {
            mainDashboardView
        }
        .sheet(isPresented: $showingAddCitySheet) {
            AddCitySheetView(store: store)
        }
        .sheet(item: $editingClockItem) { clock in
            EditClockLabelSheet(
                clock: clock,
                labelText: $editingLabelText,
                onSave: { newLabel in
                    store.updateCustomLabel(for: clock.id, label: newLabel)
                    editingClockItem = nil
                },
                onCancel: {
                    editingClockItem = nil
                }
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingAddCitySheet = true
                } label: {
                    Label("Add City", systemImage: "plus.circle.fill")
                }
                .help("Add a city or timezone")

                Button {
                    store.toggleDesktopWidgetPanel()
                } label: {
                    Label(
                        store.isDesktopOverlayVisible ? "Hide Desktop Widget" : "Pin Live Widget",
                        systemImage: store.isDesktopOverlayVisible ? "pip.exit" : "pip.enter"
                    )
                }
                .help("Toggle floating translucent desktop widget window")

                Button {
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Label("Sync Widget", systemImage: "arrow.triangle.2.circlepath")
                }
                .help("Reload macOS Notification Center & Desktop WidgetKit timelines")
            }
        }
    }

    // MARK: - Sidebar: Manage Clocks & Format Preferences

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preferences Section
            VStack(alignment: .leading, spacing: 10) {
                Text("DISPLAY SETTINGS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                Toggle(isOn: $store.preferences.use24HourFormat) {
                    Label("24-Hour Time (Military)", systemImage: "clock.badge.checkmark")
                        .font(.system(size: 13, weight: .medium))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Toggle(isOn: $store.preferences.showSeconds) {
                    Label("Show Seconds (:ss)", systemImage: "stopwatch")
                        .font(.system(size: 13, weight: .medium))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Toggle(isOn: $store.preferences.showDayNightIndicator) {
                    Label("Day / Night Icon", systemImage: "sun.and.horizon")
                        .font(.system(size: 13, weight: .medium))
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Toggle(isOn: $store.preferences.showRelativeOffset) {
                    Label("Relative Offset (+HRS)", systemImage: "plusminus.circle")
                        .font(.system(size: 13, weight: .medium))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(14)

            Divider()

            // Reorderable City List Header
            HStack {
                Text("TIMEZONES (\(store.preferences.clocks.count))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showingAddCitySheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderless)
                .help("Add a new timezone")
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            // Reorderable List of Clocks
            List {
                ForEach(Array(store.preferences.clocks.enumerated()), id: \.element.id) { index, item in
                    let calc = ClockCalculation.evaluate(
                        for: item,
                        at: store.currentDate,
                        preferences: store.preferences
                    )

                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                if store.preferences.showDayNightIndicator {
                                    Image(systemName: calc.isDaytime ? "sun.max.fill" : "moon.stars.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(calc.isDaytime ? .orange : .indigo)
                                }
                                Text(item.displayTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .lineLimit(1)
                            }
                            Text(
                                item.hasCustomLabel
                                    ? "\(item.cityName) • \(calc.abbreviation) • \(calc.offsetBadge)"
                                    : "\(calc.abbreviation) • \(calc.offsetBadge)"
                            )
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(calc.formattedTime + (calc.amPmSymbol.map { " \($0)" } ?? ""))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .foregroundStyle(.primary)

                        HStack(spacing: 2) {
                            Button {
                                editingLabelText = item.customLabel ?? ""
                                editingClockItem = item
                            } label: {
                                Image(systemName: "tag")
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.borderless)
                            .help("Set custom label for \(item.cityName)")

                            Button {
                                store.moveClockUp(at: index)
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .buttonStyle(.borderless)
                            .disabled(index == 0)
                            .help("Move Up")

                            Button {
                                store.moveClockDown(at: index)
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .buttonStyle(.borderless)
                            .disabled(index == store.preferences.clocks.count - 1)
                            .help("Move Down")

                            Button(role: .destructive) {
                                store.removeClock(id: item.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.borderless)
                            .help("Remove \(item.cityName)")
                        }
                    }
                    .padding(.vertical, 3)
                }
                .onMove { indices, newOffset in
                    store.moveClocks(from: indices, to: newOffset)
                }
            }
            .listStyle(.sidebar)

            Divider()

            HStack {
                Button("Reset Defaults") {
                    store.resetToDefaults()
                }
                .buttonStyle(.link)
                .font(.system(size: 11))

                Spacer()

                Text("Drag rows to reorder")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
        }
    }

    // MARK: - Main Detail Area: Digital Clocks Grid & Desktop Widget Preview

    private var mainDashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("World Digital Clocks")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("Manage your timezones below. Changes sync automatically with your macOS Desktop & Notification Center Widget.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        showingAddCitySheet = true
                    } label: {
                        Label("Add Timezone", systemImage: "plus")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                // Live Digital Clocks Grid
                if store.preferences.clocks.isEmpty {
                    emptyStateView
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 250, maximum: 360), spacing: 14)
                        ],
                        spacing: 14
                    ) {
                        ForEach(store.preferences.clocks) { clock in
                            DigitalClockCardView(
                                item: clock,
                                date: store.currentDate,
                                preferences: store.preferences,
                                isCompact: false
                            )
                            .contextMenu {
                                Button {
                                    editingLabelText = clock.customLabel ?? ""
                                    editingClockItem = clock
                                } label: {
                                    Label("Edit Custom Label...", systemImage: "tag")
                                }

                                if clock.hasCustomLabel {
                                    Button {
                                        store.updateCustomLabel(for: clock.id, label: nil)
                                    } label: {
                                        Label("Clear Custom Label", systemImage: "xmark.circle")
                                    }
                                }

                                Divider()

                                Button(role: .destructive) {
                                    store.removeClock(id: clock.id)
                                } label: {
                                    Label("Remove \(clock.displayTitle)", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                // Interactive macOS Desktop Widget Preview Section
                widgetPreviewSection
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("No Clocks Configured")
                .font(.headline)
            Text("Add cities from around the world to display on your dashboard and macOS desktop widget.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Add First City") {
                showingAddCitySheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(.quaternary)
        )
    }

    private var widgetPreviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "macwindow.on.rectangle")
                            .foregroundStyle(.blue)
                        Text("macOS Desktop Widget Preview")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    Text("Right-click your macOS Desktop → Edit Widgets → Search \"WorldClock\" to place on your desktop, or click \"Pin Live Widget\" in the toolbar.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Widget Size", selection: $selectedPreviewFamily) {
                    ForEach(WidgetFamilyPreview.allCases) { family in
                        Text(family.rawValue).tag(family)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 340)
            }

            HStack {
                Spacer()
                widgetMockupContainer
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var widgetMockupContainer: some View {
        switch selectedPreviewFamily {
        case .small:
            WidgetMultiClockGridView(
                clocks: Array(store.preferences.clocks.prefix(2)),
                date: store.currentDate,
                preferences: store.preferences,
                columnsCount: 1
            )
            .padding(12)
            .frame(width: 170, height: 170)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            )

        case .medium:
            WidgetMultiClockGridView(
                clocks: Array(store.preferences.clocks.prefix(4)),
                date: store.currentDate,
                preferences: store.preferences,
                columnsCount: 2
            )
            .padding(14)
            .frame(width: 364, height: 170)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            )

        case .large:
            WidgetMultiClockGridView(
                clocks: Array(store.preferences.clocks.prefix(6)),
                date: store.currentDate,
                preferences: store.preferences,
                columnsCount: 2,
                isLargeWidget: true
            )
            .padding(16)
            .frame(width: 364, height: 376)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            )
        }
    }
}

struct EditClockLabelSheet: View {
    let clock: ClockItem
    @Binding var labelText: String
    let onSave: (String?) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.blue)
                Text("Custom Label for \(clock.cityName)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }

            Text("Give this clock a custom name (e.g. \"HQ Office\", \"Engineering\", \"Home\"). Leave blank to show \(clock.cityName).")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            TextField("Custom label (optional)", text: $labelText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onSave(labelText)
                }

            HStack {
                if clock.hasCustomLabel || !labelText.isEmpty {
                    Button("Reset to City Name") {
                        labelText = ""
                        onSave(nil)
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 12))
                }

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    onSave(labelText)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}

