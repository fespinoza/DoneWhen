import SwiftUI
import SwiftData

extension Event {
    var repetitionStateColor: Color {
        if let repeatInterval, let lastOccurrenceDate = lastOccurrence?.date {
            let daysSinceLastOccurrence = Calendar.current.dateComponents(
                [.day, .month, .year],
                from: lastOccurrenceDate,
                to: Date()
            ).day

            if let daysSinceLastOccurrence {
                let weeksSinceLastOccurrence = daysSinceLastOccurrence / 7

                let color = if weeksSinceLastOccurrence == 0 {
                    Color.green
                } else if weeksSinceLastOccurrence < repeatInterval {
                    Color.yellow
                } else {
                    Color.red
                }

                return color
            } else {
                return Color.orange
            }
        } else {
            return Color.primary
        }
    }

    var lastOccurrenceMessage: String? {
        guard let daysSinceLastOccurrence else { return nil }

        return if daysSinceLastOccurrence == 0 {
            "Today"
        } else {
            "\(daysSinceLastOccurrence) days ago"
        }
    }

    var daysSinceLastOccurrence: Int? {
        guard let lastOccurrence else { return nil }

        return Calendar.current.dateComponents(
            [.day, .month, .year],
            from: lastOccurrence.date,
            to: Date()
        ).day
    }

    var weeksSinceLastOccurrence: Int? {
        guard let lastOccurrence else { return nil }

        return Calendar.current.dateComponents(
            [.weekOfYear],
            from: lastOccurrence.date,
            to: Date()
        ).weekOfYear
    }
}


public struct EventByNameListView: View {
    @State private var eventToEdit: Event?
    @State private var filterText: String = ""

    @State private var ascending: Bool = false
    @State private var sortCase: SortCase = .byLastOccurrence

    enum SortCase {
        case alphabetically
        case byLastOccurrence
    }

    struct Content: View {
        @Binding private var eventToEdit: Event?
        @Query private var events: [Event]
        @Environment(\.modelContext) var context

        init(ascending: Bool, sortCase: SortCase, filterText: String, eventToEdit: Binding<Event?>) {
            let direction: SortOrder = ascending ? .forward : .reverse

            let sort: [SortDescriptor<Event>] = switch sortCase {
            case .alphabetically:
                [SortDescriptor(\.name, order: direction)]
            case .byLastOccurrence:
                [
                    SortDescriptor(\.lastOccurrenceDate, order: direction),
                    SortDescriptor(\.name, order: .forward),
                ]
            }

            _eventToEdit = eventToEdit
            _events = Query(
                filter: #Predicate<Event> {
                    if filterText.isEmpty {
                        true
                    } else {
                        $0.name.localizedStandardContains(filterText)
                    }
                },
                sort: sort,
                animation: .default
            )
        }

        var body: some View {
            List {
                ForEach(events) { event in
                    NavigationLink {
                        EventDetailView(event: event)
                    } label: {
                        rowContent(for: event)
                    }
                    .swipeActions { actions(for: event) }
                    .contextMenu { actions(for: event) }
                }
            }
        }

        func rowContent(for event: Event) -> some View {
            HStack {
                eventCountBadge(for: event)

                VStack(alignment: .leading) {
                    Text(event.name)
                        .font(.headline)

                    if let daysSinceLastOccurrence = event.daysSinceLastOccurrence() {
                        Group {
                            if daysSinceLastOccurrence == 0 {
                                Text("Today")
                            } else {
                                Text("^[\(daysSinceLastOccurrence) day](inflect: true) ago")
                            }
                        }
                        .italic()
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .foregroundStyle(event.repetitionStateColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        @ViewBuilder func actions(for event: Event) -> some View {
            Button {
                eventToEdit = event
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(
                role: .destructive,
                action: { delete(event) },
                label: { Label("Delete", systemImage: "trash") }
            )
        }

        func delete(_ event: Event) {
            do {
                context.delete(event)
                try context.save()
            } catch {
                print(":(")
            }
        }

        func eventCountBadge(for event: Event) -> some View {
            Text((event.occurrences?.count ?? 0).formatted())
                .shadow(radius: 2)
                .bold()
                .padding(2)
                .padding(.horizontal, 12)
                .foregroundStyle(Color.white)
                .background(
                    Circle()
                        .foregroundStyle(Color.accentColor)
                )
        }
    }

    public var body: some View {
        Content(
            ascending: ascending,
            sortCase: sortCase,
            filterText: filterText,
            eventToEdit: $eventToEdit
        )
        .searchable(text: $filterText, prompt: Text("Find events"))
        .sheet(item: $eventToEdit, content: { event in
            NavigationStack {
                EditEventFormView(event: event)
            }
        })
        .listStyle(.plain)
        .navigationTitle("Tracked Events")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker(selection: $sortCase) {
                        Text("Alphabetically").tag(SortCase.alphabetically)
                        Text("By Last Occurrence").tag(SortCase.byLastOccurrence)
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                    .pickerStyle(.inline)

                    Divider()

                    Picker(selection: $ascending) {
                        Text("Ascending").tag(true)
                        Text("Descending").tag(false)
                    } label: {
                        Label("Direction", systemImage: "arrow.up.arrow.down")
                    }
                    .pickerStyle(.inline)
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PreviewDataContainer {
            EventByNameListView()
        }
    }
}
