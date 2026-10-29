import Foundation
import WidgetKit

public struct ClockItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var cityName: String
    public var countryOrRegion: String
    public var timeZoneIdentifier: String
    public var customLabel: String?

    public init(
        id: UUID = UUID(),
        cityName: String,
        countryOrRegion: String,
        timeZoneIdentifier: String,
        customLabel: String? = nil
    ) {
        self.id = id
        self.cityName = cityName
        self.countryOrRegion = countryOrRegion
        self.timeZoneIdentifier = timeZoneIdentifier
        let trimmed = customLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.customLabel = (trimmed?.isEmpty == false) ? trimmed : nil
    }

    public var displayTitle: String {
        if let label = customLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
            return label
        }
        return cityName
    }

    public var hasCustomLabel: Bool {
        if let label = customLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
            return true
        }
        return false
    }

    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}

public struct WorldClockPreferences: Codable, Equatable {
    public var clocks: [ClockItem]
    public var use24HourFormat: Bool
    public var showSeconds: Bool
    public var showRelativeOffset: Bool
    public var showDayNightIndicator: Bool

    public init(
        clocks: [ClockItem] = WorldClockPreferences.defaultClocks,
        use24HourFormat: Bool = false,
        showSeconds: Bool = true,
        showRelativeOffset: Bool = true,
        showDayNightIndicator: Bool = true
    ) {
        self.clocks = clocks
        self.use24HourFormat = use24HourFormat
        self.showSeconds = showSeconds
        self.showRelativeOffset = showRelativeOffset
        self.showDayNightIndicator = showDayNightIndicator
    }

    public static let defaultClocks: [ClockItem] = [
        ClockItem(cityName: "San Francisco", countryOrRegion: "United States", timeZoneIdentifier: "America/Los_Angeles"),
        ClockItem(cityName: "New York", countryOrRegion: "United States", timeZoneIdentifier: "America/New_York"),
        ClockItem(cityName: "London", countryOrRegion: "United Kingdom", timeZoneIdentifier: "Europe/London"),
        ClockItem(cityName: "Tokyo", countryOrRegion: "Japan", timeZoneIdentifier: "Asia/Tokyo"),
        ClockItem(cityName: "Sydney", countryOrRegion: "Australia", timeZoneIdentifier: "Australia/Sydney"),
    ]
}

// MARK: - Time Calculations & Formatting

public struct ClockCalculation {
    public let formattedTime: String
    public let amPmSymbol: String?
    public let secondsString: String
    public let abbreviation: String
    public let offsetBadge: String
    public let dayLabel: String
    public let dateString: String
    public let isDaytime: Bool
    public let hourOfDay: Int

    public static func evaluate(
        for item: ClockItem,
        at date: Date,
        preferences: WorldClockPreferences,
        referenceTimeZone: TimeZone = .current
    ) -> ClockCalculation {
        let tz = item.timeZone
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz

        let hour = calendar.component(.hour, from: date)
        let second = calendar.component(.second, from: date)
        let isDaytime = (6..<18).contains(hour)

        // Format main digital time (HH:mm or h:mm)
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = tz
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        if preferences.use24HourFormat {
            timeFormatter.dateFormat = "HH:mm"
        } else {
            timeFormatter.dateFormat = "h:mm"
        }
        let formattedTime = timeFormatter.string(from: date)

        let amPmSymbol: String?
        if preferences.use24HourFormat {
            amPmSymbol = nil
        } else {
            let amPmFormatter = DateFormatter()
            amPmFormatter.timeZone = tz
            amPmFormatter.locale = Locale(identifier: "en_US_POSIX")
            amPmFormatter.dateFormat = "a"
            amPmSymbol = amPmFormatter.string(from: date)
        }

        let secondsString = String(format: "%02d", second)
        let abbreviation = tz.abbreviation(for: date) ?? "UTC"

        // Short date e.g. "Thu, Oct 29"
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = tz
        dateFormatter.dateFormat = "EEE, MMM d"
        let dateString = dateFormatter.string(from: date)

        // Day difference (Today / Tomorrow / Yesterday)
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.timeZone = referenceTimeZone
        let localDay = localCalendar.component(.day, from: date)
        let localMonth = localCalendar.component(.month, from: date)
        let localYear = localCalendar.component(.year, from: date)

        let targetDay = calendar.component(.day, from: date)
        let targetMonth = calendar.component(.month, from: date)
        let targetYear = calendar.component(.year, from: date)

        let dayLabel: String
        if (targetYear, targetMonth, targetDay) == (localYear, localMonth, localDay) {
            dayLabel = "Today"
        } else if (targetYear, targetMonth, targetDay) > (localYear, localMonth, localDay) {
            dayLabel = "Tomorrow"
        } else {
            dayLabel = "Yesterday"
        }

        // Offset relative to local timezone
        let targetOffsetSeconds = tz.secondsFromGMT(for: date)
        let localOffsetSeconds = referenceTimeZone.secondsFromGMT(for: date)
        let diffSeconds = targetOffsetSeconds - localOffsetSeconds

        let offsetBadge: String
        if diffSeconds == 0 {
            offsetBadge = "LOCAL"
        } else {
            let sign = diffSeconds > 0 ? "+" : "-"
            let absSeconds = abs(diffSeconds)
            let hours = absSeconds / 3600
            let minutes = (absSeconds % 3600) / 60
            if minutes == 0 {
                offsetBadge = "\(sign)\(hours)HRS"
            } else {
                offsetBadge = String(format: "%@%d:%02d", sign, hours, minutes)
            }
        }

        return ClockCalculation(
            formattedTime: formattedTime,
            amPmSymbol: amPmSymbol,
            secondsString: secondsString,
            abbreviation: abbreviation,
            offsetBadge: offsetBadge,
            dayLabel: dayLabel,
            dateString: dateString,
            isDaytime: isDaytime,
            hourOfDay: hour
        )
    }
}

