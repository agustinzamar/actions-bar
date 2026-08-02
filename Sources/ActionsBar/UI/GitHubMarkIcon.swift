import AppKit
import SwiftUI

/// The official GitHub mark, bundled as a resource. Falls back to an SF Symbol if missing.
struct GitHubMarkIcon: View {
    var size: CGFloat = 32

    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }

    private var image: Image {
        if let url = Bundle.module.url(forResource: "GitHubMark", withExtension: "png"),
           let nsImage = NSImage(contentsOf: url)
        {
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "chart.bar.fill")
    }
}
