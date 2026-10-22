import Testing
@testable import Sparkwarden

struct ColorThemeTests {
    /// Panels are told apart by color alone, so no two colors in a theme may
    /// sit too close together in RGB.
    @Test(arguments: ColorTheme.allCases)
    func colorsStayDistinguishable(theme: ColorTheme) {
        for (i, a) in PlayerColor.allCases.enumerated() {
            for b in PlayerColor.allCases.dropFirst(i + 1) {
                let (r1, g1, b1) = theme.swatch(a).shade.rgb
                let (r2, g2, b2) = theme.swatch(b).shade.rgb
                let distance = ((r1 - r2) * (r1 - r2) + (g1 - g2) * (g1 - g2) + (b1 - b2) * (b1 - b2)).squareRoot()
                #expect(distance > 0.15, "\(theme) \(theme.swatch(a).name) and \(theme.swatch(b).name) are too close")
            }
        }
    }

    @Test(arguments: ColorTheme.allCases)
    func colorNamesAreUniqueWithinATheme(theme: ColorTheme) {
        let names = PlayerColor.allCases.map { theme.swatch($0).name }
        #expect(Set(names).count == names.count)
    }

    @Test func classicUsesDarkTextOnlyOnWhite() {
        let dark = PlayerColor.allCases.filter { ColorTheme.classic.swatch($0).shade.prefersDarkForeground }
        #expect(dark == [.white])
    }

    @Test func darkTextOnLightShadesWhiteOnDark() {
        #expect(HSB(0, 0, 1).prefersDarkForeground)
        #expect(!HSB(0, 0, 0).prefersDarkForeground)
    }

    @Test func litShadeIsBrighterAndPaler() {
        let shade = ColorTheme.woodblock.swatch(.red).shade
        #expect(shade.lit.b > shade.b)
        #expect(shade.lit.s < shade.s)
        #expect(shade.lit.h == shade.h)
    }

    @Test func hsbConvertsPrimariesToRGB() {
        #expect(HSB(0, 1, 1).rgb == (1, 0, 0))
        #expect(HSB(1.0 / 3, 1, 1).rgb == (0, 1, 0))
        #expect(HSB(2.0 / 3, 1, 1).rgb == (0, 0, 1))
    }

    @Test(arguments: [0xFF0000, 0x00FF00, 0x0000FF, 0xD9481C, 0x2E4057, 0xFFFFFF, 0x000000])
    func hexRoundTripsThroughHSB(hex: Int) {
        let (r, g, b) = HSB(hex: hex).rgb
        let back = Int((r * 255).rounded()) << 16 | Int((g * 255).rounded()) << 8 | Int((b * 255).rounded())
        #expect(back == hex)
    }
}
