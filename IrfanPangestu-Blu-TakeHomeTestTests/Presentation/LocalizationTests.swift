import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest
import Testing

/// English is the catalog's source language and needs no table; CI checks that every entry has its translation.
struct LocalizationTests {
    @Test("The app carries the Bahasa Indonesia texts, formats included")
    func bundleSpeaksIndonesian() throws {
        let path = try #require(Bundle.main.path(forResource: "id", ofType: "lproj"))
        let indonesian = try #require(Bundle(path: path))

        #expect(indonesian.localizedString(forKey: "No internet connection", value: nil, table: nil) == "Tidak ada koneksi internet")
        #expect(indonesian.localizedString(forKey: "No songs found for “%@”", value: nil, table: nil) == "Tidak ada lagu untuk “%@”")
        #expect(indonesian.localizedString(forKey: "%@ of %@", value: nil, table: nil) == "%1$@ dari %2$@")
    }
}
