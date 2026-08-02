import SwiftUI

struct StatusIcon: View {
    let status: RunStatus

    var body: some View {
        Image(systemName: symbolName)
            .foregroundStyle(tint)
    }

    private var symbolName: String {
        switch status {
        case .success: "checkmark.circle.fill"
        case .failure: "xmark.circle.fill"
        case .inProgress: "circle.dotted"
        case .cancelled: "minus.circle.fill"
        case .unknown: "circle"
        }
    }

    private var tint: Color {
        switch status {
        case .success: .green
        case .failure: .red
        case .inProgress: .yellow
        case .cancelled: .gray
        case .unknown: .secondary
        }
    }
}
