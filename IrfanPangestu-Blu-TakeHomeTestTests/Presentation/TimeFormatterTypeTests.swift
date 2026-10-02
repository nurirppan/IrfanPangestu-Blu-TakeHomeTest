@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

struct TimeFormatterTypeTests {
    @Test(
        "Formats seconds as m:ss",
        arguments: zip([0, 30, 61, 29.9, 600], ["0:00", "0:30", "1:01", "0:29", "10:00"])
    )
    func formats(seconds: Double, expected: String) {
        #expect(TimeFormatterType.string(from: seconds) == expected)
    }

    @Test("Shows 0:00 for a duration that isn't known yet")
    func handlesUnknownDuration() {
        #expect(TimeFormatterType.string(from: .nan) == "0:00")
        #expect(TimeFormatterType.string(from: -1) == "0:00")
    }
}
