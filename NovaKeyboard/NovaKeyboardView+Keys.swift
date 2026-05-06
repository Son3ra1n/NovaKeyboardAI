import SwiftUI
import UIKit

// MARK: - CharKeyView — Unified Input State Machine
// States: idle → highlighted (touchDown) → inserted (touchUpInside) → longPress → altSelection
// Haptic fires ONLY on touchUp (Apple feel). Long-press shows alt popup.

struct CharKeyView: View {
    let key: String
    let keyboardLayout: String
    let isDark: Bool
    let customFontSize: CGFloat
    let customKeyHeight: CGFloat
    let hapticEnabled: Bool
    let impactGenerator: UIImpactFeedbackGenerator

    @Binding var isShifted: Bool
    @Binding var isCapsLocked: Bool
    @Binding var longPressKey: String?
    @Binding var longPressAlts: [String]
    @Binding var selectedAltIndex: Int

    let engine: InputEngine
    let selectionGenerator: UISelectionFeedbackGenerator
    let playKeySoundAction: () -> Void
    let onKeyInserted: () -> Void

    // Internal state
    @State private var isHighlighted = false
    @State private var hasFired = false
    @State private var touchDownTime: Date = .distantPast
    @State private var isInLongPress = false

    private static let turkishLocale = Locale(identifier: "tr")
    private static let longPressThreshold: TimeInterval = 0.35

    func turkishLowercase(_ k: String) -> String {
        if keyboardLayout == "Turkish" {
            if k == "I" { return "\u{0131}" }
            if k == "\u{0130}" { return "i" }
            return k.lowercased(with: Self.turkishLocale)
        }
        return k.lowercased()
    }

    var displayChar: String {
        (isShifted || isCapsLocked) ? key : turkishLowercase(key)
    }

    var body: some View {
        Text(displayChar)
            .font(.system(size: customFontSize, weight: .regular, design: .rounded))
            .foregroundColor(isDark ? .white : .black)
            .frame(maxWidth: .infinity).frame(height: customKeyHeight)
            .background(
                RoundedRectangle(cornerRadius: 5).fill(keyBackground)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isHighlighted {
                            // === TOUCH DOWN ===
                            isHighlighted = true
                            hasFired = false
                            isInLongPress = false
                            touchDownTime = Date()
                            if hapticEnabled { impactGenerator.prepare() }
                        }

                        // Check for long-press threshold
                        let elapsed = Date().timeIntervalSince(touchDownTime)
                        if elapsed >= Self.longPressThreshold && !isInLongPress && !hasFired {
                            isInLongPress = true
                            if let alts = AlternateCharacters.map[key.uppercased()], !alts.isEmpty {
                                longPressKey = key
                                longPressAlts = (isShifted || isCapsLocked) ? alts : alts.map { turkishLowercase($0) }
                                selectedAltIndex = -1
                                if hapticEnabled { selectionGenerator.selectionChanged() }
                            }
                        }

                        // Alt character selection via drag
                        if longPressKey != nil && !longPressAlts.isEmpty {
                            let idx = Int(value.translation.width / 34)
                            let clamped = max(0, min(longPressAlts.count - 1, idx))
                            if clamped != selectedAltIndex {
                                selectedAltIndex = clamped
                                if hapticEnabled { selectionGenerator.selectionChanged() }
                            }
                        }
                    }
                    .onEnded { _ in
                        defer {
                            isHighlighted = false
                            hasFired = false
                        }

                        if isInLongPress {
                            // === LONG PRESS END: insert selected alt ===
                            if longPressKey != nil && selectedAltIndex >= 0 && selectedAltIndex < longPressAlts.count {
                                let alt = longPressAlts[selectedAltIndex]
                                engine.insertText(alt)
                                playKeySoundAction()
                                if hapticEnabled { impactGenerator.impactOccurred() }
                                if !isCapsLocked { isShifted = false }
                            }
                            longPressKey = nil
                            longPressAlts = []
                            selectedAltIndex = -1
                            isInLongPress = false
                        } else if !hasFired {
                            // === TOUCH UP INSIDE: normal key insert ===
                            hasFired = true
                            engine.insertText(displayChar)
                            playKeySoundAction()
                            if hapticEnabled { impactGenerator.impactOccurred() }
                            if !isCapsLocked { isShifted = false }
                            onKeyInserted()
                        }
                    }
            )
    }

    private var keyBackground: Color {
        if isHighlighted {
            return Color(red: 0, green: 0.8, blue: 0.85).opacity(0.25)
        }
        if longPressKey == key {
            return Color(red: 0, green: 0.8, blue: 0.85).opacity(0.3)
        }
        return isDark ? Color.white.opacity(0.1) : Color.white
    }
}

