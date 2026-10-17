import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet: Bool = false
    @State private var showingEditSheet: Bool = false

    let event: Event

//    @Query(sort: \Occurrence.date, order: .reverse) private var occurrences: [Occurrence]

    var occurrences: [Occurrence] { event.occurrences ?? [] }

    enum Row: Hashable, Identifiable {
        case occurrence(Occurrence)
        case interval(index: Int, interval: Int)

        var id: String {
            switch self {
            case .occurrence(let occurrence):
                occurrence.id.hashValue.description
            case .interval(let index, _):
                index.formatted()
            }
        }
    }

    var occurrencesAndIntervals: [Row] {
        var results: [Row] = []

        guard occurrences.count > 0 else {
            return []
        }

        let sortedOccurrences = occurrences.sorted(by: { $0.date < $1.date })

        results.append(.occurrence(sortedOccurrences[0]))
        let calendar = Calendar.current

        for i in 1 ..< sortedOccurrences.count {
            let previous = sortedOccurrences[i - 1]
            let current = sortedOccurrences[i]

            let difference = Calendar.current.dateComponents(
                [.day],
                from: calendar.startOfDay(for: previous.date),
                to: calendar.startOfDay(for: current.date)
            )

            if let days = difference.day {
                results.append(.interval(index: i, interval: days))
            } else {
                results.append(.interval(index: i, interval: -1))
            }

            results.append(.occurrence(current))
        }

        return results.reversed()
    }

    var averageInterval: Float? {
        let intervals = occurrencesAndIntervals.compactMap { row -> Int? in
            switch row {
            case .occurrence:
                return nil

            case .interval(_, let interval):
                return interval
            }
        }

        guard intervals.count > 0 else { return nil }

        return Float(intervals.reduce(0, +) / intervals.count)
    }

    init(event: Event) {
        self.event = event
//        let eventID = event.persistentModelID
//        _occurrences = Query(
//            filter: #Predicate<Occurrence> { occurrence in
//                occurrence.event?.persistentModelID == eventID
//            },
//            sort: [SortDescriptor(\.date, order: .reverse)]
//        )
    }

    var averageValueMessage: String {
        averageInterval.map({ "~\($0.formatted()) days" }) ?? "--"
    }

    var lastOccurrenceMessage: String {
        occurrences.first?.date.formatted(date: .long, time: .omitted) ?? "--"
    }

    var body: some View {
        List {
            if !event.descriptionContent.isEmpty {
                Text(event.descriptionContent)
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            }

            if occurrences.isEmpty {
                ContentUnavailableView(
                    "No Occurrences",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("There are no recorded occurrences for this action yet.")
                )
            } else {
                HStack {
                    statsView(title: "Occurrence Count", message: "\(occurrences.count) times")

                    statsView(title: "Repeats", message: averageValueMessage)

                    statsView(title: "Last Tracked", message: lastOccurrenceMessage)
                }
                .listRowSeparator(.hidden)

                ForEach(occurrencesAndIntervals) { row in
                    switch row {
                    case .occurrence(let occurrence):
                        occurrenceRow(for: occurrence)

                    case .interval(_, let interval):
                        Text("\(interval) days")
                            .foregroundStyle(Color.secondary)
                            .listRowInsets(EdgeInsets(top: 0, leading: 60, bottom: 0, trailing: 0))
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        #if os(macOS)
        .safeAreaInset(edge: .top, content: {
            Text(event.name)
                .font(.title.bold())
        })
        #endif
        .listStyle(.plain)
        .navigationTitle(event.name)
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Occurrence", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }

                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Event", systemImage: "pencil")
                            .labelStyle(.titleAndIcon)
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EditEventFormView(event: event)
                #if os(macOS)
                    .frame(minWidth: 400, minHeight: 400, alignment: .topLeading)
                #endif
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                OccurrenceFormView(useCase: .newForEvent(event))
                #if os(macOS)
                    .frame(minHeight: 400, alignment: .topLeading)
                #endif
            }
            .presentationDetents([.medium, .large])
        }
    }

    func occurrenceRow(for occurrence: Occurrence) -> some View {
        HStack {
            Circle()
                .foregroundStyle(Color.accent)
                .frame(width: 24)

            Text(occurrence.date.formatted(date: .long, time: .omitted))
                .bold()
        }
    }

    func statsView(title: String, message: String) -> some View {
        VStack {
            Text(title)
                .font(.caption)
            Text(message)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(Color.secondary.opacity(0.4))
        )
    }

    private func deleteOccurrences(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(occurrences[index])
        }
    }
}

private struct Demo: View {
    @Query var events: [Event]

    var body: some View {
        if let sampleEvent = events.first(where: { $0.name.contains("Vacuum") }) {
            EventDetailView(event: sampleEvent)
        } else {
            Text("No event found")
        }
    }
}

#Preview {
    TabView {
        Tab {
            NavigationStack {
                PreviewDataContainer {
                    Demo()
                }
            }
        } label: {
            Label("Hello", systemImage: "pencil")
        }

        Tab {
            Text("TODO")
        } label: {
            Label("Another", systemImage: "pencil")
        }
    }
}
