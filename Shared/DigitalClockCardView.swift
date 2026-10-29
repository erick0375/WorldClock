import SwiftUI

public struct DigitalClockCardView: View {
    public let item: ClockItem
    public let date: Date
    public let preferences: WorldClockPreferences
    public var isCompact: Bool = false

    public init(
        item: ClockItem,
        date: Date,
        preferences: WorldClockPreferences,
        isCompact: Bool = false
    ) {
        self.item = item
        self.date = date
        self.preferences = preferences
        self.isCompact = isCompact
    }

    public var body: some View {
        let calc = ClockCalculation.evaluate(for: item, at: date, preferences: preferences)

        VStack(alignment: .leading, spacing: 0) {
            // Top Header: City + Day/Night Indicator + Offset Badge
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        if preferences.showDayNightIndicator {
                            Image(systemName: calc.isDaytime ? "sun.max.fill" : "moon.stars.fill")
                                .font(.system(size: isCompact ? 11 : 13, weight: .semibold))
                                .foregroundStyle(calc.isDaytime ? Color.orange : Color.indigo)
                        }

                        Text(item.displayTitle)
                            .font(.system(size: isCompact ? 14 : 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    Text(
                        item.hasCustomLabel
                            ? "\(item.cityName), \(item.countryOrRegion) • \(calc.abbreviation)"
                            : "\(item.countryOrRegion) • \(calc.abbreviation)"
                    )
                        .font(.system(size: isCompact ? 10 : 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                if preferences.showRelativeOffset {
                    Text(calc.offsetBadge)
                        .font(.system(size: isCompact ? 9.5 : 10.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule()
                                .fill(calc.isDaytime ? Color.orange.opacity(0.16) : Color.indigo.opacity(0.18))
                        )
                        .foregroundStyle(calc.isDaytime ? Color.orange : Color.indigo)
                }
            }

            Spacer(minLength: 4)

            // Center: Large Digital Time Display
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(calc.formattedTime)
                    .font(.system(size: isCompact ? 34 : 44, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)

                if preferences.showSeconds {
                    Text(":\(calc.secondsString)")
                        .font(.system(size: isCompact ? 16 : 20, weight: .semibold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                if let amPm = calc.amPmSymbol {
                    Text(amPm)
                        .font(.system(size: isCompact ? 12 : 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)
                }

                Spacer(minLength: 0)
            }

            Spacer(minLength: 4)

            // Bottom Row: Today/Tomorrow/Yesterday below the time
            HStack {
                if preferences.showRelativeOffset {
                    Text("\(calc.dayLabel) • \(calc.dateString)")
                        .font(.system(size: isCompact ? 10.5 : 11.5, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text(calc.dateString)
                        .font(.system(size: isCompact ? 10.5 : 11.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !isCompact {
                    DayProgressBar(hourOfDay: calc.hourOfDay, isDaytime: calc.isDaytime)
                        .frame(width: 72, height: 5)
                }
            }
        }
        .padding(isCompact ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 12 : 16, style: .continuous)
                .fill(cardBackgroundGradient(isDaytime: calc.isDaytime))
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 12 : 16, style: .continuous)
                        .strokeBorder(
                            calc.isDaytime
                                ? Color.orange.opacity(0.22)
                                : Color.indigo.opacity(0.25),
                            lineWidth: 1
                        )
                )
        )
    }

    private func cardBackgroundGradient(isDaytime: Bool) -> LinearGradient {
        if isDaytime {
            return LinearGradient(
                colors: [
                    Color.orange.opacity(0.10),
                    Color.yellow.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.indigo.opacity(0.14),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

public struct DayProgressBar: View {
    public let hourOfDay: Int
    public let isDaytime: Bool

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                Capsule()
                    .fill(isDaytime ? Color.orange.opacity(0.75) : Color.indigo.opacity(0.75))
                    .frame(width: max(6, geo.size.width * CGFloat(hourOfDay + 1) / 24.0))
            }
        }
    }
}

