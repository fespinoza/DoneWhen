import SwiftUI
import SwiftData

struct ActionWorkflowView: View {
    @State var selectedEvent: Event?

    var body: some View {
        EventListView(selectedEvent: $selectedEvent)
    }
}

public struct EventListView: View {
    @State private var searchText: String = ""
    @Binding var selectedEvent: Event?
    @FocusState var isSearchFocused: Bool

    public var body: some View {
        EventQueryListView(searchText: searchText, selectedEvent: $selectedEvent)
            .navigationTitle("Actions")
        #if os(iOS)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Find or create an activity to track")
            )
        #else
            .searchable(
                text: $searchText,
                prompt: Text("Find or create an activity to track")
            )
        #endif
        .searchFocused($isSearchFocused)
        .onAppear {
            isSearchFocused = true
        }
    }
}

struct EventQueryListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var events: [Event]

    @Binding var selectedEvent: Event?
    let searchText: String

    init(searchText: String, selectedEvent: Binding<Event?>) {
        let predicate = #Predicate<Event> { event in
            if searchText.isEmpty {
                true
            } else {
                event.name.localizedStandardContains(searchText)
            }
        }
        _events = Query(filter: predicate, sort: [SortDescriptor(\.creationDate, order: .reverse)])
        self._selectedEvent = selectedEvent
        self.searchText = searchText
    }
    
    var body: some View {
        List {
            ForEach(events) { event in
                Button {
                    selectedEvent = event
                } label: {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(event.name)

                            Spacer()

                            if event == selectedEvent {
                                Image(systemName: "checkmark")
                            }
                        }
                        if let interval = event.repeatInterval, let period = event.repeatPeriod {
                            Text("Repeats every \(interval) \(period.rawValue)") // TODO: Pluralize
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteEvents)

            if events.isEmpty && !searchText.isEmpty {
                Button("Create action: \(searchText)") {
                    let newEvent = Event(name: searchText, creationDate: Date())
                    modelContext.insert(newEvent)
                    selectedEvent = newEvent
                }
            }
        }
        .listStyle(.plain)
//        .toolbar {
//            ToolbarItem {
//                NavigationLink {
//                    EventFormView { newEvent in
//                        selectedEvent = newEvent
//                    }
//                } label: {
//                    Label("Create Action", systemImage: "plus")
//                }
//            }
//        }
    }
    
    private func deleteEvents(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(events[index])
        }
    }
}

#Preview {
    EventListView(selectedEvent: .constant(nil))
        .modelContainer(for: Event.self, inMemory: true)
}

/*

- Cut the grass outside the hedge
- Vacuum clean living room
- Vacuum clean stairs
- Laundry towels
- Change bed sheets
-

 */
