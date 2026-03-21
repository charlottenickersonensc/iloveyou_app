import SwiftUI

// MARK: - Screen 6: Activity → Saved Events
struct ActivitySavedEventsView: View {
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appBlue)
                }
                Text("Saved Events").font(.custom("Jost-ExtraBold", size: 18))
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            eventSection("Upcoming", events: Array(sampleEvents.prefix(2)))
            eventSection("Past",     events: Array(sampleEvents.dropFirst(2)))
        }
        .background(Color.white)
    }

    private func eventSection(_ header: String, events: [EventItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header)
                .font(.custom("Jost-ExtraBold", size: 16)).foregroundColor(.black)
                .padding(.horizontal, 16)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(events) { e in
                    EventCard(event: e)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Event Card (used in SavedEvents)
struct EventCard: View {
    let event: EventItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray5)).frame(height: 70)
                .overlay(Image(systemName: "calendar").foregroundColor(.gray).font(.system(size: 24)))
            Text(event.title).font(.custom("Jost-ExtraBold", size: 13))
            Label(event.date, systemImage: "calendar")
                .font(.custom("Jost-Medium", size: 11)).foregroundColor(.gray)
            Label(event.org.replacingOccurrences(of: "\n", with: " "),
                  systemImage: "person.3.fill")
                .font(.custom("Jost-Medium", size: 11)).foregroundColor(.gray)
        }
        .padding(10)
        .background(Color.appBluePale).cornerRadius(12)
    }
}
