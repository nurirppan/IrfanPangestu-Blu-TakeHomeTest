import Foundation
import UIKit

/// In-memory artwork cache, so rows scrolling back into view show their image without a refetch.
@MainActor
final class ImageLoader {
    static let shared = ImageLoader(session: .shared)

    private let session: URLSession
    private let cache = NSCache<NSURL, UIImage>()

    init(session: URLSession) {
        self.session = session
        cache.countLimit = 300
    }

    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func image(for url: URL) async -> UIImage? {
        if let cached = cachedImage(for: url) {
            return cached
        }
        guard let response = try? await session.data(from: url), let image = UIImage(data: response.0) else {
            return nil
        }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
