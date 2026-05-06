import UIKit

/// Protocol abstracting UITextDocumentProxy for testability.
protocol TextProxyProtocol: AnyObject {
    func insertText(_ text: String)
    func deleteBackward()
    func adjustTextPosition(byCharacterOffset offset: Int)
    var documentContextBeforeInput: String? { get }
}

/// Thin wrapper making UITextDocumentProxy conform to TextProxyProtocol.
/// We can't extend UITextDocumentProxy directly (it's an ObjC protocol).
final class LiveTextProxy: TextProxyProtocol {
    private weak var controller: UIInputViewController?

    init(controller: UIInputViewController) {
        self.controller = controller
    }

    private var proxy: UITextDocumentProxy? {
        controller?.textDocumentProxy
    }

    func insertText(_ text: String) {
        proxy?.insertText(text)
    }

    func deleteBackward() {
        proxy?.deleteBackward()
    }

    func adjustTextPosition(byCharacterOffset offset: Int) {
        proxy?.adjustTextPosition(byCharacterOffset: offset)
    }

    var documentContextBeforeInput: String? {
        proxy?.documentContextBeforeInput
    }
}

/// InputEngine: testable module isolating all text proxy operations.
/// Single source of truth for text manipulation — views only consume.
///
/// IMPORTANT: We do NOT store a proxy reference because `textDocumentProxy`
/// is a computed property on UIInputViewController that changes when the user
/// switches text fields. `LiveTextProxy` resolves this by reading the proxy
/// live on every call. For tests, inject `MockTextProxy` directly.
final class InputEngine {

    private let proxy: TextProxyProtocol

    /// Maximum characters that applyResult is allowed to auto-delete.
    static let maxDeleteCap = 1200

    /// Production initializer: uses controller's live textDocumentProxy.
    init(controller: UIInputViewController) {
        self.proxy = LiveTextProxy(controller: controller)
    }

    /// Test initializer: injects a mock proxy.
    init(mockProxy: TextProxyProtocol) {
        self.proxy = mockProxy
    }

    // MARK: - Basic Operations

    func insertText(_ text: String) {
        proxy.insertText(text)
    }

    func deleteBackward() {
        proxy.deleteBackward()
    }

    func adjustCursor(by offset: Int) {
        proxy.adjustTextPosition(byCharacterOffset: offset)
    }

    var contextBeforeInput: String {
        proxy.documentContextBeforeInput ?? ""
    }

    // MARK: - Smart Replace (safe pipeline)

    struct ReplaceResult {
        let success: Bool
        let reason: String
    }

    /// Safely replaces `originalText` at the end of the current context with `newText`.
    /// Enforces a max-delete cap and context-match verification.
    /// Falls back to clipboard when context is lost or text is too long.
    func safeReplace(originalText: String, with newText: String) -> ReplaceResult {
        let context = contextBeforeInput

        // Context empty/nil: copy to clipboard
        if context.isEmpty {
            UIPasteboard.general.string = newText
            return ReplaceResult(success: false, reason: "Context lost. Copied to clipboard.")
        }

        // Guard: context must still end with original text
        guard context.hasSuffix(originalText) else {
            return ReplaceResult(success: false, reason: "Text changed. Cancelled.")
        }

        // Guard: never auto-delete more than cap
        guard originalText.count <= InputEngine.maxDeleteCap else {
            UIPasteboard.general.string = newText
            return ReplaceResult(success: false, reason: "Text too long. Copied to clipboard.")
        }

        // Execute replace
        for _ in 0..<originalText.count {
            proxy.deleteBackward()
        }
        proxy.insertText(newText)

        return ReplaceResult(success: true, reason: "Done!")
    }

    // MARK: - Auto-Capitalization

    func shouldAutoCapitalize() -> Bool {
        let context = contextBeforeInput
        if context.isEmpty { return true }
        let trimmed = context.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return true }
        let last = trimmed.last!
        return last == "." || last == "!" || last == "?" || last == "\n"
    }

    // MARK: - Shortcut Engine

    func checkAndApplyShortcut(shortcuts: [String: String]) -> Bool {
        guard !shortcuts.isEmpty else { return false }
        let context = contextBeforeInput
        for (trigger, replacement) in shortcuts {
            if context.hasSuffix(trigger) {
                for _ in 0..<trigger.count {
                    proxy.deleteBackward()
                }
                proxy.insertText(replacement)
                return true
            }
        }
        return false
    }
}
