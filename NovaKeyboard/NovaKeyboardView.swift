import SwiftUI
import UIKit

struct NovaKeyboardView: View {
    var controller: UIInputViewController
    let engine: InputEngine

    @State var isProcessing = false
    @State var statusMessage = "Nova AI Ready"
    @State var clipboardContent: String? = nil
    @State var showToneMenu = false
    @State var selectedTone = "Professional"
    @State var isShifted = false
    @State var isCapsLocked = false
    @State var lastSpaceTime: Date = .distantPast
    @State var currentPage: KeyboardPage = .letters
    @State var shouldAutoCapitalize = true
    @State var selectedEmojiCategory = 0
    @State var isSpaceDragging = false
    @State var lastCursorOffset = 0
    @State var cachedShortcuts: [String: String] = [:]
    @State var longPressKey: String? = nil
    @State var longPressAlts: [String] = []
    @State var selectedAltIndex: Int = -1

    @State var customKeyHeight: CGFloat = 42
    @State var customFontSize: CGFloat = 22
    @State var keySoundsEnabled: Bool = true
    @State var hapticEnabled: Bool = true
    @State var keyboardLayout: String = "Turkish"
    @State var cachedRow1: [String] = []
    @State var cachedRow2: [String] = []
    @State var cachedRow3: [String] = []

    // Gesture cooldown: prevents double-swipe triggering AI twice
    @State var lastAISwipeTime: Date = .distantPast
    // Double-tap shift for caps lock (Apple behavior)
    @State var lastShiftTapTime: Date = .distantPast
    private static let aiCooldown: TimeInterval = 1.5

    let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    let selectionGenerator = UISelectionFeedbackGenerator()
    static let turkishLocale = Locale(identifier: "tr")

    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 2) {
                statusBar

                switch currentPage {
                case .letters: lettersPage
                case .numbers: numbersPage
                case .symbols: symbolsPage
                case .emoji:   emojiPage
                }

                bottomRow
            }

            if showToneMenu {
                toneMenuOverlay
            }

            if longPressKey != nil && !longPressAlts.isEmpty {
                longPressPopup
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDark ? Color(red: 0.07, green: 0.07, blue: 0.1) : Color(red: 0.82, green: 0.83, blue: 0.85))
        .simultaneousGesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // Cooldown guard
                    let now = Date()
                    guard now.timeIntervalSince(lastAISwipeTime) >= Self.aiCooldown else { return }

                    if value.translation.height < -60 {
                        withAnimation(.easeOut(duration: 0.15)) { showToneMenu = true }
                    } else if value.translation.height > 60 {
                        lastAISwipeTime = now
                        guard controller.hasFullAccess else {
                            requestFullAccess()
                            return
                        }
                        let text = engine.contextBeforeInput
                        if !text.isEmpty {
                            translateText(text)
                        } else {
                            statusMessage = "Type something first"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { statusMessage = "Nova AI Ready" }
                        }
                    } else if value.translation.width < -60 {
                        lastAISwipeTime = now
                        guard controller.hasFullAccess else {
                            requestFullAccess()
                            return
                        }
                        let text = engine.contextBeforeInput
                        if !text.isEmpty {
                            spellCheckText(text)
                        } else {
                            statusMessage = "Type something first"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { statusMessage = "Nova AI Ready" }
                        }
                    }
                }
        )
        .onAppear {
            loadCachedSettings()
            checkClipboard()
            updateAutoCapitalize()
            loadShortcuts()
            impactGenerator.prepare()
            selectionGenerator.prepare()
        }
    }

    // MARK: - Helpers for child views

    func turkishLowercase(_ key: String) -> String {
        if keyboardLayout == "Turkish" {
            if key == "I" { return "\u{0131}" }
            if key == "\u{0130}" { return "i" }
            return key.lowercased(with: NovaKeyboardView.turkishLocale)
        }
        return key.lowercased()
    }

    /// Builds a charKey using the unified state-machine CharKeyView
    func charKey(_ key: String) -> some View {
        CharKeyView(
            key: key,
            keyboardLayout: keyboardLayout,
            isDark: isDark,
            customFontSize: customFontSize,
            customKeyHeight: customKeyHeight,
            hapticEnabled: hapticEnabled,
            impactGenerator: impactGenerator,
            isShifted: $isShifted,
            isCapsLocked: $isCapsLocked,
            longPressKey: $longPressKey,
            longPressAlts: $longPressAlts,
            selectedAltIndex: $selectedAltIndex,
            engine: engine,
            selectionGenerator: selectionGenerator,
            playKeySoundAction: { self.playKeySound() },
            onKeyInserted: {
                self.checkShortcuts()
                self.updateAutoCapitalize()
            }
        )
    }

    func specialCharKey(_ key: String) -> some View {
        SpecialCharKeyView(
            key: key,
            isDark: isDark,
            customFontSize: customFontSize,
            customKeyHeight: customKeyHeight,
            engine: engine,
            hapticEnabled: hapticEnabled,
            impactGenerator: impactGenerator,
            playKeySoundAction: { self.playKeySound() }
        )
    }

    var deleteButton: some View {
        DeleteKeyView(
            isDark: isDark,
            customKeyHeight: customKeyHeight,
            engine: engine,
            hapticEnabled: hapticEnabled,
            impactGenerator: impactGenerator,
            playKeySoundAction: { self.playKeySound() },
            updateAutoCapitalizeAction: { self.updateAutoCapitalize() }
        )
    }
}
