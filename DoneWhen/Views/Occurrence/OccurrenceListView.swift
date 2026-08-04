import SwiftUI
import SwiftData

public struct OccurrenceListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet: Bool = false
    @State private var occurrenceToEdit: Occurrence?

    @Query private var occurrences: [Occurrence]

    public init() {
        _occurrences = Query(sort: [SortDescriptor(\.date, order: .reverse)])
    }

    private var groupedByDay: [(day: Date, items: [Occurrence])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: occurrences) { occurrence in
            calendar.startOfDay(for: occurrence.date)
        }
        let sortedDays = groups.keys.sorted(by: >)
        return sortedDays.map { day in
            let items = (groups[day] ?? []).sorted { $0.date > $1.date }
            return (day: day, items: items)
        }
    }

    private func sectionHeader(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    private func deleteOccurrences(_ offsets: IndexSet, in items: [Occurrence]) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }

    public var body: some View {
        List {
            if occurrences.isEmpty {
                EmptyState(showingAddSheet: $showingAddSheet)
            } else {
                ForEach(groupedByDay, id: \.day) { section in
                    Section {
                        ForEach(section.items) { occurrence in
                            OccurrenceFeedRow(occurrence: occurrence)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions {
                                    Button(role: .destructive, action: { modelContext.delete(occurrence) }) {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button(action: { occurrenceToEdit = occurrence }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                        }
                        .onDelete { offsets in
                            deleteOccurrences(offsets, in: section.items)
                        }
                    } header: {
                        OccurrenceDayHeader(title: sectionHeader(for: section.day))
                    }
                }
            }
        }
        .sheet(item: $occurrenceToEdit, content: { occurrence in
            NavigationStack {
                OccurrenceFormView(useCase: .edit(occurrence))
            }
        })
        .listStyle(.plain)
        .navigationTitle("Timeline")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Occurrence", systemImage: "plus")
                }
                .buttonStyle(.glassProminent)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                OccurrenceFormView(useCase: .new)
                #if os(macOS)
                    .frame(minHeight: 400, alignment: .topLeading)
                #endif
            }
            .presentationDetents([.medium, .large])
        }
        .task { try? normalizeEvents() }
    }

    func normalizeEvents() throws {
        let events: [Event] = try modelContext.fetch(.init())
        print("---- normalizing \(events.count) events")
        events.forEach { event in
            event.recomputeLastOccurrenceDate()
        }
        try modelContext.save()
    }
}

private struct OccurrenceDayHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OccurrenceFeedRow: View {
    let occurrence: Occurrence

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            timeBadge

            VStack(alignment: .leading, spacing: 6) {
                Text(actionName)
                    .font(.headline)
                    .foregroundStyle(hasActionName ? .primary : .secondary)
                    .lineLimit(2)

                if let repeatText {
                    Label(repeatText, systemImage: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .labelIconToTitleSpacing(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowSeparator(.hidden)
    }

    private var timeBadge: some View {
        Text(occurrence.date, style: .time)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
            }
    }

    private var actionName: String {
        guard let name = occurrence.event?.name.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            return "No Action"
        }

        return name
    }

    private var hasActionName: Bool {
        occurrence.event?.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private var repeatText: String? {
        guard let interval = occurrence.event?.repeatInterval,
              let period = occurrence.event?.repeatPeriod else {
            return nil
        }

        if interval == 1 {
            return "Repeats every \(period.rawValue)"
        } else {
            return "Repeats every \(interval) \(period.rawValue)s"
        }
    }
}

#Preview {
    NavigationStack {
        PreviewDataContainer {
            OccurrenceListView()
        }
    }
}
