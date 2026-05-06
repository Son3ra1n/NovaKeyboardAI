import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    private var heightConstraint: NSLayoutConstraint?
    private var didShowFullAccessAlert = false

    private var customHeight: CGFloat {
        let h = UserDefaults(suiteName: AppGroupKeys.suiteName)?.double(forKey: AppGroupKeys.keyboardHeight) ?? 216
        return h >= 180 ? CGFloat(h) : 216
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

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        heightConstraint?.constant = customHeight
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasFullAccess, !didShowFullAccessAlert else { return }
        didShowFullAccessAlert = true
        let alert = UIAlertController(
            title: "Tam erişim kapalı",
            message: "Çeviri, yazım düzeltme, Groq bağlantısı ve pano için Tam Erişim gerekir.\n\nAyarlar → Genel → Klavye → Klavyeler → Nova Keyboard AI → Tam Erişim'i açın.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
