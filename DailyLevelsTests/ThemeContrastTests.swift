import SwiftUI
import XCTest
@testable import DailyLevels

final class ThemeContrastTests: XCTestCase {
    func testPrimaryAndSecondaryTextMeetNormalTextContrast() {
        XCTAssertGreaterThanOrEqual(contrastRatio(Theme.ink, Theme.cream), 4.5)
        XCTAssertGreaterThanOrEqual(contrastRatio(Theme.gray, Theme.cream), 4.5)
        XCTAssertGreaterThanOrEqual(contrastRatio(Theme.gray, Theme.card), 4.5)
    }

    func testGreenStatusTextMeetsNormalTextContrast() {
        XCTAssertGreaterThanOrEqual(contrastRatio(Theme.greenDeep, Theme.cream), 4.5)
        XCTAssertGreaterThanOrEqual(contrastRatio(Theme.greenDeep, Theme.card), 4.5)
    }

    func testLargeWhiteButtonTextMeetsLargeTextContrast() {
        XCTAssertGreaterThanOrEqual(contrastRatio(.white, Theme.green), 3.0)
    }

    private func contrastRatio(_ foreground: Color, _ background: Color) -> Double {
        let foregroundLuminance = relativeLuminance(foreground)
        let backgroundLuminance = relativeLuminance(background)
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: Color) -> Double {
        let resolved = UIColor(color).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light)
        )
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            XCTFail("Theme color must resolve to RGB")
            return 0
        }

        func linear(_ component: CGFloat) -> Double {
            let value = Double(component)
            return value <= 0.04045
                ? value / 12.92
                : pow((value + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
