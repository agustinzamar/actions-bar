import SwiftUI

/// A single row styled like a native macOS menu item: leading icon, title,
/// trailing shortcut hint, with hover highlight.
struct MenuRow: View {
    let icon: String
    let title: String
    var shortcutLabel: String?
    var keyboardShortcut: KeyboardShortcut?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Group {
            if let keyboardShortcut {
                button.keyboardShortcut(keyboardShortcut)
            } else {
                button
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
                if let shortcutLabel {
                    Text(shortcutLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(isHovering ? Color.accentColor.opacity(0.15) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }
}
