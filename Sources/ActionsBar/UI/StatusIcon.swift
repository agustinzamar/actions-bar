import SwiftUI

struct StatusIcon: View {
    let status: RunStatus

    var body: some View {
        Image(systemName: symbolName)
            .foregroundStyle(tint)
    }

    private var symbolName: String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failure: return "xmark.circle.fill"
        case .inProgress: return "circle.dotted"
        case .cancelled: return "minus.circle.fill"
        case .unknown: return "circle"
        }
    }

    private var tint: Color {
        switch status {
        case .success: return .green
        case .failure: return .red
        case .inProgress: return .yellow
        case .cancelled: return .gray
        case .unknown: return .secondary
        }
    }
}
