// FST / CenVu | (+84) 842 841 222

import SwiftUI
import Foundation
import Combine

@MainActor
public final class TechnicalLogsUpdateViewModel: ObservableObject {
    @Published public var state: AppUpdateState = .idle
    private let updateService: AppUpdateServicing

    public init(updateService: AppUpdateServicing = AppUpdateService()) {
        self.updateService = updateService
    }

    public func checkForUpdates() {
        Task {
            state = .checking
            let newState = await updateService.checkForUpdates()
            await MainActor.run {
                self.state = newState
            }
        }
    }
}
