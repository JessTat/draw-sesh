import SwiftUI
import AppKit

struct ThinScrollViewConfigurator: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    NSView()
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    DispatchQueue.main.async {
      guard let scrollView = nsView.enclosingScrollView else { return }
      scrollView.scrollerStyle = .overlay
      scrollView.verticalScroller?.controlSize = .mini
      scrollView.horizontalScroller?.controlSize = .mini
    }
  }
}

extension View {
  func thinScrollIndicators() -> some View {
    background(ThinScrollViewConfigurator().allowsHitTesting(false))
  }
}