// MARK: - SpecialCharKeyView — Touch Up Insert

struct SpecialCharKeyView: View {
    let key: String
    let isDark: Bool
    let customFontSize: CGFloat
    let customKeyHeight: CGFloat
    let engine: InputEngine
    let hapticEnabled: Bool
    let impactGenerator: UIImpactFeedbackGenerator
    let playKeySoundAction: () -> Void

    @State private var isHighlighted = false
    @State private var hasFired = false

    var body: some View {
        Text(key)
            .font(.system(size: customFontSize, weight: .regular))
            .foregroundColor(isDark ? .white : .black)
            .frame(maxWidth: .infinity).frame(height: customKeyHeight)
            .background(RoundedRectangle(cornerRadius: 5).fill(
                isHighlighted ? Color(red: 0, green: 0.8, blue: 0.85).opacity(0.2)
                : (isDark ? Color.white.opacity(0.1) : Color.white)
            ))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHighlighted {
                            isHighlighted = true
                            hasFired = false
                            if hapticEnabled { impactGenerator.prepare() }
                        }
                    }
                    .onEnded { _ in
                        defer { isHighlighted = false }
                        if !hasFired {
                            hasFired = true
                            engine.insertText(key)
                            playKeySoundAction()
                            if hapticEnabled { impactGenerator.impactOccurred() }
                        }
                    }
            )
    }
}

// MARK: - DeleteKeyView — Apple-Style Accelerating Repeat

struct DeleteKeyView: View {
    let isDark: Bool
    let customKeyHeight: CGFloat
    let engine: InputEngine
    let hapticEnabled: Bool
    let impactGenerator: UIImpactFeedbackGenerator
    let playKeySoundAction: () -> Void
    let updateAutoCapitalizeAction: () -> Void

    @State private var isHighlighted = false
    @State private var deleteTimer: Timer?
    @State private var repeatStage = 0

    // Apple-style acceleration: initial delay → slow → faster → fastest
    private static let initialDelay: TimeInterval = 0.4
    private static let repeatSpeeds: [TimeInterval] = [0.12, 0.08, 0.05]
    private static let stageThresholds = [4, 12]

    @State private var totalDeleted = 0

    var body: some View {
        Image(systemName: "delete.left")
            .font(.system(size: 15))
            .foregroundColor(isDark ? .white : .black)
            .frame(width: 44, height: customKeyHeight)
            .background(RoundedRectangle(cornerRadius: 5).fill(
                isHighlighted ? Color.red.opacity(0.2)
                : (isDark ? Color.white.opacity(0.15) : Color(white: 0.72))
            ))
            .contentShape(Rectangle().inset(by: -4))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHighlighted {
                            isHighlighted = true
                            totalDeleted = 0
                            repeatStage = 0

                            // Immediate first delete
                            engine.deleteBackward()
                            totalDeleted += 1
                            playKeySoundAction()
                            if hapticEnabled { impactGenerator.impactOccurred() }

                            // Start repeat timer after initial delay
                            deleteTimer = Timer.scheduledTimer(withTimeInterval: Self.initialDelay, repeats: false) { _ in
                                self.startRepeat()
                            }
                        }
                    }
                    .onEnded { _ in
                        stopDelete()
                    }
            )
    }

    private func startRepeat() {
        let speed = currentSpeed()
        deleteTimer?.invalidate()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in
            engine.deleteBackward()
            totalDeleted += 1

            if repeatStage < Self.stageThresholds.count {
                if totalDeleted >= Self.stageThresholds[repeatStage] {
                    repeatStage += 1
                    startRepeat()
                }
            }
        }
    }

    private func currentSpeed() -> TimeInterval {
        let idx = min(repeatStage, Self.repeatSpeeds.count - 1)
        return Self.repeatSpeeds[idx]
    }

    private func stopDelete() {
        isHighlighted = false
        deleteTimer?.invalidate()
        deleteTimer = nil
        totalDeleted = 0
        repeatStage = 0
        updateAutoCapitalizeAction()
    }
}
