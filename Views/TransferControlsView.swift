import SwiftUI

public struct TransferControlsView: View {
    @ObservedObject var viewModel: TransferViewModel
    
    // Limits represented in KB/s consistent with Rsync Engine
    private let presetBandwidths: [Int?] = [50000, 120000, 240000, nil]
    
    public init(viewModel: TransferViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Bandwidth control
            VStack(spacing: 12) {
                HStack {
                    Text("BANDWIDTH LIMIT (MB/S)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .bold()
                    Spacer()
                    Text(viewModel.bandwidthLimit == nil ? "UNLIMITED" : "\(viewModel.bandwidthLimit! / 1000) MB/s")
                        .foregroundColor(.blue)
                        .bold()
                }
                
                HStack {
                    Text("Presets:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    ForEach(presetBandwidths, id: \.self) { limit in
                        Button(action: {
                            viewModel.bandwidthLimit = limit
                        }) {
                            Text(limit == nil ? "UNLIMITED" : "\(limit! / 1000) MB/S")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(viewModel.bandwidthLimit == limit ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(viewModel.bandwidthLimit == limit ? .white : .gray)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.transferState == .copying || viewModel.transferState == .verifying)
                    }
                }
            }
            
            // Verification Mode Toggle
            VStack(spacing: 12) {
                HStack {
                    Text("VERIFICATION MODE")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .bold()
                    Spacer()
                }
                
                Picker("Verification Mode", selection: $viewModel.verificationMode) {
                    Text("None").tag(VerificationMode.none)
                    Text("Random 33%").tag(VerificationMode.random33)
                    Text("Full 100%").tag(VerificationMode.full)
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(viewModel.transferState == .copying || viewModel.transferState == .verifying)
            }
            
            // Action Button
            if viewModel.transferState == .copying || viewModel.transferState == .verifying {
                Button(action: {
                    viewModel.cancelTransfer()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("STOP SECURE MEDIA COPY")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: {
                    viewModel.startTransfer()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("START SECURE MEDIA COPY")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.transferState == .safeToFormat ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.transferState != .ready && 
                          viewModel.transferState != .error && 
                          viewModel.transferState != .cancelled && 
                          viewModel.transferState != .copyComplete && 
                          viewModel.transferState != .safeToFormat)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
