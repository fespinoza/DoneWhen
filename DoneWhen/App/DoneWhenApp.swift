//
//  DoneWhenApp.swift
//  DoneWhen
//
//  Created by Felipe Espinoza on 22/06/2026.
//

import SwiftUI
import SwiftData

extension TimeInterval {
    var hour: TimeInterval { hours }
    var hours: TimeInterval { self * oneHour }

    var day: TimeInterval { days }
    var days: TimeInterval { self * oneDay }

    var week: TimeInterval { weeks }
    var weeks: TimeInterval { self * oneWeek }

    private var oneHour: TimeInterval { 60 * 60 }
    private var oneDay: TimeInterval { 24 * oneHour }
    private var oneWeek: TimeInterval { 7 * oneDay }
}

extension ProcessInfo {
    static var isRunningForPreviews: Bool {
        processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

struct ContainerFactory {
    private static func createContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([
            Event.self,
            Occurrence.self,
        ])

        let modelConfiguration: ModelConfiguration

        if inMemory {
            modelConfiguration = .init(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
            let cloudKitEnvironment = (Bundle.main.object(forInfoDictionaryKey: "CLOUDKIT_ENVIRONMENT") as? String) ?? "development"

            let storePath: String
            if cloudKitEnvironment.lowercased() == "development" {
                print("running in development CloudKit environment")
                storePath = "debug-store.sqlite"
            } else {
                print("running in '\(cloudKitEnvironment)'")
                storePath = "release-store.sqlite"
            }

            let storeURL = URL.applicationSupportDirectory.appending(path: storePath)

            modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        }

        let container = try ModelContainer(
            for: schema,
            migrationPlan: MigrationPlan.self,
            configurations: [modelConfiguration]
        )
        print("store --- \(modelConfiguration.url) -- inMemory: \(inMemory ? "yes" : "no")")
        return container
    }

    static func testContainer() throws -> ModelContainer {
        let container = try createContainer(inMemory: true)

        print("--- container built")

        let context = container.mainContext

        let cutNails = Event(
            name: "Cut kids nails",
            creationDate: Date(),
            repeatInterval: 1,
            repeatPeriod: .week
        )
        let trash = Event(
            name: "Take out trash",
            creationDate: Date(),
            repeatInterval: 2,
            repeatPeriod: .week
        )
        let vacuumClean = Event(
            name: "Vacuum clean",
            creationDate: Date(),
        )

        let cleanBathroom = Event(
            name: "Clean downstairs bathroom",
            creationDate: Date(),
        )

        let runFido = Event(
            name: "Run Fido in the Living Room",
            creationDate: Date(),
        )

        let _ = [
            Occurrence(event: cutNails, date: Date()),
            Occurrence(event: cutNails, date: Date().addingTimeInterval(-1.day)),
            Occurrence(event: cutNails, date: Date().addingTimeInterval(-2.days)),

            Occurrence(event: trash, date: Date().addingTimeInterval(-1.week)),
            Occurrence(event: trash, date: Date().addingTimeInterval(-2.weeks)),

            Occurrence(event: vacuumClean, date: Date()),
            Occurrence(event: vacuumClean, date: Date().addingTimeInterval(-1.week)),
            Occurrence(event: vacuumClean, date: Date().addingTimeInterval(-2.weeks - 2.days)),
            Occurrence(event: vacuumClean, date: Date().addingTimeInterval(-3.weeks)),

            Occurrence(event: cleanBathroom, date: Date().addingTimeInterval(-6.days)),

            Occurrence(event: runFido, date: Date().addingTimeInterval(-1.days)),
        ].map { context.insert($0) }

        context.insert(cutNails)
        context.insert(trash)
        context.insert(vacuumClean)
        context.insert(cleanBathroom)
        context.insert(runFido)

        try context.save()

        return container
    }

    static let sharedContainer: ModelContainer = {
        do {
            return try createContainer(inMemory: ProcessInfo.isRunningForPreviews)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

@main
struct DoneWhenApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    OccurrenceListView()
                }
                .tabItem {
                    Label(
                        "Timeline",
                        systemImage: "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath.fill"
                    )
                }

                NavigationStack {
                    EventByNameListView()
                }
                .tabItem {
                    Label("Events", systemImage: "checkmark.circle")
                }
            }
        }
        .modelContainer(ContainerFactory.sharedContainer)
    }
}
