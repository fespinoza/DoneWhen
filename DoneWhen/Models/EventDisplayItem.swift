import Foundation
import SwiftData

struct EventDisplayItem: Identifiable {
    let event: Event
    let name: String

    var id: PersistentIdentifier { event.persistentModelID }

    static func prepare(
        _ events: [Event],
        filterText: String,
        ascending: Bool,
        sortByName: Bool,
        displayName: (String) -> String
    ) -> [EventDisplayItem] {
        let items = events.map { EventDisplayItem(event: $0, name: displayName($0.name)) }
            .filter { filterText.isEmpty || $0.name.localizedStandardContains(filterText) }
        return items.sorted { lhs, rhs in
            if !sortByName, lhs.event.lastOccurrenceDate != rhs.event.lastOccurrenceDate {
                switch (lhs.event.lastOccurrenceDate, rhs.event.lastOccurrenceDate) {
                case let (left?, right?): return ascending ? left < right : left > right
                case (nil, _?): return ascending
                case (_?, nil): return !ascending
                case (nil, nil): break
                }
            }
            let comparison = lhs.name.localizedStandardCompare(rhs.name)
            // Stable sorting preserves input order when displayed names are equal.
            return comparison == (sortByName && !ascending ? .orderedDescending : .orderedAscending)
        }
    }
}
