import SwiftUI
import SwiftData

struct OccurrenceFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let useCase: UseCase
    var onCreated: (Occurrence) -> Void = { _ in }

    enum UseCase {
        case edit(Occurrence)
        case new
        case newForEvent(Event)
    }

    @State private var selectedEvent: Event? = nil
    @State private var date: Date = Date()
    @State private var step: WizardStep = .action

    private enum WizardStep {
        case action
        case occurrenceDate

        var title: String {
            switch self {
            case .action:
                return "Choose Event Type"
            case .occurrenceDate:
                return "Register Event"
            }
        }
    }

    var body: some View {
        VStack {
            switch step {
            case .action:
                OccurrenceActionSelectionView(selectedEvent: $selectedEvent) { event in
                    selectedEvent = event
                    withAnimation {
                        step = .occurrenceDate
                    }
                }
            case .occurrenceDate:
                dateStep
            }

            #if os(macOS)
            HStack {
                Spacer()

                    Button("Cancel") { dismiss() }

                if step == .occurrenceDate {
                    Button("Save") {
                        saveOccurrence()
                    }
                    .disabled(selectedEvent == nil)
                }
            }
            #endif
        }
        .task {
            switch useCase {
            case let .edit(occurrence):
                selectedEvent = occurrence.event
                date = occurrence.date
                step = .occurrenceDate

            case .new:
                selectedEvent = nil
                date = Date()
                step = .action

            case let .newForEvent(event):
                selectedEvent = event
                date = Date()
                step = .occurrenceDate
            }
        }
        .navigationTitle(step.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if step == .occurrenceDate {
                    Button("Save") {
                        saveOccurrence()
                    }
                    .disabled(selectedEvent == nil)
                }
            }
        }
        #endif
    }

    private var dateStep: some View {
        Form {
            Section("What") {
                if let event = selectedEvent {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.name)
                                .font(.headline)

                            if let interval = event.repeatInterval, let period = event.repeatPeriod {
                                Text("Repeats every \(interval) \(period.rawValue)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button("Change") {
                            withAnimation {
                                step = .action
                            }
                        }
                    }
                } else {
                    Button {
                        withAnimation {
                            step = .action
                        }
                    } label: {
                        Label("Choose Event", systemImage: "checkmark.circle")
                    }
                }
            }

            Section("When") {
                DatePicker("Date", selection: $date, displayedComponents: [.date])
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func saveOccurrence() {
        guard let event = selectedEvent else { return }

        switch useCase {
        case let .edit(occurrence):
            occurrence.event = event
            occurrence.date = date
            event.recomputeLastOccurrenceDate()

        case .new, .newForEvent:
            let occurrence = Occurrence(event: event, date: date)
            modelContext.insert(occurrence)
            event.recomputeLastOccurrenceDate()
            onCreated(occurrence)
        }

        dismiss()
    }
}

private struct OccurrenceActionSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]

    @Binding var selectedEvent: Event?
    let onSelected: (Event) -> Void

    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    init(selectedEvent: Binding<Event?>, onSelected: @escaping (Event) -> Void) {
        _events = Query(sort: [SortDescriptor(\.name, order: .forward)])
        _selectedEvent = selectedEvent
        self.onSelected = onSelected
    }

    var body: some View {
        List {
            if canCreateEvent {
                Section {
                    Button {
                        createEvent()
                    } label: {
                        Label("Create \"\(trimmedSearchText)\"", systemImage: "plus.circle.fill")
                    }
                }
            }

            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    trimmedSearchText.isEmpty ? "No Actions" : "No Matching Actions",
                    systemImage: "checkmark.circle"
                )
            } else {
                ForEach(filteredEvents) { event in
                    Button {
                        select(event)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.name)
                                    .font(.headline)

                                if let interval = event.repeatInterval, let period = event.repeatPeriod {
                                    Text("Repeats every \(interval) \(period.rawValue)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if event == selectedEvent {
                                Image(systemName: "checkmark")
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        #if os(iOS)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Find or create an action")
        )
        #else
        .searchable(
            text: $searchText,
            prompt: Text("Find or create an action")
        )
        #endif
//        .searchFocused($isSearchFocused)
//        .onAppear {
//            isSearchFocused = true
//        }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredEvents: [Event] {
        guard !trimmedSearchText.isEmpty else { return events }

        return events.filter { event in
            event.name.localizedStandardContains(trimmedSearchText)
        }
    }

    private var canCreateEvent: Bool {
        guard !trimmedSearchText.isEmpty else { return false }

        return !events.contains { event in
            event.name.compare(trimmedSearchText, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private func createEvent() {
        let newEvent = Event(name: trimmedSearchText, creationDate: Date())
        modelContext.insert(newEvent)
        select(newEvent)
    }

    private func select(_ event: Event) {
        selectedEvent = event
        onSelected(event)
    }
}

#Preview {
    NavigationStack {
        PreviewDataContainer {
            OccurrenceFormView(useCase: .new)
        }
    }
}
