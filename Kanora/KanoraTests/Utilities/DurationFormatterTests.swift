import Foundation
@testable import Kanora
import Testing

struct DurationFormatterTests {
    @Test("Formats minute-second pattern for English locale")
    func formatsMinuteSecondForEnglishLocale() {
        let result = DurationFormatter.string(from: 125, locale: Locale(identifier: "en_GB"))
        #expect(result == "2:05")
    }

    @Test("Formats hour-minute-second pattern when duration exceeds an hour")
    func formatsHourMinuteSecondWhenNeeded() {
        let result = DurationFormatter.string(from: 3723, locale: Locale(identifier: "en_GB"))
        #expect(result == "1:02:03")
    }

    @Test("Honours locales that use non-Latin digits")
    func honoursNonLatinDigits() {
        let result = DurationFormatter.string(from: 125, locale: Locale(identifier: "ar"))
        let arabicDigits = CharacterSet(charactersIn: "٠١٢٣٤٥٦٧٨٩")
        #expect(result.unicodeScalars.contains { arabicDigits.contains($0) })
    }
}
