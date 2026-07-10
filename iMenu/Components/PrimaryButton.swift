//
//  PrimaryButton.swift
//  iMenu
//
//  Created by Yusuf Demirci on 10.07.2026.
//

import SwiftUI

/// The app's primary call-to-action button.
///
/// Centralizing the styling here keeps every prominent action visually
/// consistent and means restyling happens in exactly one place.
struct PrimaryButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

#Preview {
    PrimaryButton("Refresh", systemImage: "arrow.clockwise") {}
        .padding()
        .frame(width: 220)
}
