import SwiftUI

/// A palette that paints every `PlayerColor` slot and the table behind the
/// panels. A player's slot sticks across themes; the theme decides what that
/// slot looks like and what it's called — the slot `.red` is "Hot Pink" in
/// Synthwave and "Vermilion" in Woodblock. Each theme keeps its nine colors far
/// enough apart to tell seats apart, and gives the default seats (red, blue,
/// green, white, black, purple) its most distinct colors.
enum ColorTheme: String, CaseIterable, Codable, Identifiable {
    case classic, synthwave, woodblock, autumnForest, tropical, desertBloom, ember, arcade, bauhaus

    var id: String { rawValue }

    var label: String {
        switch self {
        case .classic:      "Classic"
        case .synthwave:    "Synthwave"
        case .woodblock:    "Woodblock"
        case .autumnForest: "Autumn Forest"
        case .tropical:     "Tropical"
        case .desertBloom:  "Desert Bloom"
        case .ember:        "Ember"
        case .arcade:       "Arcade"
        case .bauhaus:      "Bauhaus"
        }
    }

    var summary: String {
        switch self {
        case .classic:      "Bold, flat colors"
        case .synthwave:    "Neon grid, sunset over chrome"
        case .woodblock:    "Ukiyo-e print: indigo, vermilion, washi paper"
        case .autumnForest: "Maple, birch, pine, and a cold lake"
        case .tropical:     "Hibiscus, mango, lagoon"
        case .desertBloom:  "Adobe, agave, and cactus flowers at dusk"
        case .ember:        "Lava and ash with cool smoke"
        case .arcade:       "The 8-bit console palette"
        case .bauhaus:      "Primary shapes on a paper-white table"
        }
    }

    /// What a slot is called and its resting shade in this theme.
    func swatch(_ color: PlayerColor) -> Swatch {
        switch self {
        case .classic:
            let name = color.rawValue.capitalized
            return switch color {
            case .white:  Swatch(name, HSB(0.12, 0.10, 0.85))
            case .blue:   Swatch(name, HSB(0.60, 0.80, 0.60))
            case .black:  Swatch(name, HSB(0.72, 0.15, 0.22))
            case .red:    Swatch(name, HSB(0.00, 0.80, 0.62))
            case .green:  Swatch(name, HSB(0.36, 0.75, 0.48))
            case .orange: Swatch(name, HSB(0.07, 0.85, 0.75))
            case .purple: Swatch(name, HSB(0.78, 0.65, 0.55))
            case .teal:   Swatch(name, HSB(0.50, 0.75, 0.52))
            case .pink:   Swatch(name, HSB(0.92, 0.60, 0.70))
            }
        case .synthwave:
            return switch color {
            case .white:  Swatch("Chrome", 0xF1F1F6)
            case .blue:   Swatch("Cyan", 0x2DE2E6)
            case .black:  Swatch("Plum Night", 0x3A1A5E)
            case .red:    Swatch("Hot Pink", 0xFF2E97)
            case .green:  Swatch("Sunset", 0xFF8C42)
            case .orange: Swatch("Laser Lime", 0x00F5A0)
            case .purple: Swatch("Violet", 0x9D4EDD)
            case .teal:   Swatch("Indigo", 0x3D5AFE)
            case .pink:   Swatch("Sun", 0xFFE066)
            }
        case .woodblock:
            return switch color {
            case .white:  Swatch("Washi", 0xE8D3A7)
            case .blue:   Swatch("Indigo", 0x2C5A8A)
            case .black:  Swatch("Sumi", 0x2B2B2B)
            case .red:    Swatch("Vermilion", 0xD9481C)
            case .green:  Swatch("Pine", 0x3B6E52)
            case .orange: Swatch("Ochre", 0xE3B448)
            case .purple: Swatch("Murasaki", 0x6C4675)
            case .teal:   Swatch("Celadon", 0xA3C4BC)
            case .pink:   Swatch("Sakura", 0xE7A0B0)
            }
        case .autumnForest:
            return switch color {
            case .white:  Swatch("Birch", 0xF2E8CF)
            case .blue:   Swatch("Lake", 0x3D5A80)
            case .black:  Swatch("Bark", 0x7A5C3C)
            case .red:    Swatch("Rust", 0xC8553D)
            case .green:  Swatch("Pine", 0x386641)
            case .orange: Swatch("Maple Gold", 0xE3A857)
            case .purple: Swatch("Heather", 0x8E7DBE)
            case .teal:   Swatch("Lichen", 0xA7C957)
            case .pink:   Swatch("Wine", 0x6B2737)
            }
        case .tropical:
            return switch color {
            case .white:  Swatch("Coconut", 0xFFF3E2)
            case .blue:   Swatch("Lagoon", 0x4D96FF)
            case .black:  Swatch("Night", 0x2E4057)
            case .red:    Swatch("Hibiscus", 0xFF6B6B)
            case .green:  Swatch("Palm", 0x6BCB77)
            case .orange: Swatch("Mango", 0xFFD93D)
            case .purple: Swatch("Orchid", 0x9B5DE5)
            case .teal:   Swatch("Turquoise", 0x00C2A8)
            case .pink:   Swatch("Papaya", 0xFF9F1C)
            }
        case .desertBloom:
            return switch color {
            case .white:  Swatch("Bone", 0xF4E3C9)
            case .blue:   Swatch("Dusk", 0x264653)
            case .black:  Swatch("Oxide", 0x7B2D26)
            case .red:    Swatch("Clay Rose", 0xC1666B)
            case .green:  Swatch("Agave", 0x2A9D8F)
            case .orange: Swatch("Saffron", 0xE9C46A)
            case .purple: Swatch("Cactus Flower", 0xD16BA5)
            case .teal:   Swatch("Sand", 0xD4A373)
            case .pink:   Swatch("Adobe", 0x9C6644)
            }
        case .ember:
            return switch color {
            case .white:  Swatch("Ash", 0x9BA4B4)
            case .blue:   Swatch("Smoke", 0x3E5C76)
            case .black:  Swatch("Obsidian", 0x3A2A2A)
            case .red:    Swatch("Lava", 0xFF5A1F)
            case .green:  Swatch("Ember", 0xFFB627)
            case .orange: Swatch("Crimson", 0xD7263D)
            case .purple: Swatch("Rhodochrosite", 0xC97B84)
            case .teal:   Swatch("Flame Tip", 0xFFE8A3)
            case .pink:   Swatch("Magma", 0x8A1C1C)
            }
        case .arcade:
            return switch color {
            case .white:  Swatch("White", 0xFCFCFC)
            case .blue:   Swatch("Blue", 0x0078F8)
            case .black:  Swatch("Brown", 0xAC7C00)
            case .red:    Swatch("Red", 0xF83800)
            case .green:  Swatch("Green", 0x00A800)
            case .orange: Swatch("Gold", 0xF8B800)
            case .purple: Swatch("Purple", 0x6844FC)
            case .teal:   Swatch("Sky", 0x3CBCFC)
            case .pink:   Swatch("Pink", 0xE40058)
            }
        case .bauhaus:
            // No white: the table itself is paper white.
            return switch color {
            case .white:  Swatch("Black", 0x1A1A1A)
            case .blue:   Swatch("Blue", 0x1B4DE4)
            case .black:  Swatch("Green", 0x2E8B57)
            case .red:    Swatch("Red", 0xD7263D)
            case .green:  Swatch("Yellow", 0xF5C200)
            case .orange: Swatch("Orange", 0xF28C28)
            case .purple: Swatch("Violet", 0x8E44AD)
            case .teal:   Swatch("Sky", 0x5BC0EB)
            case .pink:   Swatch("Grey", 0x7D7D7D)
            }
        }
    }

