# World Clock for macOS

A native macOS application and **WidgetKit Desktop & Notification Center Widget** for displaying digital clocks across multiple global timezones.

## Features

- **Native macOS Desktop Widget (`WidgetKit`)**:
  - Supports **Small** (2 clocks), **Medium** (4 clocks), and **Large** (6 clocks) widget sizes on macOS Sonoma / Sequoia and later.
- **Pin-to-Desktop Live Floating Widget**:
  - Toggle an always-available translucent (`ultraThinMaterial`) floating desktop widget panel (`Cmd+Shift+P`) with real-time ticking seconds across all Spaces.
- **Custom Clock Labels**:
  - Assign custom labels to any timezone (e.g., `"HQ Office"`, `"Engineering"`, `"Family"`) while preserving the city and timezone subtitle.
- **Rich Digital Clock Display**:
  - Toggle between **12-hour (AM/PM)** and **24-hour** formats (`Cmd+T`).
  - Optional `:ss` seconds display (`Cmd+Shift+S`).
  - Automatic **Day / Night** indicator (`☀️` / `🌙`) with adaptive warm-day and indigo-night card styling.
  - Relative hour offset badges (`+8HRS`, `-4HRS`, `LOCAL`) and relative day indicators (`Today`, `Tomorrow`, `Yesterday`).
- **Full IANA Timezone Catalog**:
  - Curated list of major global cities plus instant search across all global IANA timezones, countries, and abbreviations.
  - Drag-and-drop or one-click reordering in the sidebar.

## Building & Installing

### Option 1: Build Script (No Paid Apple Developer Account Required)

Run `./build_app.sh` from the repository root:

```bash
chmod +x build_app.sh
./build_app.sh
```

The script automatically:
1. Generates `AppIcon.icns` at all macOS Retina resolutions (`16x16` through `1024x1024`) using `generate_icon.swift`.
2. Compiles `WorldClockWidgetExtension.appex` and `WorldClock.app` using the Xcode Swift toolchain.
3. Signs both targets with App Sandbox entitlements and installs `WorldClock.app` into `/Applications/WorldClock.app` so macOS `pluginkit` and `chronod` register the desktop widget immediately.

### Option 2: Xcode

Open `WorldClock.xcodeproj` in Xcode 15+ and build the `WorldClock` scheme for **My Mac**.

## Adding the Desktop Widget

1. Right-click anywhere on your macOS Desktop and choose **Edit Widgets...**
2. Search for **World Clock** in the widget gallery.
3. Drag the **Small**, **Medium**, or **Large** digital clock widget onto your desktop.

## Project Structure

- `Shared/`
  - `WorldClockModels.swift` — Data models, timezone offset & day calculation engine, shared preference storage, and IANA timezone catalog.
  - `DigitalClockCardView.swift` — Main digital clock card component.
  - `WidgetMultiClockGridView.swift` — Multi-column responsive widget grid for Small, Medium, and Large widgets.
- `WorldClockApp/`
  - `WorldClockApp.swift` — Main app entry point, menu bar commands, and About panel.
  - `WorldClockStore.swift` — State management, timer, and floating desktop widget panel controller.
  - `ContentView.swift` — Split-view dashboard, display settings, reorderable city list, and live widget preview.
  - `AddCitySheetView.swift` — Searchable timezone picker with custom label support.
  - `DesktopFloatingWidgetView.swift` — Translucent floating desktop widget view.
- `WorldClockWidget/`
  - `WorldClockWidget.swift` — `WidgetKit` timeline provider and widget configuration.
- `generate_icon.swift` — CoreGraphics vector icon generator (`AppIcon.icns`).

## License

Created by **Eric K** and released under the [MIT License](LICENSE).

