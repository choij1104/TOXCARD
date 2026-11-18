import SwiftUI
import UIKit

extension Color {
    /// A colour that follows light and dark mode.
    init(light: UInt32, dark: UInt32) {
        self = Color(UIColor { trait in
            let v = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255,
                           green: CGFloat((v >> 8) & 0xFF) / 255,
                           blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        })
    }
}

/// TOXCARD colour system (carried over from the 1.1 iPhone interface).
enum Palette {
    static let ground   = Color(light: 0xEFF0ED, dark: 0x0A0B0B)
    static let surface  = Color(light: 0xFFFFFF, dark: 0x17191A)
    static let surface2 = Color(light: 0xF6F7F5, dark: 0x202324)
    static let ink      = Color(light: 0x0F1312, dark: 0xF2F4F3)
    static let mut      = Color(light: 0x5B6461, dark: 0xA3ACA9)
    static let dim      = Color(light: 0x7D8683, dark: 0x7C8582)
    static let acc      = Color(light: 0x0A7A55, dark: 0x3FD39A)
    static let accSoft  = Color(light: 0xDCEFE6, dark: 0x0F3427)
    static let sig      = Color(light: 0xC7361E, dark: 0xFF6B56)
    static let sigSoft  = Color(light: 0xFBE6E0, dark: 0x3A1812)
    static let amber    = Color(light: 0x975900, dark: 0xF0B354)
    static let amberSoft = Color(light: 0xF7EAD2, dark: 0x33260F)
    static let fill     = Color(light: 0xE4E6E3, dark: 0x2A2E2F)
    static let onTab    = Color(light: 0xFFFFFF, dark: 0x0A0B0B)

    static func tier(_ t: String) -> Color {
        switch t {
        case "A": return Color(light: 0x0A7A55, dark: 0x3FD39A)
        case "B": return Color(light: 0x2E64A0, dark: 0x7BAEEA)
        case "C": return Color(light: 0x975900, dark: 0xF0B354)
        case "D": return Color(light: 0x69707A, dark: 0x9AA2A8)
        default:  return Color(light: 0x8A9095, dark: 0x7F878C)
        }
    }
}

/// The index-card tab: the tier letter on the card's edge, with a white rule near the foot.
struct TierTab: View {
    let tier: String
    var large = false
    var body: some View {
        let w: CGFloat = large ? 44 : 30, h: CGFloat = large ? 50 : 34
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: large ? 9 : 7, bottomLeadingRadius: large ? 4 : 3,
                                   bottomTrailingRadius: large ? 4 : 3, topTrailingRadius: large ? 9 : 7)
                .fill(Palette.tier(tier))
            Text(tier == "N" ? "–" : tier)
                .font(.system(size: large ? 21 : 14, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.onTab)
                .padding(.top, large ? 9 : 5)
            VStack { Spacer(); Capsule().fill(Palette.onTab.opacity(0.55)).frame(height: 2).padding(.horizontal, 5).padding(.bottom, 5) }
        }
        .frame(width: w, height: h)
        .accessibilityElement()
        .accessibilityLabel(tier == "N" ? "Supportive care" : "Tier \(tier)")
    }
}

/// A rounded white card on the grey ground, with an optional coloured edge.
struct Panel<Content: View>: View {
    var top: Color? = nil
    var leading: Color? = nil
    var background: Color = Palette.surface
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 14)
            .padding(.leading, leading == nil ? 0 : 4)
            .background(background)
            .overlay(alignment: .leading) { if let l = leading { Rectangle().fill(l).frame(width: 4) } }
            .overlay(alignment: .top) { if let t = top { Rectangle().fill(t).frame(height: 6) } }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct PanelLabel: View {
    let text: String
    var color: Color = Palette.mut
    var body: some View {
        Text(text.uppercased()).font(.system(size: 12.5, weight: .semibold)).tracking(0.8).foregroundStyle(color)
    }
}

struct Pill: View {
    let text: String
    var fg: Color = Palette.ink
    var bg: Color = Palette.fill
    var body: some View {
        Text(text).font(.system(size: 12.5, weight: .semibold))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .foregroundStyle(fg).background(bg, in: Capsule())
    }
}

/// The ECG trace from the TOXCARD book cover.
struct ECGLine: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let y = r.midY, w = r.width, h = r.height
        let pts: [(CGFloat, CGFloat)] = [
            (0, y), (0.20, y), (0.23, y), (0.25, y - h * 0.40), (0.27, y + h * 0.45), (0.29, y - h * 0.50), (0.31, y),
            (0.55, y), (0.58, y), (0.60, y - h * 0.35), (0.62, y + h * 0.40), (0.64, y - h * 0.48), (0.66, y), (1, y),
        ]
        p.move(to: CGPoint(x: 0, y: y))
        for (x, yy) in pts { p.addLine(to: CGPoint(x: x * w, y: yy)) }
        return p
    }
}

struct PoisonCenterButton: View {
    var body: some View {
        Link(destination: URL(string: "tel://18002221222")!) {
            Label("Call Poison Control  1-800-222-1222", systemImage: "phone.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Palette.sig, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityHint("Calls the US poison center line")
    }
}
