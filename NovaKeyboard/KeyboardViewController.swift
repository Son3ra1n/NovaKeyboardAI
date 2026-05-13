import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var heightConstraint: NSLayoutConstraint?
    private var didShowFullAccessAlert = false

    /// Vertical chrome: status strip + outer VStack spacings + between-letter-row gaps (see `NovaKeyboardView+Pages`).
    private static let statusChrome: CGFloat = 18
    private static let outerVStackSpacing: CGFloat = 4
    private static let letterRowGaps: CGFloat = 8

    /// Minimum height so 3 letter rows + bottom row + status never clip inside the constrained input view.
    private static func minimumHeight(forKeyHeight keyH: CGFloat) -> CGFloat {
        let k = max(30, min(54, keyH))
        return statusChrome + outerVStackSpacing + letterRowGaps + 4 * k
    }

    private var customHeight: CGFloat {
        let user = SharedSettings.double(forKey: AppGroupKeys.keyboardHeight).map { CGFloat($0) } ?? 216
        let userClamped = user >= 180 ? user : 216
        let keyH = SharedSettings.double(forKey: AppGroupKeys.keyHeight).map { CGFloat($0) } ?? 42
        let needed = Self.minimumHeight(forKeyHeight: keyH)
        let base = max(userClamped, needed)
        let safeBottom = view.safeAreaInsets.bottom
        return base + safeBottom
    }

    /// Opens the app's settings page where Full Access toggle is visible.
    /// Uses responder chain workaround for keyboard extensions.
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        let selector = sel_registerName("openURL:")
        var responder: UIResponder? = self
        while let r = responder {
            if r.responds(to: selector) {
                r.perform(selector, with: url)
                return
            }
            responder = r.next
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create InputEngine — accesses textDocumentProxy live via controller ref
        let engine = InputEngine(controller: self)

        let novaView = NovaKeyboardView(
            controller: self,
            engine: engine
        )
        let host = UIHostingController(rootView: novaView)
        host.view.backgroundColor = .clear

        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        heightConstraint = view.heightAnchor.constraint(equalToConstant: customHeight)
        heightConstraint?.priority = .required
        heightConstraint?.isActive = true
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        heightConstraint?.constant = customHeight
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint?.constant = customHeight
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Force-reload height every time keyboard appears (settings may have changed)
        heightConstraint?.constant = customHeight
        // Notify SwiftUI view to reload settings
        NotificationCenter.default.post(name: .novaKeyboardDidAppear, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasFullAccess, !didShowFullAccessAlert else { return }
        didShowFullAccessAlert = true
        let alert = UIAlertController(
            title: "Full Access Disabled",
            message: "Full Access is required for translation, spell check, Groq API, and clipboard.\n\nSettings → General → Keyboard → Keyboards → Nova Keyboard AI → Allow Full Access.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
