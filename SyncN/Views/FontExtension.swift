import SwiftUI

extension Font {
    static func sofiaPro(size: CGFloat, weight: Font.Weight = .regular, isItalic: Bool = false) -> Font {
        let baseName: String
        switch weight {
        case .ultraLight:
            baseName = "SofiaPro-UltraLight"
        case .thin:
            baseName = "SofiaPro-Thin"
        case .light:
            baseName = "SofiaPro-Light"
        case .regular:
            baseName = "SofiaPro-Regular"
        case .medium:
            baseName = "SofiaPro-Medium"
        case .semibold:
            baseName = "SofiaPro-SemiBold"
        case .bold:
            baseName = "SofiaPro-Bold"
        case .heavy:
            baseName = "SofiaPro-Black"
        default:
            baseName = "SofiaPro-Regular"
        }
        
        let fontName = isItalic ? "\(baseName)Italic" : baseName
        return Font.custom(fontName, size: size)
    }
    
    // Convenience methods for common font sizes
    static let sofiaProLargeTitle = Font.sofiaPro(size: 34, weight: .bold)
    static let sofiaProTitle = Font.sofiaPro(size: 28, weight: .bold)
    static let sofiaProTitle2 = Font.sofiaPro(size: 22, weight: .semibold)
    static let sofiaProTitle3 = Font.sofiaPro(size: 20, weight: .semibold)
    static let sofiaProHeadline = Font.sofiaPro(size: 17, weight: .semibold)
    static let sofiaProBody = Font.sofiaPro(size: 17, weight: .regular)
    static let sofiaProCallout = Font.sofiaPro(size: 16, weight: .regular)
    static let sofiaProSubheadline = Font.sofiaPro(size: 15, weight: .regular)
    static let sofiaProFootnote = Font.sofiaPro(size: 13, weight: .regular)
    static let sofiaProCaption = Font.sofiaPro(size: 12, weight: .regular)
    static let sofiaProCaption2 = Font.sofiaPro(size: 11, weight: .regular)
}
