/// Runs a view-model operation and turns any failure into `AppErrorType` plus a retry, so view models never repeat do/catch.
@MainActor
protocol ErrorHandling: AnyObject {
    func handle(_ error: AppErrorType, retry: @escaping @MainActor () async -> Void)
}

extension ErrorHandling {
    func performTask(_ operation: @escaping @MainActor () async throws -> Void) async {
        do {
            try await operation()
        } catch is CancellationError {
            return
        } catch {
            handle(error as? AppErrorType ?? .unknown) { [weak self] in
                await self?.performTask(operation)
            }
        }
    }
}
