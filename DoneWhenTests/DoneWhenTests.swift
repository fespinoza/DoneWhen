//
//  DoneWhenTests.swift
//  DoneWhenTests
//
//  Created by Felipe Espinoza on 17/08/2026.
//

import Testing
import Foundation

struct DoneWhenTests {

    struct DateParts: Sendable {
        let year: Int
        let month: Int
        let day: Int
    }

    struct DayComparisonCase: Sendable {
        let from: DateParts
        let to: DateParts
        let expectedDays: Int
    }

    @Test(
        "Compares days between dates",
        arguments: [
            DayComparisonCase(
                from: DateParts(year: 2026, month: 8, day: 3),
                to: DateParts(year: 2026, month: 8, day: 10),
                expectedDays: 7
            ),
            DayComparisonCase(
                from: DateParts(year: 2026, month: 8, day: 3),
                to: DateParts(year: 2026, month: 8, day: 3),
                expectedDays: 0
            ),
            DayComparisonCase(
                from: DateParts(year: 2026, month: 8, day: 10),
                to: DateParts(year: 2026, month: 8, day: 3),
                expectedDays: -7
            ),
            DayComparisonCase(
                from: DateParts(year: 2026, month: 2, day: 27),
                to: DateParts(year: 2026, month: 3, day: 1),
                expectedDays: 2
            ),
            DayComparisonCase(
                from: DateParts(year: 2026, month: 12, day: 30),
                to: DateParts(year: 2027, month: 1, day: 2),
                expectedDays: 3
            )
        ]
    )
    func compareDaysBetweenReturnsExpectedDayDifference(testCase: DayComparisonCase) throws {
        let calendar: Calendar = .current
        let fromDate = try date(from: testCase.from, calendar: calendar)
        let toDate = try date(from: testCase.to, calendar: calendar)

        let result = try #require(compareDaysBetween(from: fromDate, to: toDate))

        #expect(result == testCase.expectedDays)
    }

    @Test(
        arguments: [
            DayComparisonCase(
                from: DateParts(year: 2026, month: 8, day: 3),
                to: DateParts(year: 2026, month: 8, day: 10),
                expectedDays: 7
            ),
            DayComparisonCase(
                from: DateParts(year: 2026, month: 8, day: 3),
                to: DateParts(year: 2026, month: 8, day: 3),
                expectedDays: 0
            ),
            DayComparisonCase(
                from: DateParts(year: 2026, month: 8, day: 10),
                to: DateParts(year: 2026, month: 8, day: 3),
                expectedDays: -7
            ),
            DayComparisonCase(
                from: DateParts(year: 2026, month: 2, day: 27),
                to: DateParts(year: 2026, month: 3, day: 1),
                expectedDays: 2
            ),
            DayComparisonCase(
                from: DateParts(year: 2026, month: 12, day: 30),
                to: DateParts(year: 2027, month: 1, day: 2),
                expectedDays: 3
            )
        ]
    )
    func `other test`(testCase: DayComparisonCase) throws {
        let calendar: Calendar = .current
        let fromDate = try date(from: testCase.from, calendar: calendar)
        let toDate = try date(from: testCase.to, calendar: calendar)

        let result = try #require(aiCompareDaysBetween(from: fromDate, to: toDate))

        #expect(result == testCase.expectedDays)
    }

    private func date(from parts: DateParts, calendar: Calendar) throws -> Date {
        try #require(calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: parts.year,
                month: parts.month,
                day: parts.day,
                hour: 12
            )
        ))
    }

}

func compareDaysBetween(from: Date, to: Date) -> Int? {
    Calendar.current.dateComponents(
        [.day, .month, .year],
        from: from,
        to: to
    ).day
}


func aiCompareDaysBetween(from: Date, to: Date) -> Int? {
    let calendar: Calendar = .current
    let startDate = calendar.startOfDay(for: from)
    let endDate = calendar.startOfDay(for: to)

    return calendar.dateComponents([.day], from: startDate, to: endDate).day
}
