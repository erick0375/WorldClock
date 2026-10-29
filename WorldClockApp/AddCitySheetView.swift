import SwiftUI

struct AddCitySheetView: View {
    @ObservedObject var store: WorldClockStore
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var customLabelText: String = ""
    @State private var showAllTimeZones: Bool = false

    private var filteredEntries: [TimeZoneCatalogEntry] {
        let baseList = showAllTimeZones ? TimeZoneCatalog.allEntries : TimeZoneCatalog.curatedCities
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return baseList }

        let allMatches = TimeZoneCatalog.allEntries.filter { entry in
            entry.cityName.localizedCaseInsensitiveContains(trimmed)
                || entry.countryOrRegion.localizedCaseInsensitiveContains(trimmed)
                || entry.timeZoneIdentifier.localizedCaseInsensitiveContains(trimmed)
                || entry.abbreviation.localizedCaseInsensitiveContains(trimmed)
        }
        return allMatches
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add City or Timezone")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Search major cities or browse all global IANA timezones.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(16)

            // Search Bar
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search city, country, or timezone (e.g. Tokyo, PST, UTC)...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.06))
                )

                Toggle("All IANA Zones", isOn: $showAllTimeZones)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Optional Custom Label Field
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Optional custom label (e.g. \"HQ Office\", \"Mom & Dad\", \"Client\")...", text: $customLabelText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !customLabelText.isEmpty {
                    Button {
                        customLabelText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.04))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider()

            // Results List
            List(filteredEntries) { entry in
                let sampleItem = ClockItem(
                    cityName: entry.cityName,
                    countryOrRegion: entry.countryOrRegion,
                    timeZoneIdentifier: entry.timeZoneIdentifier
                )
                let calc = ClockCalculation.evaluate(
                    for: sampleItem,
                    at: store.currentDate,
                    preferences: store.preferences
                )

                HStack(spacing: 12) {
                    Image(systemName: calc.isDaytime ? "sun.max.fill" : "moon.stars.fill")
                        .foregroundStyle(calc.isDaytime ? .orange : .indigo)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.cityName)
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(entry.countryOrRegion) • \(entry.timeZoneIdentifier) (\(entry.currentOffsetString))")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(calc.formattedTime + (calc.amPmSymbol.map { " \($0)" } ?? ""))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    Button {
                        store.addClock(from: entry, customLabel: customLabelText)
                        customLabelText = ""
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 540, height: 460)
    }
}

