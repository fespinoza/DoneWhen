import Foundation
import SwiftData
import Testing
@testable import DoneWhen

@MainActor
struct AnonymizationTests {
    @Test(arguments: [
        ("Ann ann ANN Annual", "Person Person Person Annual"),
        ("Ann's (Ann), Ann_2", "Person's (Person), Ann_2"),
        ("Visit Ann Smith and Ann", "Visit Friend and Person"),
        ("ÅSE sees Åse", "Neighbor sees Neighbor"),
        ("Use C++ and a.b", "Use Language and $1\\literal"),
        ("🐶 Ann!", "🐶 Person!"),
        ("Unknown", "Unknown")
    ])
    func replacesWholeWords(input: String, expected: String) throws {
        let anonymizer = try TextAnonymizer(dictionary: [
            "Ann": "Person",
            "Ann Smith": "Friend",
            "Åse": "Neighbor",
            "C++": "Language",
            "a.b": "$1\\literal"
        ])
        #expect(anonymizer.anonymize(input) == expected)
    }

    @Test func replacementsDoNotCascade() throws {
        let anonymizer = try TextAnonymizer(dictionary: ["Ann": "Bob", "Bob": "Person"])
        #expect(anonymizer.anonymize("Ann Bob") == "Bob Person")
    }

    @Test(arguments: [
        #"{"":"Person"}"#,
        #"{"Ann":"  "}"#,
        #"{"Ann":"Person","ann":"Friend"}"#,
        #"{"Ann":2}"#,
        "invalid"
    ])
    func rejectsInvalidConfiguration(json: String) {
        #expect(throws: (any Error).self) {
            try TextAnonymizer(data: Data(json.utf8))
        }
    }

    @Test func emptyDictionaryPreservesInput() throws {
        let anonymizer = try TextAnonymizer(data: Data("{}".utf8))
        #expect(anonymizer.anonymize("Ann 🐶 Åse") == "Ann 🐶 Åse")
        #expect(anonymizer.anonymize("") == "")
    }

    @Test func missingFilePreservesInput() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("bundle")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let bundle = try #require(Bundle(url: directory))
        let anonymizer = try TextAnonymizer.load(bundle: bundle)
        #expect(anonymizer.anonymize("Ann 🐶 Åse") == "Ann 🐶 Åse")
    }

    @Test func decodesDictionary() throws {
        let anonymizer = try TextAnonymizer(data: Data(#"{"Fido":"Dog"}"#.utf8))
        #expect(anonymizer.anonymize("Walk Fido") == "Walk Dog")
    }

    @Test func bundledDictionaryIsIncluded() throws {
        let url = try #require(Bundle.main.url(forResource: "Anonymization", withExtension: "json"))
        _ = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: url))
    }

    @Test func sortsAndFiltersDisplayedNamesWithoutChangingModels() throws {
        let container = try ModelContainer(
            for: Event.self, Occurrence.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let first = Event(name: "Ann")
        let second = Event(name: "Bob")
        let third = Event(name: "Alice")
        for event in [first, second, third] { container.mainContext.insert(event) }
        try container.mainContext.save()
        let anonymizer = try TextAnonymizer(dictionary: [
            "Ann": "Zebra", "Bob": "Apple", "Alice": "Apple"
        ])
        let items = EventDisplayItem.prepare(
            [first, second, third], filterText: "", ascending: true,
            sortByName: true, displayName: anonymizer.anonymize
        )
        #expect(items.map(\.name) == ["Apple", "Apple", "Zebra"])
        #expect(Set(items.map(\.id)).count == 3)
        #expect(items[0].event === second)
        let filtered = EventDisplayItem.prepare(
            [first, second, third], filterText: "apple", ascending: true,
            sortByName: true, displayName: anonymizer.anonymize
        )
        #expect(filtered.count == 2)
        #expect([first.name, second.name, third.name] == ["Ann", "Bob", "Alice"])
        let original = EventDisplayItem.prepare(
            [first, second, third], filterText: "Ann", ascending: true,
            sortByName: true, displayName: { $0 }
        )
        #expect(original.map(\.name) == ["Ann"])
        first.lastOccurrenceDate = Date(timeIntervalSince1970: 100)
        let byDate = EventDisplayItem.prepare(
            [first, second, third], filterText: "", ascending: false,
            sortByName: false, displayName: anonymizer.anonymize
        )
        #expect(byDate.first?.event === first)
        #expect(byDate.dropFirst().map(\.name) == ["Apple", "Apple"])
    }
}
