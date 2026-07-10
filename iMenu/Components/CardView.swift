//
//  CardView.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// A reusable rounded container that groups related content on a subtle
/// background. Generic over its content so any view can be placed inside.
///
/// ```swift
/// CardView {
///     Text("Hello")
/// }
/// ```
struct CardView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.separator, lineWidth: 1)
            )
    }
}

#Preview {
    CardView {
        Text("Card content")
    }
    .padding()
}
