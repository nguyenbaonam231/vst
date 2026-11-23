#if canImport(UIKit)
import UIKit

/// Giao diện dựng lại theo bố cục VideoStar Tool trong ảnh tham chiếu.
/// Đây là lớp giao diện; các thao tác chỉnh sửa thật phải được nối với editor bridge.
public final class VideoStarToolHomeViewController: UIViewController {
    public var onFeatureSelected: ((ToolFeature) -> Void)?
    public var onClose: (() -> Void)?

    private enum Tab: Int, CaseIterable {
        case home, functions, developer

        var title: String {
            switch self {
            case .home: return "Trang chủ"
            case .functions: return "Chức năng"
            case .developer: return "Nhà phát triển"
            }
        }
    }

    private let localAccess: FeatureAccessProviding
    private let recentCodeStore: RecentCodeStore
    private let pageStack = UIStackView()
    private var selectedTab: Tab = .home
    private var tabButtons: [UIButton] = []

    public init(
        localAccess: FeatureAccessProviding = LocalFeatureAccess(),
        recentCodeStore: RecentCodeStore = RecentCodeStore()
    ) {
        self.localAccess = localAccess
        self.recentCodeStore = recentCodeStore
        super.init(nibName: nil, bundle: nil)
    }

    /// Gọi từ callback QR hợp lệ của host app để lưu mã gần đây trên thiết bị.
    /// Hàm này không thực hiện request mạng.
    public func recordRecentCode(_ code: String) {
        recentCodeStore.record(code)
        if selectedTab == .functions {
            // Cập nhật trang nếu người dùng đang mở phần chức năng.
            showRecentCodesPageIfVisible()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) chưa được hỗ trợ")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        installVideoStarPastelBackground()
        buildPanel()
        show(tab: .home)
    }

