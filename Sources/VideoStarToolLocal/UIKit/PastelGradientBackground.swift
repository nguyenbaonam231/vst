#if canImport(UIKit)
import UIKit

/// Nền pastel hồng – vàng phía sau bảng công cụ.
public final class PastelGradientBackgroundView: UIView {
    public override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradient: CAGradientLayer { layer as! CAGradientLayer }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureGradient()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureGradient()
    }

    private func configureGradient() {
        gradient.colors = [
            UIColor(red: 1.00, green: 0.78, blue: 0.86, alpha: 1).cgColor, // hồng pastel
            UIColor(red: 1.00, green: 0.93, blue: 0.72, alpha: 1).cgColor, // vàng kem
            UIColor(red: 0.98, green: 0.80, blue: 0.84, alpha: 1).cgColor  // hồng đào
        ]
        gradient.locations = [0.0, 0.55, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }
}

public extension UIViewController {
    func installVideoStarPastelBackground() {
        view.subviews
            .filter { $0 is PastelGradientBackgroundView }
            .forEach { $0.removeFromSuperview() }
        let background = PastelGradientBackgroundView(frame: view.bounds)
        background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(background, at: 0)
        view.backgroundColor = .clear
    }
}

#endif
