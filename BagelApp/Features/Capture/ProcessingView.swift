import SwiftUI

struct ProcessingView: View {
    let stage: CaptureViewModel.Stage

    private var label: String {
        switch stage {
        case .recognizingText: return "Reading document…"
        case .parsingWithLLM: return "Itemizing…"
        case .reviewReady: return "Finishing up…"
        default: return "Working…"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(label)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ProcessingView(stage: .parsingWithLLM)
}