// MARK: - Shared Storage (UserDefaults + App Support JSON for WidgetKit sync)

public final class WorldClockStorage {
    public static let shared = WorldClockStorage()

    public static let sharedSuiteName = "com.worldclock.macos"
    private let preferencesKey = "WorldClockPreferences_v1"

    private init() {}

    public func load() -> WorldClockPreferences {
        // 1. Try shared preference suite (com.worldclock.macos) accessible via temporary-exception entitlement
        if let sharedDefaults = UserDefaults(suiteName: Self.sharedSuiteName),
           let data = sharedDefaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(WorldClockPreferences.self, from: data) {
            return decoded
        }

        // 2. Try standard UserDefaults
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(WorldClockPreferences.self, from: data) {
            return decoded
        }

        return WorldClockPreferences()
    }

    public func save(_ preferences: WorldClockPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }

        UserDefaults.standard.set(data, forKey: preferencesKey)
        if let sharedDefaults = UserDefaults(suiteName: Self.sharedSuiteName) {
            sharedDefaults.set(data, forKey: preferencesKey)
            sharedDefaults.synchronize()
        }
        UserDefaults.standard.synchronize()

        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Catalog of Popular Cities & All TimeZones

public struct TimeZoneCatalogEntry: Identifiable, Hashable {
    public var id: String { "\(cityName)|\(timeZoneIdentifier)" }
    public let cityName: String
    public let countryOrRegion: String
    public let timeZoneIdentifier: String

    public var currentOffsetString: String {
        guard let tz = TimeZone(identifier: timeZoneIdentifier) else { return "UTC" }
        let seconds = tz.secondsFromGMT()
        let sign = seconds >= 0 ? "+" : "-"
        let absSec = abs(seconds)
        let hrs = absSec / 3600
        let mins = (absSec % 3600) / 60
        if mins == 0 {
            return "UTC\(sign)\(hrs)"
        }
        return String(format: "UTC%@%d:%02d", sign, hrs, mins)
    }