    private func buildPanel() {
        let panel = UIView()
        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.backgroundColor = UIColor(red: 0.025, green: 0.035, blue: 0.045, alpha: 0.96)
        panel.layer.cornerRadius = 30
        panel.layer.masksToBounds = false
        panel.layer.shadowColor = UIColor(red: 0.92, green: 0.48, blue: 0.66, alpha: 1).cgColor
        panel.layer.shadowOpacity = 0.30
        panel.layer.shadowRadius = 22
        panel.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.addSubview(panel)

        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            panel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            panel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            panel.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor, constant: -34),
            panel.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
            panel.widthAnchor.constraint(greaterThanOrEqualToConstant: 280),
            panel.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.82),
            panel.heightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.92),
            panel.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            panel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])

        let border = PastelGradientBorderView()
        border.translatesAutoresizingMaskIntoConstraints = false
        border.isUserInteractionEnabled = false
        panel.addSubview(border)
        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: panel.topAnchor),
            border.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            border.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        ])

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        panel.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: panel.topAnchor, constant: 19),
            scroll.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            scroll.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),
            scroll.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -17)
        ])

        let content = UIStackView()
        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 16
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        content.addArrangedSubview(makeHeader())
        content.addArrangedSubview(makeDivider())
        content.addArrangedSubview(makeTabs())

        pageStack.axis = .vertical
        pageStack.alignment = .fill
        pageStack.spacing = 15
        content.addArrangedSubview(pageStack)

        content.addArrangedSubview(makeDivider())
        content.addArrangedSubview(makeFooter())
    }

    private func makeHeader() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10

        let star = UIImageView(image: UIImage(systemName: "star.fill"))
        star.translatesAutoresizingMaskIntoConstraints = false
        star.tintColor = UIColor(red: 1.00, green: 0.73, blue: 0.83, alpha: 1)
        star.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            star.widthAnchor.constraint(equalToConstant: 38),
            star.heightAnchor.constraint(equalToConstant: 38)
        ])

        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 2

        let title = makePaytoneLabel("VideoStar Tool", size: 25, color: UIColor(red: 1.00, green: 0.78, blue: 0.82, alpha: 1))
        let author = makePaytoneLabel("Tạo bởi: j4avzckcy", size: 12, color: UIColor(red: 1.00, green: 0.88, blue: 0.66, alpha: 1))
        titleStack.addArrangedSubview(title)
        titleStack.addArrangedSubview(author)

        let close = UIButton(type: .system)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        close.tintColor = UIColor(red: 1.00, green: 0.84, blue: 0.87, alpha: 1)
        close.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if let onClose = self.onClose { onClose() } else { self.dismiss(animated: true) }
        }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            close.widthAnchor.constraint(equalToConstant: 34),
            close.heightAnchor.constraint(equalToConstant: 34)
        ])

        row.addArrangedSubview(star)
        row.addArrangedSubview(titleStack)
        row.addArrangedSubview(close)
        row.setCustomSpacing(8, after: star)
        return row
    }

    private func makeTabs() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 8
        tabButtons = Tab.allCases.map { tab in
            let button = UIButton(type: .system)
            button.setTitle(tab.title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.numberOfLines = 2
            button.contentHorizontalAlignment = .center
            button.contentVerticalAlignment = .center
            button.layer.cornerRadius = 15
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
            button.backgroundColor = UIColor.white.withAlphaComponent(0.035)
            button.tintColor = .white
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            button.addAction(UIAction { [weak self] _ in self?.show(tab: tab) }, for: .touchUpInside)
            row.addArrangedSubview(button)
            return button
        }
        return row
    }

    private func show(tab: Tab) {
        selectedTab = tab
        for (index, button) in tabButtons.enumerated() {
            let active = Tab.allCases[index] == tab
            button.backgroundColor = active
                ? UIColor(red: 0.96, green: 0.69, blue: 0.78, alpha: 0.20)
                : UIColor.white.withAlphaComponent(0.035)
            button.layer.borderColor = (active
                ? UIColor(red: 1.00, green: 0.78, blue: 0.64, alpha: 0.95)
                : UIColor.white.withAlphaComponent(0.14)).cgColor
            button.setTitleColor(active
                ? UIColor(red: 1.00, green: 0.84, blue: 0.77, alpha: 1)
                : UIColor(red: 0.88, green: 0.87, blue: 0.90, alpha: 1), for: .normal)
        }

        pageStack.arrangedSubviews.forEach { view in
            pageStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        switch tab {
        case .home:
            pageStack.addArrangedSubview(makeHomePage())
        case .functions:
            pageStack.addArrangedSubview(makeFunctionsPage())
        case .developer:
            pageStack.addArrangedSubview(makeDeveloperPage())
        }
    }

    private func makeHomePage() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 17
        stack.addArrangedSubview(makePaytoneLabel("Xin chào!", size: 29, color: .white))
        stack.addArrangedSubview(makeBodyLabel(
            "Đây là VideoStar Tool, công cụ giúp bạn sử dụng VideoStar thuận tiện, nhanh chóng và dễ dàng hơn.",
            size: 16,
            color: UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1)
        ))
        let hint = makeBodyLabel("Chọn mục Chức năng để mở các công cụ của bạn.", size: 13,
                                  color: UIColor(red: 1.00, green: 0.85, blue: 0.72, alpha: 1))
        stack.addArrangedSubview(hint)
        return stack
    }

    private func makeFunctionsPage() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.addArrangedSubview(makePaytoneLabel("Chức năng", size: 24, color: .white))
        stack.addArrangedSubview(makeBodyLabel("Chọn công cụ muốn sử dụng.", size: 14,
                                               color: UIColor(white: 0.86, alpha: 1)))

        let enabled = ToolFeature.allCases.filter { localAccess.isEnabled($0) }
        for pairStart in stride(from: 0, to: enabled.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .fill
            row.distribution = .fillEqually
            row.spacing = 10
            row.addArrangedSubview(makeFeatureButton(for: enabled[pairStart]))
            if pairStart + 1 < enabled.count {
                row.addArrangedSubview(makeFeatureButton(for: enabled[pairStart + 1]))
            } else {
                let spacer = UIView()
                row.addArrangedSubview(spacer)
            }
            stack.addArrangedSubview(row)
        }
        return stack
    }

    private func makeRecentCodesPage() -> UIView {
        let stack = UIStackView()
        stack.accessibilityIdentifier = "recent-codes-page"
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.addArrangedSubview(makePaytoneLabel("Mã đã dùng gần đây", size: 23, color: .white))
        stack.addArrangedSubview(makeBodyLabel(
            "Danh sách được lưu trực tiếp trên thiết bị.", size: 13,
            color: UIColor(white: 0.86, alpha: 1)
        ))

        let entries = recentCodeStore.entries()
        if entries.isEmpty {
            stack.addArrangedSubview(makeBodyLabel(
                "Chưa có mã nào được lưu.", size: 14,
                color: UIColor(red: 1.00, green: 0.85, blue: 0.76, alpha: 1)
            ))
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "vi_VN")
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            for entry in entries {
                let row = UIButton(type: .system)
                row.setTitle(entry.code, for: .normal)
                row.setTitleColor(UIColor(red: 1.00, green: 0.91, blue: 0.88, alpha: 1), for: .normal)
                row.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
                row.titleLabel?.textAlignment = .center
                row.titleLabel?.numberOfLines = 0
                row.contentHorizontalAlignment = .center
                row.contentVerticalAlignment = .center
                row.backgroundColor = UIColor.white.withAlphaComponent(0.055)
                row.layer.cornerRadius = 13
                row.layer.borderWidth = 1
                row.layer.borderColor = UIColor(red: 0.96, green: 0.72, blue: 0.72, alpha: 0.48).cgColor
                row.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
                row.accessibilityHint = "Chạm để sao chép mã"
                row.addAction(UIAction { _ in UIPasteboard.general.string = entry.code }, for: .touchUpInside)
                stack.addArrangedSubview(row)
                stack.addArrangedSubview(makeBodyLabel(
                    "Đã lưu: \(formatter.string(from: entry.savedAt))", size: 10,
                    color: UIColor(white: 0.68, alpha: 1)
                ))
            }
        }

        let clear = UIButton(type: .system)
        clear.setTitle("Xóa lịch sử mã", for: .normal)
        clear.setTitleColor(UIColor(red: 1.00, green: 0.78, blue: 0.72, alpha: 1), for: .normal)
        clear.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        clear.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.recentCodeStore.removeAll()
            self.showRecentCodesPage()
        }, for: .touchUpInside)
        stack.addArrangedSubview(clear)
        return stack
    }

    private func showRecentCodesPage() {
        pageStack.arrangedSubviews.forEach { view in
            pageStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        pageStack.addArrangedSubview(makeRecentCodesPage())
    }

    private func showRecentCodesPageIfVisible() {
        // Chỉ refresh nếu người dùng đang ở trang lịch sử mã.
        let isRecentCodesPage = pageStack.arrangedSubviews.first?.accessibilityIdentifier == "recent-codes-page"
        if isRecentCodesPage { showRecentCodesPage() }
    }

    private func makeDeveloperPage() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.addArrangedSubview(makePaytoneLabel("Nhà phát triển", size: 24, color: .white))
        stack.addArrangedSubview(makeBodyLabel("Tác giả: j4avzckcy", size: 17,
                                               color: UIColor(red: 1.00, green: 0.83, blue: 0.75, alpha: 1)))
        stack.addArrangedSubview(makeBodyLabel("VideoStar Tool • Phiên bản 1.0.0", size: 13,
                                               color: UIColor(white: 0.84, alpha: 1)))
        return stack
    }

    private func makeFeatureButton(for feature: ToolFeature) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(feature.displayTitle, for: .normal)
        button.setTitleColor(UIColor(red: 1.00, green: 0.91, blue: 0.88, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 2
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.backgroundColor = UIColor.white.withAlphaComponent(0.055)
        button.layer.cornerRadius = 17
        button.layer.borderWidth = 1.2
        button.layer.borderColor = UIColor(red: 0.96, green: 0.72, blue: 0.72, alpha: 0.62).cgColor
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 68).isActive = true
        button.accessibilityLabel = feature.displayTitle
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            // Last Code là chức năng local; các workflow editor còn lại đi qua adapter.
            if feature == .lastCode {
                self.showRecentCodesPage()
            } else {
                // Không tự hiển thị hộp thoại "Thay thành công" tại đây.
                self.onFeatureSelected?(feature)
            }
        }, for: .touchUpInside)
        return button
    }

    private func makeFooter() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 5
        stack.addArrangedSubview(makePaytoneLabel("Phiên bản đang sử dụng: 1.0.0", size: 12,
                                                  color: UIColor(red: 1.00, green: 0.82, blue: 0.69, alpha: 1)))
        stack.addArrangedSubview(makePaytoneLabel("VIDEOSTAR  •  J4AVZCKCY", size: 10,
                                                  color: UIColor(red: 1.00, green: 0.78, blue: 0.82, alpha: 1)))
        return stack
    }

    private func makeDivider() -> UIView {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }

    /// Các tiêu đề nằm ngoài ô chức năng dùng Paytone One.
    private func makePaytoneLabel(_ text: String, size: CGFloat, color: UIColor) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = color
        label.font = UIFont(name: "PaytoneOne-Regular", size: size)
            ?? UIFont.systemFont(ofSize: size, weight: .heavy)
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func makeBodyLabel(_ text: String, size: CGFloat, color: UIColor) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = color
        label.font = UIFont.systemFont(ofSize: size, weight: .regular)
        label.adjustsFontForContentSizeCategory = true
        return label
    }
}

/// Viền chuyển sắc pastel chạy quanh khung chính.
private final class PastelGradientBorderView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    private let borderShape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        isUserInteractionEnabled = false
        let gradient = layer as! CAGradientLayer
        gradient.colors = [
            UIColor(red: 1.00, green: 0.70, blue: 0.82, alpha: 1).cgColor,
            UIColor(red: 1.00, green: 0.90, blue: 0.63, alpha: 1).cgColor,
            UIColor(red: 0.96, green: 0.73, blue: 0.82, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        borderShape.fillColor = UIColor.clear.cgColor
        borderShape.strokeColor = UIColor.white.cgColor
        borderShape.lineWidth = 2.3
        gradient.mask = borderShape
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderShape.frame = bounds
        borderShape.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 1.2, dy: 1.2),
            cornerRadius: 28
        ).cgPath
    }
}

#endif
