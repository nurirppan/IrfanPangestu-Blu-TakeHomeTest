import Foundation
@testable import IrfanPangestu_Blu_TakeHomeTest

extension SongModel {
    static func sample(id: Int, title: String = "Song") -> SongModel {
        SongModel(
            id: id,
            title: title,
            artist: "Coldplay",
            album: "Parachutes",
            artworkURL: nil,
            previewURL: URL(filePath: "/previews/\(id).m4a")
        )
    }
}
