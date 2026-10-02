import FactoryKit
import Foundation

extension Container: @retroactive AutoRegistering {
    /// The only place that connects the domain's contracts to the data layer's implementations.
    /// `nonisolated` because FactoryKit calls it from its own resolution code, before the first dependency is built.
    public nonisolated func autoRegister() {
        songRepository.register { SongRepositoryImpl(session: .shared) }
    }
}
