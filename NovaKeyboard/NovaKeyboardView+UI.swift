import SwiftUI
import UIKit

extension NovaKeyboardView {

    var statusBar: some View {
        HStack(spacing: 4) {
            if isProcessing {
                ProgressView().scaleEffect(0.5).accentColor(Color(red: 0, green: 0.8, blue: 0.85))
            } else {
                Image(systemName: "sparkles").foregroundColor(Color(red: 0, green: 0.8, blue: 0.85)).font(.system(size: 7))
            }
            Text(statusMessage)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(isDark ? .white.opacity(0.4) : .black.opacity(0.3))
                .lineLimit(1)
            Spacer()

            if let clip = clipboardContent {
                Button {
                    engine.insertText(UIPasteboard.general.string ?? "")
                    clipboardContent = nil
                    playKeySound()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "doc.on.clipboard").font(.system(size: 6))
                        Text(clip).font(.system(size: 7)).lineLimit(1)
                    }
                    .foregroundColor(Color(red: 0, green: 0.8, blue: 0.85))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color(red: 0, green: 0.8, blue: 0.85).opacity(0.15))
                    .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 14)
    }

    // MARK: - Shift Button (Apple-style double-tap for caps lock)

    var shiftButton: some View {
        Button {
            playKeySound()
            let now = Date()
            let interval = now.timeIntervalSince(lastShiftTapTime)
            lastShiftTapTime = now

            if interval < 0.35 && isShifted && !isCapsLocked {
                // Double-tap: engage caps lock
                isCapsLocked = true
            } else if isCapsLocked {
                // Tap while caps locked: disengage
                isCapsLocked = false
                isShifted = false
            } else {
                // Single tap: toggle shift
                isShifted.toggle()
            }
        } label: {
            Image(systemName: isCapsLocked ? "capslock.fill" : (isShifted ? "shift.fill" : "shift"))
                .font(.system(size: 15))
                .foregroundColor((isShifted || isCapsLocked) ? .black : (isDark ? .white : .black))
                .frame(width: 44, height: customKeyHeight)
                .background(RoundedRectangle(cornerRadius: 5).fill(
                    (isShifted || isCapsLocked)
                    ? Color(red: 0, green: 0.8, blue: 0.85)
                    : (isDark ? Color.white.opacity(0.15) : Color(white: 0.72))
                ))
                .contentShape(Rectangle().inset(by: -4)) // extra hitbox
        }.buttonStyle(PlainButtonStyle())
    }

    var bottomRow: some View {
        HStack(spacing: 4) {
            Button {
                playKeySound()
                switch currentPage {
                case .letters: currentPage = .numbers
                case .numbers, .symbols: currentPage = .letters
                case .emoji: currentPage = .letters
                }
            } label: {
                Text(currentPage == .letters ? "123" : "ABC")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(isDark ? .white : .black)
                    .frame(width: 40, height: customKeyHeight)
                    .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.15) : Color(white: 0.72)))
            }.buttonStyle(PlainButtonStyle())

            Button {
                playKeySound()
                currentPage = currentPage == .emoji ? .letters : .emoji
            } label: {
                Image(systemName: currentPage == .emoji ? "keyboard" : "face.smiling")
                    .font(.system(size: 16))
                    .foregroundColor(isDark ? .white : .black)
                    .frame(width: 36, height: customKeyHeight)
                    .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.15) : Color(white: 0.72)))
            }.buttonStyle(PlainButtonStyle())

            Button { controller.advanceToNextInputMode() } label: {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .foregroundColor(isDark ? .white : .black)
                    .frame(width: 36, height: customKeyHeight)
                    .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.15) : Color(white: 0.72)))
            }.buttonStyle(PlainButtonStyle())

            Button {
                engine.insertText(",")
                playKeySound()
            } label: {
                Text(",")
                    .font(.system(size: 18))
                    .foregroundColor(isDark ? .white : .black)
                    .frame(width: 28, height: customKeyHeight)
                    .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.15) : Color(white: 0.72)))
            }.buttonStyle(PlainButtonStyle())

            spaceBar

            Button {
                engine.insertText(".")
                playKeySound()
                shouldAutoCapitalize = true
                isShifted = true
            } label: {
                Text(".")
                    .font(.system(size: 18))
                    .foregroundColor(isDark ? .white : .black)
                    .frame(width: 28, height: customKeyHeight)
                    .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.15) : Color(white: 0.72)))
            }.buttonStyle(PlainButtonStyle())

            Button {
                playKeySound()
                engine.insertText("\n")
                shouldAutoCapitalize = true
                isShifted = true
            } label: {
                Image(systemName: "return.left")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .frame(width: 52, height: customKeyHeight)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.blue))
            }.buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 3)
        .frame(height: customKeyHeight)
    }

    // MARK: - Space Bar with Nonlinear Cursor Drag

    var spaceBar: some View {
        Button {
            let now = Date()
            if now.timeIntervalSince(lastSpaceTime) < 0.3 {
                engine.deleteBackward()
                engine.insertText(". ")
                shouldAutoCapitalize = true
                isShifted = true
            } else {
                engine.insertText(" ")
            }
            lastSpaceTime = now
            playKeySound()
        } label: {
            Text(isSpaceDragging ? "◆ Cursor" : "Nova AI")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(isSpaceDragging ? Color(red: 0, green: 0.8, blue: 0.85) : (isDark ? .white.opacity(0.3) : .black.opacity(0.3)))
                .frame(maxWidth: .infinity).frame(height: customKeyHeight)
                .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.15) : Color.white))
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Strict horizontal check
                    guard abs(value.translation.width) > 20,
                          abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }

                    isSpaceDragging = true

                    // Nonlinear curve: small movement = precise, large = fast
                    let raw = value.translation.width
                    let sign: CGFloat = raw >= 0 ? 1 : -1
                    let magnitude = abs(raw)
                    // Apply sqrt curve for precision at low distances
                    let curved = sign * sqrt(magnitude) * 1.2
                    let newOffset = Int(curved)
                    let diff = newOffset - lastCursorOffset

                    if diff != 0 {
                        engine.adjustCursor(by: diff)
                        lastCursorOffset = newOffset
                        if hapticEnabled { selectionGenerator.selectionChanged() }
                    }
                }
                .onEnded { _ in
                    isSpaceDragging = false
                    lastCursorOffset = 0
                }
        )
    }

    var toneMenuOverlay: some View {
        VStack {
            HStack(spacing: 6) {
                ForEach(AITones.all, id: \.self) { tone in
                    Button {
                        selectedTone = tone
                        withAnimation(.easeOut(duration: 0.15)) { showToneMenu = false }
                        rewriteText(tone: tone)
                    } label: {
                        Text(tone)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(selectedTone == tone ? Color(red: 0, green: 0.8, blue: 0.85) : (isDark ? Color(white: 0.2) : Color(white: 0.85)))
                            .foregroundColor(selectedTone == tone ? .black : (isDark ? .white : .black))
                            .cornerRadius(6)
                    }
                }

                Button {
                    withAnimation(.easeOut(duration: 0.15)) { showToneMenu = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(isDark ? .white.opacity(0.5) : .black.opacity(0.3))
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background((isDark ? Color(white: 0.12) : Color.white).cornerRadius(10))
            .shadow(color: (isDark ? Color.black : Color.black.opacity(0.15)), radius: 5)
            .padding(.top, 2)

            Spacer()
        }
        .transition(.opacity)
    }

    var longPressPopup: some View {
        GeometryReader { geo in
            VStack {
                HStack(spacing: 1) {
                    ForEach(Array(longPressAlts.enumerated()), id: \.offset) { idx, alt in
                        Text(alt)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(idx == selectedAltIndex ? .black : (isDark ? .white : .black))
                            .frame(width: 32, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(idx == selectedAltIndex ? Color(red: 0, green: 0.8, blue: 0.85) : (isDark ? Color(white: 0.2) : Color.white))
                            )
                    }
                }
                .padding(4)
                .background((isDark ? Color(white: 0.12) : Color(white: 0.92)).cornerRadius(8))
                .shadow(color: Color.black.opacity(0.3), radius: 4)
                // Edge clamp: keep popup within screen bounds
                .frame(maxWidth: geo.size.width - 16)
                Spacer()
            }
            .padding(.top, 20)
            .frame(maxWidth: .infinity)
        }
        .transition(.opacity)
    }
}
