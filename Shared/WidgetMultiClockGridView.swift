import SwiftUI

public struct WidgetMultiClockGridView: View {
    public let clocks: [ClockItem]
    public let date: Date
    public let preferences: WorldClockPreferences
    public let columnsCount: Int
    public let isLargeWidget: Bool

    public init(
        clocks: [ClockItem],
        date: Date,
        preferences: WorldClockPreferences,
        columnsCount: Int,
        isLargeWidget: Bool = false
    ) {
        self.clocks = clocks
        self.date = date
        self.preferences = preferences
        self.columnsCount = columnsCount
        self.isLargeWidget = isLargeWidget
    }

    public var body: some View {
        let rows = chunkedClocks
        VStack(spacing: isLargeWidget ? 8 : 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: isLargeWidget ? 8 : 6) {
                    ForEach(row) { clock in
                        WidgetDigitalClockCell(
                            item: clock,
                            date: date,
                            preferences: preferences,
                            isSingleColumn: columnsCount == 1,
                            isLargeWidget: isLargeWidget
                        )
                    }
                    if row.count < columnsCount {
                        ForEach(0..<(columnsCount - row.count), id: \.self) { _ in
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var chunkedClocks: [[ClockItem]] {
        guard columnsCount > 0 else { return [clocks] }
        var result: [[ClockItem]] = []
        var current: [ClockItem] = []
        for clock in clocks {
            current.append(clock)
            if current.count == columnsCount {
                result.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}

public struct WidgetDigitalClockCell: View {
    public let item: ClockItem
    public let date: Date
    public let preferences: WorldClockPreferences
    public let isSingleColumn: Bool
    public var isLargeWidget: Bool = false

    public var body: some View {
        let calc = ClockCalculation.evaluate(for: item, at: date, preferences: preferences)

        VStack(alignment: .leading, spacing: 0) {
            // Top Row: City / Custom Label + Offset Badge
            HStack(alignment: .top, spacing: 4) {
                if preferences.showDayNightIndicator {
                    Image(systemName: calc.isDaytime ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: isLargeWidget ? 12 : 10, weight: .semibold))
                        .foregroundStyle(calc.isDaytime ? Color.orange : Color.indigo)
                        .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(item.displayTitle)
                        .font(.system(size: isLargeWidget ? 13.5 : 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if item.hasCustomLabel {
                        Text(item.cityName)
                            .font(.system(size: isLargeWidget ? 9.5 : 8.5, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 2)

                if preferences.showRelativeOffset {
                    Text(calc.offsetBadge)
                        .font(.system(size: isLargeWidget ? 9.5 : 8.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, isLargeWidget ? 5 : 4)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(calc.isDaytime ? Color.orange.opacity(0.18) : Color.indigo.opacity(0.22))
                        )
                        .foregroundStyle(calc.isDaytime ? Color.orange : Color.indigo)
                }
            }

            Spacer(minLength: 0)

            // Center: Large Digital Time filling the middle space
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(calc.formattedTime)
                    .font(.system(size: isLargeWidget ? 38 : (isSingleColumn ? 28 : 26), weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                if preferences.showSeconds {
                    Text(":\(calc.secondsString)")
                        .font(.system(size: isLargeWidget ? 16 : 12, weight: .semibold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let amPm = calc.amPmSymbol {
                    Text(amPm)
                        .font(.system(size: isLargeWidget ? 12 : 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // Bottom Row: Today / Tomorrow / Yesterday + Date & Timezone below the time
            HStack(spacing: 4) {
                if preferences.showRelativeOffset {
                    Text(calc.dayLabel)
                        .font(.system(size: isLargeWidget ? 11 : 9.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if isLargeWidget {
                    Text("• \(calc.dateString)")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(calc.abbreviation)
                    .font(.system(size: isLargeWidget ? 10 : 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, isLargeWidget ? 11 : 9)
        .padding(.vertical, isLargeWidget ? 9 : 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: isLargeWidget ? 14 : 12, style: .continuous)
                .fill(calc.isDaytime ? Color.orange.opacity(0.09) : Color.indigo.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: isLargeWidget ? 14 : 12, style: .continuous)
                        .strokeBorder(
                            calc.isDaytime ? Color.orange.opacity(0.2) : Color.indigo.opacity(0.22),
                            lineWidth: 0.8
                        )
                )
        )
    }
}