    /// The table behind the panels.
    var backdrop: Color {
        switch self {
        case .classic:      .black
        case .synthwave:    HSB(hex: 0x0D0221).color
        case .woodblock:    HSB(hex: 0x16161A).color
        case .autumnForest: HSB(hex: 0x14100C).color
        case .tropical:     HSB(hex: 0x10141C).color
        case .desertBloom:  HSB(hex: 0x1E140F).color
        case .ember:        HSB(hex: 0x120A08).color
        case .arcade:       HSB(hex: 0x0A0A0A).color
        case .bauhaus:      HSB(hex: 0xE9E4D8).color
        }
    }

    /// The panel fill: the resting shade, or the brighter "lit" shade used
    /// while the starter roulette light is under the panel or the player has
    /// just been chosen to go first.
    func fill(_ color: PlayerColor, lit: Bool) -> Color {
        let c = swatch(color).shade
        return lit ? c.lit.color : c.color
    }

    /// Dark text on light shades, white on everything else.
    func foreground(_ color: PlayerColor) -> Color {
        swatch(color).shade.prefersDarkForeground ? Color(white: 0.12) : .white
    }
}

/// One slot's look in a theme.
struct Swatch: Equatable {
    let name: String
    let shade: HSB

    init(_ name: String, _ shade: HSB) {
        self.name = name
        self.shade = shade
    }

    init(_ name: String, _ hex: Int) {
        self.init(name, HSB(hex: hex))
    }
}

/// A color as hue, saturation, and brightness, each 0...1.
struct HSB: Equatable {
    var h: Double
    var s: Double
    var b: Double

    init(_ h: Double, _ s: Double, _ b: Double) {
        self.h = h
        self.s = s
        self.b = b
    }

    /// From a 0xRRGGBB sRGB value.
    init(hex: Int) {
        let r = Double(hex >> 16 & 0xFF) / 255
        let g = Double(hex >> 8 & 0xFF) / 255
        let bl = Double(hex & 0xFF) / 255
        let maxC = max(r, g, bl), delta = maxC - min(r, g, bl)
        var hue = 0.0
        if delta > 0 {
            switch maxC {
            case r: hue = ((g - bl) / delta).truncatingRemainder(dividingBy: 6)
            case g: hue = (bl - r) / delta + 2
            default: hue = (r - g) / delta + 4
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }
        self.init(hue, maxC == 0 ? 0 : delta / maxC, maxC)
    }

    var color: Color { Color(hue: h, saturation: s, brightness: b) }

    /// Paler and brighter, for a panel under the roulette light.
    var lit: HSB { HSB(h, max(s - 0.25, 0.05), min(b + 0.35, 1)) }

    /// WCAG relative luminance.
    var luminance: Double {
        let (r, g, b) = rgb
        func linear(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// True when dark text contrasts better than white against this shade.
    var prefersDarkForeground: Bool {
        let dark = HSB(0, 0, 0.12).luminance
        let contrastWithWhite = 1.05 / (luminance + 0.05)
        let contrastWithDark = (luminance + 0.05) / (dark + 0.05)
        return contrastWithDark > contrastWithWhite
    }

    var rgb: (Double, Double, Double) {
        let sector = (h - floor(h)) * 6
        let f = sector - floor(sector)
        let p = b * (1 - s)
        let q = b * (1 - s * f)
        let t = b * (1 - s * (1 - f))
        switch Int(sector) {
        case 0: return (b, t, p)
        case 1: return (q, b, p)
        case 2: return (p, b, t)
        case 3: return (p, q, b)
        case 4: return (t, p, b)
        default: return (b, p, q)
        }
    }
}

extension EnvironmentValues {
    @Entry var colorTheme: ColorTheme = .classic
}
