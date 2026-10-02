import Foundation

/// Loads JSON captured from the real iTunes Search API.
enum FixtureType {
    static func data(_ name: String) throws -> Data {
        guard let url = Bundle(for: FixtureBundleToken.self).url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }
}

/// The test bundle holds the fixtures; a class is what `Bundle(for:)` needs to find it.
private final class FixtureBundleToken {}
