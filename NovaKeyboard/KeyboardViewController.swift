import UIKit
import SwiftUI
import AudioToolbox

class KeyboardViewController: UIInputViewController {
    
    private var heightConstraint: NSLayoutConstraint?
    private var didShowFullAccessAlert = false
    
    private var customHeight: CGFloat {
        let h = UserDefaults(suiteName: "group.com.soner.NovaAI")?.double(forKey: "keyboard_height") ?? 216
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
        
        let novaView = NovaKeyboardView(
            proxy: textDocumentProxy,
            controller: self
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
            message: "Çeviri, yazım düzeltme, Groq bağlantısı ve pano için Tam Erişim gerekir.\n\nAyarlar → Genel → Klavye → Klavyeler → Nova Keyboard AI → Tam Erişim’i açın.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Keyboard Page Enum
enum KeyboardPage {
    case letters
    case numbers
    case symbols
    case emoji
}


// MARK: - Nova Keyboard SwiftUI View
struct NovaKeyboardView: View {
    var proxy: UITextDocumentProxy
    var controller: UIInputViewController
    
    @State private var isProcessing = false
    @State private var statusMessage = "Nova AI Ready"
    @State private var clipboardContent: String? = nil
    @State private var showToneMenu = false
    @State private var selectedTone = "Professional"
    @State private var isShifted = false
    @State private var isCapsLocked = false
    @State private var deleteTimer: Timer? = nil
    @State private var lastSpaceTime: Date = .distantPast
    @State private var currentPage: KeyboardPage = .letters
    @State private var shouldAutoCapitalize = true
    @State private var selectedEmojiCategory = 0
    @State private var isSpaceDragging = false
    @State private var lastCursorOffset = 0
    @State private var cachedShortcuts: [String: String] = [:]
    @State private var longPressKey: String? = nil
    @State private var longPressAlts: [String] = []
    @State private var selectedAltIndex: Int = -1
    
    // Cached settings (loaded once on appear)
    @State private var customKeyHeight: CGFloat = 42
    @State private var customFontSize: CGFloat = 22
    @State private var keySoundsEnabled: Bool = true
    @State private var hapticEnabled: Bool = true
    @State private var keyboardLayout: String = "Turkish"
    @State private var cachedRow1: [String] = []
    @State private var cachedRow2: [String] = []
    @State private var cachedRow3: [String] = []
    
    // Long-press alternate characters
    private static let altChars: [String: [String]] = [
        "A": ["À","Á","Â","Ã","Ä","Å","Æ","Ą"],
        "E": ["È","É","Ê","Ë","Ę","Ė"],
        "I": ["Ì","Í","Î","Ï","İ","\u{0131}"],
        "O": ["Ò","Ó","Ô","Õ","Ö","Ø","Œ"],
        "U": ["Ù","Ú","Û","Ü"],
        "S": ["Ş","Ś","Š","ß"],
        "C": ["Ç","Ć","Č"],
        "G": ["Ğ","Ġ"],
        "N": ["Ñ","Ń"],
        "Y": ["Ý","Ÿ"],
        "Z": ["Ž","Ź","Ż"],
        "L": ["Ł"],
        "D": ["Ð","Ď"],
        "R": ["Ř"],
        "T": ["Ť","Þ"]
    ]
    
    let tones = ["Professional", "Casual", "Friendly", "Creative"]
    
    // Pre-allocated feedback generators
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private static let turkishLocale = Locale(identifier: "tr")
    
    // Light/Dark mode
    @Environment(\.colorScheme) var colorScheme
    var isDark: Bool { colorScheme == .dark }
    
    // Shared settings reference
    private var shared: UserDefaults? { UserDefaults(suiteName: "group.com.soner.NovaAI") }
    
    // Number rows
    let numRow1 = ["1","2","3","4","5","6","7","8","9","0"]
    let numRow2 = ["-","/",":",";","(",")","₺","&","@","\""]
    let numRow3 = [".",",","?","!","'"]
    
    // Symbol rows
    let symRow1 = ["[","]","{","}","#","%","^","*","+","="]
    let symRow2 = ["_","\\","|","~","<",">","€","$","¥","•"]
    let symRow3 = [".",",","?","!","'"]
    
    // MARK: - Emoji Data (7 Categories)
    let emojiCatIcons = ["😀","❤️","👋","🐶","🍕","🚗","⚡"]
    let emojiData: [[String]] = [
        ["😀","😃","😄","😁","😆","😅","🤣","😂","🙂","🙃","😉","😊","😇","🥰","😍","🤩","😘","😗","😚","😙","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🤫","🤔","🤐","🤨","😐","😑","😶","😏","😒","🙄","😬","😌","😔","😪","🤤","😴","😷","🤒","🤕","🤢","🤮","🤧","🥵","🥶","🥴","😵","🤯","🤠","🥳","😎","🤓","🧐","😕","😟","🙁","😮","😯","😲","😳","🥺","😨","😰","😥","😢","😭","😱","😖","😣","😞","😩","😫","😤","😡","😠","🤬","😈","👿","💀","💩","🤡","👻","👽","👾","🤖","😺","😸","😹","😻","😼","😽","🙀","😿","😾"],
        ["❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❣️","💕","💞","💓","💗","💖","💘","💝","💟","♥️","💑","💏","💍","💐","🌹","🌷","🌺","🌸","🌼","🌻"],
        ["👋","🤚","🖐","✋","🖖","👌","🤏","✌️","🤞","🤟","🤘","🤙","👈","👉","👆","🖕","👇","☝️","👍","👎","✊","👊","🤛","🤜","👏","🙌","👐","🤲","🤝","🙏","✍️","💅","🤳","💪","🦾","🦿","🦵","🦶","👂","👃","👀","👁","👅","👄"],
        ["🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🙈","🙉","🙊","🐔","🐧","🐦","🐤","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🐛","🦋","🐌","🐞","🐜","🐢","🐍","🦎","🐙","🦑","🦐","🦀","🐡","🐠","🐟","🐬","🐳","🐋","🦈"],
        ["🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🍈","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥒","🌶","🌽","🥕","🧄","🧅","🥔","🍠","🥐","🍞","🥖","🧀","🍗","🍖","🥩","🍳","🥞","🧇","🍕","🌭","🍔","🍟","🌮","🌯","🍿","🧂","🍰","🎂","🍩","🍪"],
        ["🚗","🚕","🚙","🚌","🚎","🏎","🚓","🚑","🚒","🚐","🚚","🚛","🚜","🏍","🛵","🚲","🛴","✈️","🚀","🛸","🚁","⛵","🚤","🏠","🏢","🏥","🏫","🏰","🗼","🗽","⛪","🕌","🌍","🌎","🌏","🌑","🌕","🌙","⭐","🌟"],
        ["⚡","💥","🔥","✨","🌟","💫","🎉","🎊","🎈","🎆","🎇","✅","❌","❓","❗","⚠️","🔴","🟠","🟡","🟢","🔵","🟣","⚫","⚪","🏁","🚩","🎌","🏳️","🇹🇷","💯","🔔","🎵","🎶","📸","💬","📌","📎","🔑","💡","🚀"]
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 2) {
                // Status Bar
                statusBar
                
                // Pages
                switch currentPage {
                case .letters:
                    lettersPage
                case .numbers:
                    numbersPage
                case .symbols:
                    symbolsPage
                case .emoji:
                    emojiPage
                }
                
                bottomRow
            }
            
            // Tone Menu Overlay
            if showToneMenu {
                toneMenuOverlay
            }
            
            // Long Press Alternates Popup
            if longPressKey != nil && !longPressAlts.isEmpty {
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
                    Spacer()
                }
                .padding(.top, 20)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isDark ? Color(red: 0.07, green: 0.07, blue: 0.1) : Color(red: 0.82, green: 0.83, blue: 0.85))
        .simultaneousGesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height < -60 {
                        withAnimation(.easeOut(duration: 0.15)) { showToneMenu = true }
                    } else if value.translation.height > 60 {
                        guard controller.hasFullAccess else {
                            requestFullAccess()
                            return
                        }
                        let text = proxy.documentContextBeforeInput ?? ""
                        if !text.isEmpty {
                            translateText(text)
                        } else {
                            statusMessage = "Type something first"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { statusMessage = "Nova AI Ready" }
                        }
                    } else if value.translation.width < -60 {
                        guard controller.hasFullAccess else {
                            requestFullAccess()
                            return
                        }
                        let text = proxy.documentContextBeforeInput ?? ""
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
    
    // MARK: - Status Bar
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
                    proxy.insertText(UIPasteboard.general.string ?? "")
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
    
    // MARK: - Letters Page
    var lettersPage: some View {
        VStack(spacing: 6) {
             HStack(spacing: 3) {
                ForEach(cachedRow1, id: \.self) { key in charKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
            
            HStack(spacing: 3) {
                ForEach(cachedRow2, id: \.self) { key in charKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
            
            HStack(spacing: 3) {
                Button {
                    playKeySound()
                    if isShifted && !isCapsLocked {
                        isCapsLocked = true
                    } else if isCapsLocked {
                        isCapsLocked = false
                        isShifted = false
                    } else {
                        isShifted = true
                    }
                } label: {
                    Image(systemName: isCapsLocked ? "capslock.fill" : (isShifted ? "shift.fill" : "shift"))
                        .font(.system(size: 15))
                        .foregroundColor((isShifted || isCapsLocked) ? .black : (isDark ? .white : .black))
                        .frame(width: 42, height: customKeyHeight)
                        .background(RoundedRectangle(cornerRadius: 5).fill((isShifted || isCapsLocked) ? Color(red: 0, green: 0.8, blue: 0.85) : (isDark ? Color.white.opacity(0.15) : Color(white: 0.72))))
                }.buttonStyle(PlainButtonStyle())
                
                ForEach(cachedRow3, id: \.self) { key in charKey(key) }
                
                deleteButton
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
        }
    }
    
    // MARK: - Numbers Page
    var numbersPage: some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(numRow1, id: \.self) { key in specialCharKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
            
            HStack(spacing: 3) {
                ForEach(numRow2, id: \.self) { key in specialCharKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
            
            HStack(spacing: 3) {
                Button {
                    playKeySound()
                    currentPage = .symbols
                } label: {
                    Text("#+=")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isDark ? .white : .black)
                        .frame(height: customKeyHeight).frame(width: 40)
                        .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.95)))
                }.buttonStyle(PlainButtonStyle())
                
                ForEach(numRow3, id: \.self) { key in specialCharKey(key) }
                
                deleteButton
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
        }
    }
    
    // MARK: - Symbols Page
    var symbolsPage: some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(symRow1, id: \.self) { key in specialCharKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
            
            HStack(spacing: 3) {
                ForEach(symRow2, id: \.self) { key in specialCharKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
            
            HStack(spacing: 3) {
                Button {
                    playKeySound()
                    currentPage = .numbers
                } label: {
                    Text("123")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(isDark ? .white : .black)
                        .frame(height: customKeyHeight).frame(width: 40)
                        .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.95)))
                }.buttonStyle(PlainButtonStyle())
                
                ForEach(symRow3, id: \.self) { key in specialCharKey(key) }
                
                deleteButton
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
        }
    }
    
    // MARK: - Emoji Page (7 Categories, Scrollable Grid)
    var emojiPage: some View {
        VStack(spacing: 2) {
            // Category Selector
            HStack(spacing: 6) {
                ForEach(0..<emojiCatIcons.count, id: \.self) { i in
                    Button {
                        selectedEmojiCategory = i
                        playKeySound()
                    } label: {
                        Text(emojiCatIcons[i])
                            .font(.system(size: 18))
                            .frame(width: 30, height: 28)
                            .background(selectedEmojiCategory == i ? Color(red: 0, green: 0.8, blue: 0.85).opacity(0.3) : Color.clear)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // Emoji Grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 8), spacing: 4) {
                    ForEach(emojiData[selectedEmojiCategory], id: \.self) { emoji in
                        Button {
                            proxy.insertText(emoji)
                            playKeySound()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity).frame(height: 36)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Bottom Row (Shared)
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
                proxy.insertText(",")
                playKeySound()
            } label: {
                Text(",")
                    .font(.system(size: 18))
                    .foregroundColor(isDark ? .white : .black)
                    .frame(width: 28, height: customKeyHeight)
                    .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.15) : Color(white: 0.72)))
            }.buttonStyle(PlainButtonStyle())
            
            // Space Bar with Cursor Control
            Button {
                let now = Date()
                if now.timeIntervalSince(lastSpaceTime) < 0.3 {
                    proxy.deleteBackward()
                    proxy.insertText(". ")
                    shouldAutoCapitalize = true
                    isShifted = true
                } else {
                    proxy.insertText(" ")
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
                        if abs(value.translation.width) > 20 {
                            isSpaceDragging = true
                            let newOffset = Int(value.translation.width / 8)
                            let diff = newOffset - lastCursorOffset
                            if diff != 0 {
                                proxy.adjustTextPosition(byCharacterOffset: diff)
                                lastCursorOffset = newOffset
                                if hapticEnabled {
                                    selectionGenerator.selectionChanged()
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        isSpaceDragging = false
                        lastCursorOffset = 0
                    }
            )
            
            Button {
                proxy.insertText(".")
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
                proxy.insertText("\n")
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
    
    // MARK: - Turkish Lowercase Helper
    func turkishLowercase(_ key: String) -> String {
        if keyboardLayout == "Turkish" {
            if key == "I" { return "\u{0131}" }
            if key == "\u{0130}" { return "i" }
            return key.lowercased(with: NovaKeyboardView.turkishLocale)
        }
        return key.lowercased()
    }
    
    // MARK: - Character Key (Letters) with Long-Press Alternates
    func charKey(_ key: String) -> some View {
        let displayChar = (isShifted || isCapsLocked) ? key : turkishLowercase(key)
        return Button {
            playKeySound()
            proxy.insertText(displayChar)
            if !isCapsLocked { isShifted = false }
            shouldAutoCapitalize = false
            checkShortcuts()
            updateAutoCapitalize()
        } label: {
            Text(displayChar)
                .font(.system(size: customFontSize, weight: .regular, design: .rounded))
                .foregroundColor(isDark ? .white : .black)
                .frame(maxWidth: .infinity).frame(height: customKeyHeight)
                .background(RoundedRectangle(cornerRadius: 5).fill(
                    longPressKey == key ? Color(red: 0, green: 0.8, blue: 0.85).opacity(0.3) : (isDark ? Color.white.opacity(0.1) : Color.white)
                ))
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    if let alts = NovaKeyboardView.altChars[key.uppercased()], !alts.isEmpty {
                        longPressKey = key
                        longPressAlts = (isShifted || isCapsLocked) ? alts : alts.map { turkishLowercase($0) }
                        selectedAltIndex = -1
                        if hapticEnabled { selectionGenerator.selectionChanged() }
                    }
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    guard longPressKey != nil, !longPressAlts.isEmpty else { return }
                    let idx = Int(value.translation.width / 34)
                    let clamped = max(0, min(longPressAlts.count - 1, idx))
                    if clamped != selectedAltIndex {
                        selectedAltIndex = clamped
                        if hapticEnabled { selectionGenerator.selectionChanged() }
                    }
                }
                .onEnded { _ in
                    if longPressKey != nil && selectedAltIndex >= 0 && selectedAltIndex < longPressAlts.count {
                        let alt = longPressAlts[selectedAltIndex]
                        proxy.insertText(alt)
                        playKeySound()
                        if !isCapsLocked { isShifted = false }
                    }
                    longPressKey = nil
                    longPressAlts = []
                    selectedAltIndex = -1
                }
        )
    }
    
    // MARK: - Special Character Key (Numbers/Symbols)
    func specialCharKey(_ key: String) -> some View {
        Button {
            playKeySound()
            proxy.insertText(key)
        } label: {
            Text(key)
                .font(.system(size: customFontSize, weight: .regular))
                .foregroundColor(isDark ? .white : .black)
                .frame(maxWidth: .infinity).frame(height: customKeyHeight)
                .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.1) : Color.white))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Delete Button
    var deleteButton: some View {
        Button {} label: {
            Image(systemName: "delete.left")
                .font(.system(size: 15))
                .foregroundColor(isDark ? .white : .black)
                .frame(width: 42, height: customKeyHeight)
                .background(RoundedRectangle(cornerRadius: 5).fill(isDark ? Color.white.opacity(0.15) : Color(white: 0.72)))
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if deleteTimer == nil {
                        proxy.deleteBackward()
                        playKeySound()
                        // İlk silmeden sonra 0.4s bekle, sonra hızlı tekrarla
                        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                            self.deleteTimer?.invalidate()
                            self.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
                                self.proxy.deleteBackward()
                            }
                        }
                    }
                }
                .onEnded { _ in
                    deleteTimer?.invalidate()
                    deleteTimer = nil
                    updateAutoCapitalize()
                }
        )
    }
    

    
    // MARK: - Tone Menu Overlay
    var toneMenuOverlay: some View {
        VStack {
            HStack(spacing: 6) {
                ForEach(tones, id: \.self) { tone in
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
    
    // MARK: - Sound (Pre-allocated generator)
    func playKeySound() {
        if keySoundsEnabled { AudioServicesPlaySystemSound(1104) }
        if hapticEnabled { impactGenerator.impactOccurred() }
    }
    
    // MARK: - Request Full Access (opens Settings)
    func requestFullAccess() {
        statusMessage = "⚠️ Full Access required → Opening Settings..."
        if let kvc = controller as? KeyboardViewController {
            kvc.openAppSettings()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.statusMessage = "Nova AI Ready" }
    }
    
    // MARK: - Auto-Capitalize
    func updateAutoCapitalize() {
        let context = proxy.documentContextBeforeInput ?? ""
        if context.isEmpty {
            shouldAutoCapitalize = true
            isShifted = true
            return
        }
        let trimmed = context.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasSuffix(".") || trimmed.hasSuffix("!") || trimmed.hasSuffix("?") || trimmed.hasSuffix("\n") {
            shouldAutoCapitalize = true
            if !isCapsLocked { isShifted = true }
        }
    }
    
    // MARK: - AI Actions
    func rewriteText(tone: String) {
        guard !isProcessing else { return }
        guard controller.hasFullAccess else {
            requestFullAccess()
            return
        }
        let text = proxy.documentContextBeforeInput ?? ""
        guard !text.isEmpty else { return }
        isProcessing = true
        statusMessage = "Rewriting..."
        
        NovaAIEngine.shared.request(
            prompt: "Rewrite this text to be more \(tone). Return ONLY the rewritten text, nothing else: \(text)"
        ) { result in
            self.applyResult(result, originalText: text)
        }
    }
    
    func translateText(_ text: String) {
        guard !isProcessing else { return }
        isProcessing = true
        let s = UserDefaults(suiteName: "group.com.soner.NovaAI")
        let nativeLang = s?.string(forKey: "native_language") ?? "Turkish"
        let targetLang = s?.string(forKey: "target_language") ?? "English"
        statusMessage = "Translating..."
        
        NovaAIEngine.shared.request(
            prompt: "Translate the following text from \(nativeLang) to \(targetLang). Return ONLY the translation, nothing else: \(text)"
        ) { result in
            self.applyResult(result, originalText: text)
        }
    }
    
    func applyResult(_ result: Result<String, NovaAIEngine.AIError>, originalText: String) {
        isProcessing = false
        switch result {
        case .success(let newText):
            // Verify text hasn't changed during async request
            let currentContext = proxy.documentContextBeforeInput ?? ""
            guard currentContext.hasSuffix(originalText) else {
                // Text changed — do NOT delete, just show warning
                statusMessage = "Text changed. Cancelled."
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.statusMessage = "Nova AI Ready" }
                return
            }
            for _ in 0..<originalText.count { proxy.deleteBackward() }
            proxy.insertText(newText)
            statusMessage = "Done!"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .failure(let error):
            switch error {
            case .noApiKey: statusMessage = "Set API Key first"
            case .networkError: statusMessage = "Network error"
            case .unauthorized: statusMessage = "Invalid API Key"
            case .rateLimited: statusMessage = "Rate limited. Wait a moment."
            case .serverError(let code): statusMessage = "Server error (\(code))"
            case .parseError: statusMessage = "Error. Try again."
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
    
    // MARK: - Load Cached Settings (called once on appear)
    func loadCachedSettings() {
        let s = UserDefaults(suiteName: "group.com.soner.NovaAI")
        let h = s?.double(forKey: "key_height") ?? 42
        customKeyHeight = h >= 30 ? CGFloat(h) : 42
        let f = s?.double(forKey: "font_size") ?? 22
        customFontSize = f >= 14 ? CGFloat(f) : 22
        keySoundsEnabled = s?.bool(forKey: "key_sounds") ?? true
        hapticEnabled = s?.bool(forKey: "haptic_feedback") ?? true
        keyboardLayout = s?.string(forKey: "keyboard_layout") ?? "Turkish"
        
        cachedRow1 = keyboardLayout == "Turkish" ? ["Q","W","E","R","T","Y","U","I","O","P","Ğ","Ü"] : ["Q","W","E","R","T","Y","U","I","O","P"]
        cachedRow2 = keyboardLayout == "Turkish" ? ["A","S","D","F","G","H","J","K","L","Ş","İ"] : ["A","S","D","F","G","H","J","K","L"]
        cachedRow3 = keyboardLayout == "Turkish" ? ["Z","X","C","V","B","N","M","Ö","Ç"] : ["Z","X","C","V","B","N","M"]
    }
    
    // MARK: - AI Spell Check
    func spellCheckText(_ text: String) {
        guard !isProcessing else { return }
        guard controller.hasFullAccess else {
            requestFullAccess()
            return
        }
        isProcessing = true
        statusMessage = "Fixing..."
        let s = UserDefaults(suiteName: "group.com.soner.NovaAI")
        let lang = s?.string(forKey: "native_language") ?? "Turkish"
        let prompt = "The text was written in \(lang). Fix spelling and grammar only in \(lang). Do not translate or use words from other languages. Keep the same meaning and tone. Return ONLY the corrected text, nothing else: \(text)"
        NovaAIEngine.shared.request(prompt: prompt) { result in
            self.applyResult(result, originalText: text)
        }
    }
    
    // MARK: - Text Shortcuts
    func loadShortcuts() {
        guard let jsonStr = shared?.string(forKey: "text_shortcuts"),
              let data = jsonStr.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return }
        cachedShortcuts = dict
    }
    
    func checkShortcuts() {
        if cachedShortcuts.isEmpty { return }
        let context = proxy.documentContextBeforeInput ?? ""
        for (trigger, replacement) in cachedShortcuts {
            if context.hasSuffix(trigger) {
                for _ in 0..<trigger.count { proxy.deleteBackward() }
                proxy.insertText(replacement)
                playKeySound()
                break
            }
        }
    }
}

// MARK: - Nova AI Engine (Groq / Llama 3.3 70B)
class NovaAIEngine {
    static let shared = NovaAIEngine()
    
    enum AIError: Error {
        case noApiKey
        case networkError
        case unauthorized
        case rateLimited
        case serverError(Int)
        case parseError
    }
    
    private var groqKey: String {
        UserDefaults(suiteName: "group.com.soner.NovaAI")?.string(forKey: "groq_api_key") ?? ""
    }
    
    func request(prompt: String, completion: @escaping (Result<String, AIError>) -> Void) {
        if groqKey.isEmpty {
            DispatchQueue.main.async { completion(.failure(.noApiKey)) }
            return
        }
        
        let endpoint = "https://api.groq.com/openai/v1/chat/completions"
        
        let body: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        guard let url = URL(string: endpoint),
              let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async { completion(.failure(.parseError)) }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(groqKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 15
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(.failure(.networkError)) }
                return
            }
            
            // HTTP status differentiation
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: break
                case 401:
                    DispatchQueue.main.async { completion(.failure(.unauthorized)) }
                    return
                case 429:
                    DispatchQueue.main.async { completion(.failure(.rateLimited)) }
                    return
                case 400, 402...428, 430...499:
                    DispatchQueue.main.async { completion(.failure(.serverError(httpResponse.statusCode))) }
                    return
                case 500...599:
                    DispatchQueue.main.async { completion(.failure(.serverError(httpResponse.statusCode))) }
                    return
                default: break
                }
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let text = message["content"] as? String {
                let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
                DispatchQueue.main.async { completion(.success(clean)) }
            } else {
                DispatchQueue.main.async { completion(.failure(.parseError)) }
            }
        }.resume()
    }
}
