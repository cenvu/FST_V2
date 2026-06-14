import Foundation
import Combine

@MainActor
public final class TransferViewModel: ObservableObject {
    @Published public var sourceURL: URL?
    @Published public var destinationURL: URL?
    @Published public var bandwidthLimit: Int? = nil
    @Published public var verificationMode: VerificationMode = .random33
    
    @Published public var transferState: TransferState = .ready
    @Published public var progress: Double = 0.0
    @Published public var speed: Double = 0.0
    @Published public var eta: TimeInterval = 0.0
    @Published public var currentFile: String = ""
    @Published public var logs: [String] = []
    @Published public var errorMessage: String? = nil
    
    private let coordinator: TransferCoordinator
    
    public init(coordinator: TransferCoordinator = TransferCoordinator()) {
        self.coordinator = coordinator
        setupBindings()
    }
    
    private func setupBindings() {
        coordinator.onStateChanged = { [weak self] state in
            self?.transferState = state
            if state == .ready {
                self?.resetTransferMetrics()
            }
        }
        
        coordinator.onProgress = { [weak self] p in
            self?.progress = p
        }
        
        coordinator.onSpeed = { [weak self] s in
            self?.speed = s
        }
        
        coordinator.onETA = { [weak self] e in
            self?.eta = e
        }
        
        coordinator.onCurrentFile = { [weak self] f in
            self?.currentFile = f
        }
        
        coordinator.onError = { [weak self] err in
            self?.errorMessage = err.localizedDescription
            self?.addLog("[ERROR] \(err.localizedDescription)")
        }
    }
    
    public func startTransfer() {
        guard let sourceURL = sourceURL, let destinationURL = destinationURL else {
            errorMessage = "Please select both source and destination folders."
            return
        }
        
        resetTransferMetrics()
        errorMessage = nil
        addLog("[INFO] Starting transfer workflow...")
        
        coordinator.startTransfer(
            source: sourceURL,
            destination: destinationURL,
            bandwidthLimit: bandwidthLimit,
            mode: verificationMode
        )
    }
    
    public func cancelTransfer() {
        addLog("[WARNING] User requested transfer cancellation.")
        coordinator.cancelTransfer()
    }
    
    private func resetTransferMetrics() {
        progress = 0.0
        speed = 0.0
        eta = 0.0
        currentFile = ""
    }
    
    private func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        logs.append("[\(timestamp)] \(message)")
    }
}
