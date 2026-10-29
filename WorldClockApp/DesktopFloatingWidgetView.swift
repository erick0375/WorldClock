import SwiftUI

struct DesktopFloatingWidgetView: View {
    @ObservedObject var store: WorldClockStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "globe.americas.fill")
                        .foregroundStyle(.cyan)
                    Text("WORLD CLOCK WIDGET")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    store.preferences.use24HourFormat.toggle()
                } label: {
                    Text(store.preferences.use24HourFormat ? "24H" : "12H")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.quaternary))
                }
                .buttonStyle(.plain)
                .help("Toggle 12-hour / 24-hour format")
            }
            .padding(.top, 6)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(store.preferences.clocks) { clock in
                        DigitalClockCardView(
                            item: clock,
                            date: store.currentDate,
                            preferences: store.preferences,
                            isCompact: true
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                )
        )
        .padding(4)
    }
}

