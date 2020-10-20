import UIKit

extension UIView {
    func setAccessibilityLabelInSpanish(_ label: String, region: String = Current.settings.region.accent) {
        setAccessibilityLabel(label, spokenInLanguage: "es_\(region)")
    }
    
    private func setAccessibilityLabel(_ label: String, spokenInLanguage languageCode: String) {
        let attributes: [NSAttributedString.Key : Any] = [
            .accessibilitySpeechLanguage: languageCode,
        ]
        let attributedLabel = NSAttributedString(string: label, attributes: attributes)
        accessibilityAttributedLabel = attributedLabel
    }
}
