import UIKit

/// InputEngine: testable module isolating all UITextDocumentProxy operations.
/// Single source of truth for text manipulation — views only consume.
///
/// IMPORTANT: We do NOT store a `proxy` reference because `textDocumentProxy`
/// is a computed property on UIInputViewController that changes when the user
/// switches text fields. Instead, we hold a weak ref to the controller and
/// access `textDocumentProxy` live on every call.
final class InputEngine {

    private weak var controller: UIInputViewController?

    /// Maximum characters that applyResult is allowed to auto-delete.
    static let maxDeleteCap = 1200

    /// The live proxy — always current, even after text field switches.
    private var proxy: UITextDocumentProxy? {
        controller?.textDocumentProxy
    }

    init(controller: UIInputViewController) {
        self.controller = controller
    }

    /// Test-only initializer: injects a mock proxy directly.
    /// Do NOT use in production (proxy would go stale).
    #if DEBUG
    private weak var _testProxy: UITextDocumentProxy?
    init(testProxy: UITextDocumentProxy) {
        self._testProxy = testProxy
        self.controller = nil
    }
    #endif

    // MARK: - Basic Operations

    func insertText(_ text: String) {
        proxy?.insertText(text)
    }

    func deleteBackward() {
        proxy?.deleteBackward()
    }

    func adjustCursor(by offset: Int) {
        proxy?.adjustTextPosition(byCharacterOffset: offset)
    }

    var contextBeforeInput: String {
        proxy?.documentContextBeforeInput ?? ""
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
            proxy?.deleteBackward()
        }
        proxy?.insertText(newText)

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
                    proxy?.deleteBackward()
                }
                proxy?.insertText(replacement)
                return true
            }
        }
        return false
    }
}
