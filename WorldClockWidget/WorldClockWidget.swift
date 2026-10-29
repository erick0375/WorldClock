import WidgetKit
import SwiftUI

struct WorldClockTimelineEntry: TimelineEntry {
    let date: Date
    let preferences: WorldClockPreferences
}

struct WorldClockTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorldClockTimelineEntry {
        WorldClockTimelineEntry(date: Date(), preferences: WorldClockPreferences())
    }

    func getSnapshot(in context: Context, completion: @escaping (WorldClockTimelineEntry) -> Void) {
        let prefs = WorldClockStorage.shared.load()
        completion(WorldClockTimelineEntry(date: Date(), preferences: prefs))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorldClockTimelineEntry>) -> Void) {
        let prefs = WorldClockStorage.shared.load()
        let now = Date()
        let calendar = Calendar.current

        // Generate entries on each minute boundary for the next 60 minutes
        var entries: [WorldClockTimelineEntry] = []
        let currentSecond = calendar.component(.second, from: now)
        let startOfNextMinute = now.addingTimeInterval(TimeInterval(60 - currentSecond))

        entries.append(WorldClockTimelineEntry(date: now, preferences: prefs))

        for minuteOffset in 0..<60 {
            let entryDate = startOfNextMinute.addingTimeInterval(TimeInterval(minuteOffset * 60))
            entries.append(WorldClockTimelineEntry(date: entryDate, preferences: prefs))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WorldClockWidgetEntryView: View {
    var entry: WorldClockTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let clocks = entry.preferences.clocks

        switch family {
        case .systemSmall:
            WidgetMultiClockGridView(
                clocks: Array(clocks.prefix(2)),
                date: entry.date,
                preferences: entry.preferences,
                columnsCount: 1
            )
            .containerBackground(.fill.tertiary, for: .widget)

        case .systemMedium:
            WidgetMultiClockGridView(
                clocks: Array(clocks.prefix(4)),
                date: entry.date,
                preferences: entry.preferences,
                columnsCount: 2
            )
            .containerBackground(.fill.tertiary, for: .widget)

        case .systemLarge:
            WidgetMultiClockGridView(
                clocks: Array(clocks.prefix(6)),
                date: entry.date,
                preferences: entry.preferences,
                columnsCount: 2,
                isLargeWidget: true
            )
            .containerBackground(.fill.tertiary, for: .widget)

        default:
            WidgetMultiClockGridView(
                clocks: Array(clocks.prefix(4)),
                date: entry.date,
                preferences: entry.preferences,
                columnsCount: 2
            )
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

@main
struct WorldClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorldClockDesktopWidget()
    }
}

struct WorldClockDesktopWidget: Widget {
    let kind: String = "WorldClockDesktopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorldClockTimelineProvider()) { entry in
            WorldClockWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("World Digital Clocks")
        .description("Display multiple digital clocks across global timezones on your macOS Desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

