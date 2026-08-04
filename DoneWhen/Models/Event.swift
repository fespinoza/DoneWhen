import SwiftData
import Foundation

typealias CurrentVersion = ModelsV2

typealias Event = CurrentVersion.Event
typealias Occurrence = CurrentVersion.Occurrence
typealias RepeatPeriod = CurrentVersion.RepeatPeriod

enum MigrationPlan: SchemaMigrationPlan {
    static let schemas: [any VersionedSchema.Type] = [
        ModelsV1.self,
        ModelsV2.self,
    ]

    static let stages: [MigrationStage] = [
        .custom(
            fromVersion: ModelsV1.self,
            toVersion: ModelsV2.self,
            willMigrate: nil,
            didMigrate: { context in
                let events: [ModelsV2.Event] = try context.fetch(.init())
                events.forEach { event in
                    event.lastOccurrenceDate = event.occurrences?.map(\.date).sorted().last
                }
                try context.save()
            }
        )
    ]
}

enum ModelsV1: VersionedSchema {
    static let models: [any PersistentModel.Type] = [Event.self, Occurrence.self]
    static let versionIdentifier: Schema.Version = .init(1, 0, 0)

    @Model
    class Event {
        var name: String = ""
        var creationDate: Date = Date()
        var repeatInterval: Int?
        var repeatPeriod: RepeatPeriod?

        @Relationship(deleteRule: .cascade, inverse: \Occurrence.event)
        var occurrences: [Occurrence]? = []

        init(
            name: String,
            creationDate: Date = .init(),
            repeatInterval: Int? = nil,
            repeatPeriod: RepeatPeriod? = nil
        ) {
            self.name = name
            self.creationDate = creationDate
            self.repeatInterval = repeatInterval
            self.repeatPeriod = repeatPeriod
        }

        var lastOccurrence: Occurrence? {
            occurrences?.sorted(by: { $0.date < $1.date }).last
        }
    }

    enum RepeatPeriod: String, Codable, CaseIterable {
        case day
        case week
        case month
        case year
    }

    @Model
    class Occurrence {
        var event: Event? = nil

        var date: Date = Date()

        init(event: Event, date: Date) {
            self.event = event
            self.date = date
        }
    }
}

enum ModelsV2: VersionedSchema {
    static let models: [any PersistentModel.Type] = [Event.self, Occurrence.self]
    static let versionIdentifier: Schema.Version = .init(2, 0, 0)

    @Model
    class Event {
        var name: String = ""
        var creationDate: Date = Date()
        var repeatInterval: Int?
        var repeatPeriod: RepeatPeriod?
        var lastOccurrenceDate: Date?

        @Relationship(deleteRule: .cascade, inverse: \Occurrence.event)
        var occurrences: [Occurrence]? = []

        init(
            name: String,
            creationDate: Date = .init(),
            repeatInterval: Int? = nil,
            repeatPeriod: RepeatPeriod? = nil,
            lastOccurrenceDate: Date? = nil
        ) {
            self.name = name
            self.creationDate = creationDate
            self.repeatInterval = repeatInterval
            self.repeatPeriod = repeatPeriod
            self.lastOccurrenceDate = lastOccurrenceDate
        }

        var lastOccurrence: Occurrence? {
            occurrences?.sorted(by: { $0.date < $1.date }).last
        }

        func recomputeLastOccurrenceDate() {
            lastOccurrenceDate = occurrences?.map(\.date).max()
        }

        func daysSinceLastOccurrence(with calendar: Calendar = .current, to date: Date = .init()) -> Int? {
            guard let lastOccurrenceDate else { return nil }

            let start = calendar.startOfDay(for: lastOccurrenceDate)
            let end = calendar.startOfDay(for: date)

            return calendar.dateComponents([.day], from: start, to: end).day
        }
    }

    enum RepeatPeriod: String, Codable, CaseIterable {
        case day
        case week
        case month
        case year
    }

    @Model
    class Occurrence {
        var event: Event? = nil

        var date: Date = Date()

        init(event: Event, date: Date) {
            self.event = event
            self.date = date
        }
    }
}
