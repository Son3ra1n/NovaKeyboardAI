import SwiftUI
import UIKit
import AudioToolbox
import os.signpost

// Signpost loggers for Instruments profiling
fileprivate let aiLog = OSLog(subsystem: "com.nova.keyboard", category: "AI")
fileprivate let keyLog = OSLog(subsystem: "com.nova.keyboard", category: "KeyPress")

extension NovaKeyboardView {

    func playKeySound() {
        if keySoundsEnabled { AudioServicesPlaySystemSound(1104) }
        // Note: haptic is now fired by individual key views on touchUp, not here
    }

    func requestFullAccess() {
        statusMessage = "⚠️ Full Access required → Opening Settings..."
        if let kvc = controller as? KeyboardViewController {
            kvc.openAppSettings()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.statusMessage = "Nova AI Ready" }
    }

    func updateAutoCapitalize() {
        if engine.shouldAutoCapitalize() {
            shouldAutoCapitalize = true
            if !isCapsLocked { isShifted = true }
        }
    }

    func rewriteText(tone: String) {
        guard !isProcessing else { return }
        guard controller.hasFullAccess else {
            requestFullAccess()
            return
        }
        let text = engine.contextBeforeInput
        guard !text.isEmpty else { return }
        isProcessing = true
        statusMessage = "Rewriting..."

        let signpostID = OSSignpostID(log: aiLog)
        os_signpost(.begin, log: aiLog, name: "RewriteRequest", signpostID: signpostID)

        NovaAIEngine.shared.request(
            prompt: "Rewrite this text to be more \(tone). Return ONLY the rewritten text, nothing else: \(text)"
        ) { result in
            os_signpost(.end, log: aiLog, name: "RewriteRequest", signpostID: signpostID)
            self.applyResult(result, originalText: text)
        }
    }

    func translateText(_ text: String) {
        guard !isProcessing else { return }
        guard controller.hasFullAccess else {
            requestFullAccess()
            return
        }

        let nativeLang = SharedSettings.string(forKey: AppGroupKeys.nativeLanguage) ?? "Turkish"
        let targetLang = SharedSettings.string(forKey: AppGroupKeys.targetLanguage) ?? "English"

        if nativeLang.lowercased() == targetLang.lowercased() {
            statusMessage = "Diller aynı (iptal)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.statusMessage = "Nova AI Ready" }
            return
        }

        isProcessing = true
        statusMessage = "Translating..."

        let signpostID = OSSignpostID(log: aiLog)
        os_signpost(.begin, log: aiLog, name: "TranslateRequest", signpostID: signpostID, "Started translation for %d chars", text.count)

        NovaAIEngine.shared.request(
            prompt: "Translate the following text from \(nativeLang) to \(targetLang). Return ONLY the translation, nothing else: \(text)"
        ) { result in
            os_signpost(.end, log: aiLog, name: "TranslateRequest", signpostID: signpostID, "Finished translation")
            self.applyResult(result, originalText: text)
        }
    }

    func spellCheckText(_ text: String) {
        guard !isProcessing else { return }
        guard controller.hasFullAccess else {
            requestFullAccess()
            return
        }
        isProcessing = true
        statusMessage = "Fixing..."

        let lang = SharedSettings.string(forKey: AppGroupKeys.nativeLanguage) ?? "Turkish"
        let prompt = "The text was written in \(lang). Fix spelling and grammar only in \(lang). Do not translate or use words from other languages. Keep the same meaning and tone. Return ONLY the corrected text, nothing else: \(text)"

        let signpostID = OSSignpostID(log: aiLog)
        os_signpost(.begin, log: aiLog, name: "SpellCheckRequest", signpostID: signpostID)

        NovaAIEngine.shared.request(prompt: prompt) { result in
            os_signpost(.end, log: aiLog, name: "SpellCheckRequest", signpostID: signpostID)
            self.applyResult(result, originalText: text)
        }
    }

    func applyResult(_ result: Result<String, NovaAIEngine.AIError>, originalText: String) {
        isProcessing = false
        switch result {
        case .success(let newText):
            let replaceResult = engine.safeReplace(originalText: originalText, with: newText)
            statusMessage = replaceResult.reason
            if replaceResult.success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        case .failure(let error):
            switch error {
            case .noApiKey:
                statusMessage = controller.hasFullAccess
                    ? "API key missing — save in Nova app"
                    : "Tam Erişim kapalı — anahtar okunamaz"
            case .networkError:       statusMessage = "Network error"
            case .unauthorized:       statusMessage = "Invalid API Key"
            case .rateLimited:        statusMessage = "Rate limited. Wait a moment."
            case .serverError(let c): statusMessage = "Server error (\(c))"
            case .parseError:         statusMessage = "Error. Try again."
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.statusMessage = "Nova AI Ready" }
    }

    func checkClipboard() {
        if let text = UIPasteboard.general.string, !text.isEmpty, text.count > 2 {
            clipboardContent = String(text.prefix(25))
        } else {
            clipboardContent = nil
        }
    }

    func loadCachedSettings() {
        let h = SharedSettings.double(forKey: AppGroupKeys.keyHeight) ?? 42
        customKeyHeight = h >= 30 ? CGFloat(h) : 42
        let f = SharedSettings.double(forKey: AppGroupKeys.fontSize) ?? 22
        customFontSize = f >= 14 ? CGFloat(f) : 22
        keySoundsEnabled = SharedSettings.bool(forKey: AppGroupKeys.keySounds)
        hapticEnabled = SharedSettings.bool(forKey: AppGroupKeys.hapticFeedback)
        keyboardLayout = SharedSettings.string(forKey: AppGroupKeys.keyboardLayout) ?? "Turkish"

        let rows = KeyboardLayouts.rows(for: keyboardLayout)
        cachedRow1 = rows.row1
        cachedRow2 = rows.row2
        cachedRow3 = rows.row3
    }

    func loadShortcuts() {
        guard let jsonStr = SharedSettings.string(forKey: AppGroupKeys.textShortcuts),
              let data = jsonStr.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return }
        cachedShortcuts = dict
    }

    func checkShortcuts() {
        if engine.checkAndApplyShortcut(shortcuts: cachedShortcuts) {
            playKeySound()
        }
    }
}
