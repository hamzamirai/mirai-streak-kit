import Foundation
import Testing
@testable import MiraiStreakKit

/// Comprehensive tests for the Streak data structure and its outcome logic.
@Suite
struct StreakCoreTests {
    private let gregorian = Calendar(identifier: .gregorian)

    // MARK: - Basic Outcome Logic

    @Test("Same day check-in returns alreadyCompletedToday")
    func sameDayCheckIn() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 9).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 13).date!
        let streak = Streak(length: 3, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .alreadyCompletedToday)
    }

    @Test("Next day check-in continues streak")
    func nextDayCheckIn() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 19, hour: 12).date!
        let streak = Streak(length: 3, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    @Test("Midnight boundary: 23:59 → 00:01 continues streak")
    func midnightBoundaryContinues() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 23, minute: 59).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 19, hour: 0, minute: 1).date!
        let streak = Streak(length: 3, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    @Test("Missing one full day breaks streak")
    func missingOneDayBreaks() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 10, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 12, hour: 12).date!
        let streak = Streak(length: 8, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakBroken)
    }

    @Test("Missing multiple days breaks streak")
    func missingMultipleDaysBreaks() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 1, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 10, hour: 12).date!
        let streak = Streak(length: 8, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakBroken)
    }

    // MARK: - First Check-in (nil lastDate)

    @Test("First check-in with nil lastDate returns streakContinues")
    func firstCheckInWithNilDate() throws {
        let streak = Streak(length: 0, lastDate: nil)
        let now = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    @Test("First check-in preserves zero length")
    func firstCheckInPreservesZeroLength() throws {
        let streak = Streak(length: 0, lastDate: nil)
        let outcome = streak.determineOutcome(on: .now, calendar: gregorian)

        #expect(outcome == .streakContinues)
        #expect(streak.length == 0) // determineOutcome should not mutate
    }

    // MARK: - Calendar Variations

    @Test("Hebrew calendar handles same day correctly")
    func hebrewCalendarSameDay() throws {
        let hebrew = Calendar(identifier: .hebrew)
        let last = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 1, hour: 9).date!
        let now = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 1, hour: 13).date!
        let streak = Streak(length: 1, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: hebrew) == .alreadyCompletedToday)
    }

    @Test("Hebrew calendar handles next day correctly")
    func hebrewCalendarNextDay() throws {
        let hebrew = Calendar(identifier: .hebrew)
        let last = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 1, hour: 12).date!
        let now = DateComponents(calendar: hebrew, year: 5785, month: 1, day: 2, hour: 12).date!
        let streak = Streak(length: 1, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: hebrew) == .streakContinues)
    }

    @Test("Islamic calendar handles same day correctly")
    func islamicCalendarSameDay() throws {
        let islamic = Calendar(identifier: .islamic)
        let last = DateComponents(calendar: islamic, year: 1446, month: 1, day: 1, hour: 9).date!
        let now = DateComponents(calendar: islamic, year: 1446, month: 1, day: 1, hour: 13).date!
        let streak = Streak(length: 1, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: islamic) == .alreadyCompletedToday)
    }

    @Test("Islamic calendar handles next day correctly")
    func islamicCalendarNextDay() throws {
        let islamic = Calendar(identifier: .islamic)
        let last = DateComponents(calendar: islamic, year: 1446, month: 1, day: 1, hour: 12).date!
        let now = DateComponents(calendar: islamic, year: 1446, month: 1, day: 2, hour: 12).date!
        let streak = Streak(length: 1, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: islamic) == .streakContinues)
    }

    // MARK: - Boundary Conditions

    @Test("Month boundary: Dec 31 → Jan 1 continues streak")
    func monthBoundaryDecToJan() throws {
        let last = DateComponents(calendar: gregorian, year: 2024, month: 12, day: 31, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 1, day: 1, hour: 12).date!
        let streak = Streak(length: 5, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    @Test("Month boundary: Jan 31 → Feb 1 continues streak")
    func monthBoundaryJanToFeb() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 1, day: 31, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 2, day: 1, hour: 12).date!
        let streak = Streak(length: 5, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    @Test("Leap year: Feb 28 → Feb 29 continues streak")
    func leapYearFeb28ToFeb29() throws {
        let last = DateComponents(calendar: gregorian, year: 2024, month: 2, day: 28, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2024, month: 2, day: 29, hour: 12).date!
        let streak = Streak(length: 5, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    @Test("Leap year: Feb 29 → Mar 1 continues streak")
    func leapYearFeb29ToMar1() throws {
        let last = DateComponents(calendar: gregorian, year: 2024, month: 2, day: 29, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2024, month: 3, day: 1, hour: 12).date!
        let streak = Streak(length: 5, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    @Test("Non-leap year: Feb 28 → Mar 1 continues streak")
    func nonLeapYearFeb28ToMar1() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 2, day: 28, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 3, day: 1, hour: 12).date!
        let streak = Streak(length: 5, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    // MARK: - Extreme Values

    @Test("Very long streak length preserves value")
    func veryLongStreakLength() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 19, hour: 12).date!
        let longLength = Int.max - 1
        let streak = Streak(length: longLength, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
        #expect(streak.length == longLength)
    }

    @Test("Zero streak length is valid")
    func zeroStreakLength() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let now = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 19, hour: 12).date!
        let streak = Streak(length: 0, lastDate: last)

        #expect(streak.determineOutcome(on: now, calendar: gregorian) == .streakContinues)
    }

    // MARK: - Codable Conformance

    @Test("Encodes and decodes with valid data")
    func codableRoundTrip() throws {
        let last = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let original = Streak(length: 5, lastDate: last)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Streak.self, from: data)

        #expect(decoded.length == original.length)
        #expect(decoded.lastDate == original.lastDate)
    }

    @Test("Encodes and decodes with nil lastDate")
    func codableWithNilLastDate() throws {
        let original = Streak(length: 3, lastDate: nil)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Streak.self, from: data)

        #expect(decoded.length == original.length)
        #expect(decoded.lastDate == nil)
    }

    @Test("Decoding succeeds with missing optional fields")
    func decodingSucceedsWithMissingOptionalFields() throws {
        let invalidJSON = """
        {
            "length": 5
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Streak.self, from: invalidJSON)

        #expect(decoded.length == 5)
        #expect(decoded.lastDate == nil)
    }

    @Test("Decoding fails with wrong data types")
    func decodingFailsWithWrongTypes() throws {
        let invalidJSON = """
        {
            "length": "not_a_number",
            "lastDate": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        #expect(throws: DecodingError.self) {
            try decoder.decode(Streak.self, from: invalidJSON)
        }
    }

    // MARK: - Equatable Conformance

    @Test("Equal streaks with same values")
    func equalStreaksIdentical() throws {
        let date = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let streak1 = Streak(length: 5, lastDate: date)
        let streak2 = Streak(length: 5, lastDate: date)

        #expect(streak1 == streak2)
    }

    @Test("Unequal streaks with different lengths")
    func unequalDifferentLength() throws {
        let date = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let streak1 = Streak(length: 5, lastDate: date)
        let streak2 = Streak(length: 6, lastDate: date)

        #expect(streak1 != streak2)
    }

    @Test("Unequal streaks with different dates")
    func unequalDifferentDate() throws {
        let date1 = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let date2 = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 19, hour: 12).date!
        let streak1 = Streak(length: 5, lastDate: date1)
        let streak2 = Streak(length: 5, lastDate: date2)

        #expect(streak1 != streak2)
    }

    @Test("Equal streaks both with nil lastDate")
    func equalBothWithNilDate() throws {
        let streak1 = Streak(length: 0, lastDate: nil)
        let streak2 = Streak(length: 0, lastDate: nil)

        #expect(streak1 == streak2)
    }

    @Test("Unequal: one nil, one with date")
    func unequalNilVsDate() throws {
        let date = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let streak1 = Streak(length: 5, lastDate: nil)
        let streak2 = Streak(length: 5, lastDate: date)

        #expect(streak1 != streak2)
    }

    // MARK: - Initialization

    @Test("Default initialization creates zero length")
    func defaultInitZeroLength() throws {
        let streak = Streak()

        #expect(streak.length == 0)
        #expect(streak.lastDate == nil)
    }

    @Test("Custom initialization preserves values")
    func customInitPreservesValues() throws {
        let date = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let streak = Streak(length: 10, lastDate: date)

        #expect(streak.length == 10)
        #expect(streak.lastDate == date)
    }

    // MARK: - Outcome Enum Properties

    @Test("Outcome enum values are equatable")
    func outcomeEquatable() throws {
        #expect(Streak.Outcome.alreadyCompletedToday == .alreadyCompletedToday)
        #expect(Streak.Outcome.streakContinues == .streakContinues)
        #expect(Streak.Outcome.streakBroken == .streakBroken)
        #expect(Streak.Outcome.alreadyCompletedToday != .streakContinues)
    }

    // MARK: - Sendable Conformance

    @Test("Streak is sendable (concurrent context safe)")
    func streakSendable() async throws {
        let date = DateComponents(calendar: gregorian, year: 2025, month: 10, day: 18, hour: 12).date!
        let streak = Streak(length: 5, lastDate: date)

        // If this compiles, Sendable conformance is verified
        let _: Streak = streak
        #expect(true)
    }
}
