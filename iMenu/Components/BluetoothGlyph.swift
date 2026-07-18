//
//  BluetoothGlyph.swift
//  iMenu
//
//  Created by Yusuf Demirci on 18.07.2026.
//

import SwiftUI

/// The Bluetooth rune, drawn as a vector.
///
/// SF Symbols ships no Bluetooth glyph (Apple omits it for trademark reasons), so
/// the one system menu bar item we can't represent with `Image(systemName:)` gets
/// this hand-drawn stand-in instead. It strokes with the current foreground style,
/// so callers tint it with `.foregroundStyle(...)` exactly like an SF Symbol.
struct BluetoothGlyph: View {
    var body: some View {
        BluetoothShape()
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }
}

/// The Bluetooth rune as a `Shape`: a vertical spine crossed by two chevrons that
/// meet at the top and bottom tips. Point geometry follows the widely used
/// 24×24 reference, scaled to fit (with a little inset so the tall, narrow rune
/// optically matches the SF Symbols beside it) and centered in `rect`.
struct BluetoothShape: Shape {
    func path(in rect: CGRect) -> Path {
        // Rune vertices in a 24×24 reference box, traced as one polyline.
        let points: [CGPoint] = [
            CGPoint(x: 6.5, y: 6.5),
            CGPoint(x: 17.5, y: 17.5),
            CGPoint(x: 12, y: 23),
            CGPoint(x: 12, y: 1),
            CGPoint(x: 17.5, y: 6.5),
            CGPoint(x: 6.5, y: 17.5),
        ]
        // Reference slightly larger than the 24 box so the near-full-height rune
        // doesn't tower over its neighbors; center on the glyph's bounding box.
        let reference: CGFloat = 26
        let center = CGPoint(x: 12, y: 12)
        let scale = min(rect.width, rect.height) / reference

        func map(_ point: CGPoint) -> CGPoint {
            CGPoint(x: rect.midX + (point.x - center.x) * scale,
                    y: rect.midY + (point.y - center.y) * scale)
        }

        var path = Path()
        path.move(to: map(points[0]))
        for point in points.dropFirst() {
            path.addLine(to: map(point))
        }
        return path
    }
}

#Preview {
    HStack(spacing: 16) {
        BluetoothGlyph()
            .frame(width: 22, height: 22)
            .foregroundStyle(.primary)
        BluetoothGlyph()
            .frame(width: 44, height: 44)
            .foregroundStyle(.blue)
    }
    .padding()
}