    public var abbreviation: String {
        TimeZone(identifier: timeZoneIdentifier)?.abbreviation() ?? "UTC"
    }
}

public enum TimeZoneCatalog {
    public static let curatedCities: [TimeZoneCatalogEntry] = [
        TimeZoneCatalogEntry(cityName: "San Francisco", countryOrRegion: "United States", timeZoneIdentifier: "America/Los_Angeles"),
        TimeZoneCatalogEntry(cityName: "Los Angeles", countryOrRegion: "United States", timeZoneIdentifier: "America/Los_Angeles"),
        TimeZoneCatalogEntry(cityName: "Seattle", countryOrRegion: "United States", timeZoneIdentifier: "America/Los_Angeles"),
        TimeZoneCatalogEntry(cityName: "Vancouver", countryOrRegion: "Canada", timeZoneIdentifier: "America/Vancouver"),
        TimeZoneCatalogEntry(cityName: "Denver", countryOrRegion: "United States", timeZoneIdentifier: "America/Denver"),
        TimeZoneCatalogEntry(cityName: "Chicago", countryOrRegion: "United States", timeZoneIdentifier: "America/Chicago"),
        TimeZoneCatalogEntry(cityName: "Mexico City", countryOrRegion: "Mexico", timeZoneIdentifier: "America/Mexico_City"),
        TimeZoneCatalogEntry(cityName: "New York", countryOrRegion: "United States", timeZoneIdentifier: "America/New_York"),
        TimeZoneCatalogEntry(cityName: "Toronto", countryOrRegion: "Canada", timeZoneIdentifier: "America/Toronto"),
        TimeZoneCatalogEntry(cityName: "Miami", countryOrRegion: "United States", timeZoneIdentifier: "America/New_York"),
        TimeZoneCatalogEntry(cityName: "São Paulo", countryOrRegion: "Brazil", timeZoneIdentifier: "America/Sao_Paulo"),
        TimeZoneCatalogEntry(cityName: "Buenos Aires", countryOrRegion: "Argentina", timeZoneIdentifier: "America/Argentina/Buenos_Aires"),
        TimeZoneCatalogEntry(cityName: "Honolulu", countryOrRegion: "United States", timeZoneIdentifier: "Pacific/Honolulu"),
        TimeZoneCatalogEntry(cityName: "Anchorage", countryOrRegion: "United States", timeZoneIdentifier: "America/Anchorage"),
        TimeZoneCatalogEntry(cityName: "UTC / GMT", countryOrRegion: "Universal Time", timeZoneIdentifier: "GMT"),
        TimeZoneCatalogEntry(cityName: "Reykjavik", countryOrRegion: "Iceland", timeZoneIdentifier: "Atlantic/Reykjavik"),
        TimeZoneCatalogEntry(cityName: "London", countryOrRegion: "United Kingdom", timeZoneIdentifier: "Europe/London"),
        TimeZoneCatalogEntry(cityName: "Dublin", countryOrRegion: "Ireland", timeZoneIdentifier: "Europe/Dublin"),
        TimeZoneCatalogEntry(cityName: "Lisbon", countryOrRegion: "Portugal", timeZoneIdentifier: "Europe/Lisbon"),
        TimeZoneCatalogEntry(cityName: "Paris", countryOrRegion: "France", timeZoneIdentifier: "Europe/Paris"),
        TimeZoneCatalogEntry(cityName: "Berlin", countryOrRegion: "Germany", timeZoneIdentifier: "Europe/Berlin"),
        TimeZoneCatalogEntry(cityName: "Amsterdam", countryOrRegion: "Netherlands", timeZoneIdentifier: "Europe/Amsterdam"),
        TimeZoneCatalogEntry(cityName: "Zurich", countryOrRegion: "Switzerland", timeZoneIdentifier: "Europe/Zurich"),
        TimeZoneCatalogEntry(cityName: "Madrid", countryOrRegion: "Spain", timeZoneIdentifier: "Europe/Madrid"),
        TimeZoneCatalogEntry(cityName: "Rome", countryOrRegion: "Italy", timeZoneIdentifier: "Europe/Rome"),
        TimeZoneCatalogEntry(cityName: "Stockholm", countryOrRegion: "Sweden", timeZoneIdentifier: "Europe/Stockholm"),
        TimeZoneCatalogEntry(cityName: "Warsaw", countryOrRegion: "Poland", timeZoneIdentifier: "Europe/Warsaw"),
        TimeZoneCatalogEntry(cityName: "Athens", countryOrRegion: "Greece", timeZoneIdentifier: "Europe/Athens"),
        TimeZoneCatalogEntry(cityName: "Cairo", countryOrRegion: "Egypt", timeZoneIdentifier: "Africa/Cairo"),
        TimeZoneCatalogEntry(cityName: "Johannesburg", countryOrRegion: "South Africa", timeZoneIdentifier: "Africa/Johannesburg"),
        TimeZoneCatalogEntry(cityName: "Istanbul", countryOrRegion: "Turkey", timeZoneIdentifier: "Europe/Istanbul"),
        TimeZoneCatalogEntry(cityName: "Jerusalem", countryOrRegion: "Israel", timeZoneIdentifier: "Asia/Jerusalem"),
        TimeZoneCatalogEntry(cityName: "Riyadh", countryOrRegion: "Saudi Arabia", timeZoneIdentifier: "Asia/Riyadh"),
        TimeZoneCatalogEntry(cityName: "Moscow", countryOrRegion: "Russia", timeZoneIdentifier: "Europe/Moscow"),
        TimeZoneCatalogEntry(cityName: "Dubai", countryOrRegion: "United Arab Emirates", timeZoneIdentifier: "Asia/Dubai"),
        TimeZoneCatalogEntry(cityName: "Mumbai", countryOrRegion: "India", timeZoneIdentifier: "Asia/Kolkata"),
        TimeZoneCatalogEntry(cityName: "Bengaluru", countryOrRegion: "India", timeZoneIdentifier: "Asia/Kolkata"),
        TimeZoneCatalogEntry(cityName: "New Delhi", countryOrRegion: "India", timeZoneIdentifier: "Asia/Kolkata"),
        TimeZoneCatalogEntry(cityName: "Kathmandu", countryOrRegion: "Nepal", timeZoneIdentifier: "Asia/Kathmandu"),
        TimeZoneCatalogEntry(cityName: "Dhaka", countryOrRegion: "Bangladesh", timeZoneIdentifier: "Asia/Dhaka"),
        TimeZoneCatalogEntry(cityName: "Bangkok", countryOrRegion: "Thailand", timeZoneIdentifier: "Asia/Bangkok"),
        TimeZoneCatalogEntry(cityName: "Jakarta", countryOrRegion: "Indonesia", timeZoneIdentifier: "Asia/Jakarta"),
        TimeZoneCatalogEntry(cityName: "Ho Chi Minh City", countryOrRegion: "Vietnam", timeZoneIdentifier: "Asia/Ho_Chi_Minh"),
        TimeZoneCatalogEntry(cityName: "Singapore", countryOrRegion: "Singapore", timeZoneIdentifier: "Asia/Singapore"),
        TimeZoneCatalogEntry(cityName: "Kuala Lumpur", countryOrRegion: "Malaysia", timeZoneIdentifier: "Asia/Kuala_Lumpur"),
        TimeZoneCatalogEntry(cityName: "Hong Kong", countryOrRegion: "China", timeZoneIdentifier: "Asia/Hong_Kong"),
        TimeZoneCatalogEntry(cityName: "Taipei", countryOrRegion: "Taiwan", timeZoneIdentifier: "Asia/Taipei"),
        TimeZoneCatalogEntry(cityName: "Shanghai", countryOrRegion: "China", timeZoneIdentifier: "Asia/Shanghai"),
        TimeZoneCatalogEntry(cityName: "Beijing", countryOrRegion: "China", timeZoneIdentifier: "Asia/Shanghai"),
        TimeZoneCatalogEntry(cityName: "Manila", countryOrRegion: "Philippines", timeZoneIdentifier: "Asia/Manila"),
        TimeZoneCatalogEntry(cityName: "Perth", countryOrRegion: "Australia", timeZoneIdentifier: "Australia/Perth"),
        TimeZoneCatalogEntry(cityName: "Seoul", countryOrRegion: "South Korea", timeZoneIdentifier: "Asia/Seoul"),
        TimeZoneCatalogEntry(cityName: "Tokyo", countryOrRegion: "Japan", timeZoneIdentifier: "Asia/Tokyo"),
        TimeZoneCatalogEntry(cityName: "Adelaide", countryOrRegion: "Australia", timeZoneIdentifier: "Australia/Adelaide"),
        TimeZoneCatalogEntry(cityName: "Sydney", countryOrRegion: "Australia", timeZoneIdentifier: "Australia/Sydney"),
        TimeZoneCatalogEntry(cityName: "Melbourne", countryOrRegion: "Australia", timeZoneIdentifier: "Australia/Melbourne"),
        TimeZoneCatalogEntry(cityName: "Brisbane", countryOrRegion: "Australia", timeZoneIdentifier: "Australia/Brisbane"),
        TimeZoneCatalogEntry(cityName: "Auckland", countryOrRegion: "New Zealand", timeZoneIdentifier: "Pacific/Auckland"),
    ]

    public static let allEntries: [TimeZoneCatalogEntry] = {
        var list = curatedCities
        let existingIDs = Set(list.map { $0.timeZoneIdentifier })

        for identifier in TimeZone.knownTimeZoneIdentifiers where !existingIDs.contains(identifier) {
            let parts = identifier.split(separator: "/").map(String.init)
            guard parts.count >= 2 else { continue }
            let region = parts[0].replacingOccurrences(of: "_", with: " ")
            let city = parts.last!.replacingOccurrences(of: "_", with: " ")
            list.append(
                TimeZoneCatalogEntry(
                    cityName: city,
                    countryOrRegion: region,
                    timeZoneIdentifier: identifier
                )
            )
        }
        return list.sorted { $0.cityName.localizedCaseInsensitiveCompare($1.cityName) == .orderedAscending }
    }()
}

