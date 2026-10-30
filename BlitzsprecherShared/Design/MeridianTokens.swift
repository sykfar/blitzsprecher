import SwiftUI
import AppKit

/// Meridian — Design-System aus Interview Studio.
///
/// Fraunces für das Vorgelesene und Überschriften, Public Sans für die Bedienung,
/// IBM Plex Mono für Belege und Pfade. Paper + Fathom + Sienna als Flächen,
/// Lesen-Blau und Signal-Orange.
///
/// Farben als Direktwerte: so läuft das Grundgerüst ohne Asset-Katalog durch.
/// Wenn die App wächst, wandern die Werte in `Assets.xcassets` und bekommen
/// dort ihre Dark-Mode-Spiegelung sauber.
public enum Meridian {

    public enum Palette {
        public static let paper      = adaptive(light: rgb(0.949, 0.937, 0.902), dark: rgb(0.051, 0.090, 0.078))
        public static let paper2     = adaptive(light: rgb(0.910, 0.890, 0.835), dark: rgb(0.078, 0.125, 0.098))
        public static let card       = adaptive(light: rgb(0.984, 0.976, 0.953), dark: rgb(0.086, 0.137, 0.118))
        public static let ink        = adaptive(light: rgb(0.118, 0.169, 0.153), dark: rgb(0.918, 0.902, 0.847))
        public static let ink2       = adaptive(light: rgb(0.365, 0.408, 0.384), dark: rgb(0.576, 0.627, 0.600))
        public static let ink3      = adaptive(light: rgb(0.545, 0.580, 0.553), dark: rgb(0.400, 0.451, 0.424))
        public static let line       = adaptive(light: rgb(0.851, 0.827, 0.765), dark: rgb(0.141, 0.192, 0.161))
        public static let lineStrong = adaptive(light: rgb(0.765, 0.737, 0.659), dark: rgb(0.204, 0.263, 0.231))
        public static let fathom     = adaptive(light: rgb(0.118, 0.353, 0.471), dark: rgb(0.435, 0.702, 0.824))
        public static let sienna     = adaptive(light: rgb(0.753, 0.357, 0.200), dark: rgb(0.878, 0.533, 0.361))
        public static let onFathom   = adaptive(light: rgb(0.984, 0.976, 0.953), dark: rgb(0.051, 0.090, 0.078))
        public static let ok         = adaptive(light: rgb(0.247, 0.490, 0.278), dark: rgb(0.498, 0.749, 0.541))
        public static let warn       = adaptive(light: rgb(0.659, 0.416, 0.082), dark: rgb(0.851, 0.643, 0.255))
        public static let risk       = adaptive(light: rgb(0.659, 0.227, 0.220), dark: rgb(0.878, 0.478, 0.416))
    }

    /// Typografie. Die Meridian-Schriften (Serif, Sans, Mono) sind OFL-Derivate
    /// aus `picturefish-meridian-fonts` und werden lokal im App-Bundle unter
    /// `Resources/Fonts/` ausgeliefert; `ATSApplicationFontsPath` im `Info.plist`
    /// registriert sie beim Start. Fallbacks: System-Serif, SF Pro, SF Mono.
    public enum Typo {
        public static func serif(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
            .custom("MeridianSerif-\(weight.ps)", size: size, relativeTo: .body)
        }

        public static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .custom("MeridianSans-\(weight.ps)", size: size, relativeTo: .body)
        }

        public static func mono(_ size: CGFloat) -> Font {
            .custom("MeridianMono-Regular", size: size, relativeTo: .body)
        }
    }

    public enum Radius {
        public static let s: CGFloat = 6
        public static let m: CGFloat = 10
        public static let l: CGFloat = 14
    }

    public enum Space {
        public static let xs: CGFloat = 4
        public static let s:  CGFloat = 8
        public static let m:  CGFloat = 12
        public static let l:  CGFloat = 18
        public static let xl: CGFloat = 28
    }
}

private func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(red: r, green: g, blue: b, alpha: a)
}

private func adaptive(light: NSColor, dark: NSColor) -> Color {
    Color(nsColor: NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
        return isDark ? dark : light
    })
}

private extension Font.Weight {
    /// Meridian liefert Regular, Medium und SemiBold aus. Jeder andere Weight
    /// wird auf Regular gemappt, damit `.custom` nicht ins Leere greift.
    var ps: String {
        switch self {
        case .medium:   "Medium"
        case .semibold: "SemiBold"
        default:        "Regular"
        }
    }
}
