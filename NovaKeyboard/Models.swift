import Foundation

enum KeyboardPage {
    case letters
    case numbers
    case symbols
    case emoji
}

enum KeyboardLayouts {
    static let numRow1 = ["1","2","3","4","5","6","7","8","9","0"]
    static let numRow2 = ["-","/",":",";","(",")","₺","&","@","\""]
    static let numRow3 = [".",",","?","!","'"]

    static let symRow1 = ["[","]","{","}","#","%","^","*","+","="]
    static let symRow2 = ["_","\\","|","~","<",">","€","$","¥","•"]
    static let symRow3 = [".",",","?","!","'"]

    static let turkishRow1 = ["Q","W","E","R","T","Y","U","I","O","P","Ğ","Ü"]
    static let turkishRow2 = ["A","S","D","F","G","H","J","K","L","Ş","İ"]
    static let turkishRow3 = ["Z","X","C","V","B","N","M","Ö","Ç"]

    static let englishRow1 = ["Q","W","E","R","T","Y","U","I","O","P"]
    static let englishRow2 = ["A","S","D","F","G","H","J","K","L"]
    static let englishRow3 = ["Z","X","C","V","B","N","M"]

    static func rows(for layout: String) -> (row1: [String], row2: [String], row3: [String]) {
        if layout == "Turkish" {
            return (turkishRow1, turkishRow2, turkishRow3)
        }
        return (englishRow1, englishRow2, englishRow3)
    }
}

enum AlternateCharacters {
    static let map: [String: [String]] = [
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
}

enum AITones {
    static let all = ["Professional", "Casual", "Friendly", "Creative"]
}

enum EmojiCatalog {
    static let categoryIcons = ["😀","❤️","👋","🐶","🍕","🚗","⚡"]
    static let data: [[String]] = [
        ["😀","😃","😄","😁","😆","😅","🤣","😂","🙂","🙃","😉","😊","😇","🥰","😍","🤩","😘","😗","😚","😙","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🤫","🤔","🤐","🤨","😐","😑","😶","😏","😒","🙄","😬","😌","😔","😪","🤤","😴","😷","🤒","🤕","🤢","🤮","🤧","🥵","🥶","🥴","😵","🤯","🤠","🥳","😎","🤓","🧐","😕","😟","🙁","😮","😯","😲","😳","🥺","😨","😰","😥","😢","😭","😱","😖","😣","😞","😩","😫","😤","😡","😠","🤬","😈","👿","💀","💩","🤡","👻","👽","👾","🤖","😺","😸","😹","😻","😼","😽","🙀","😿","😾"],
        ["❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❣️","💕","💞","💓","💗","💖","💘","💝","💟","♥️","💑","💏","💍","💐","🌹","🌷","🌺","🌸","🌼","🌻"],
        ["👋","🤚","🖐","✋","🖖","👌","🤏","✌️","🤞","🤟","🤘","🤙","👈","👉","👆","🖕","👇","☝️","👍","👎","✊","👊","🤛","🤜","👏","🙌","👐","🤲","🤝","🙏","✍️","💅","🤳","💪","🦾","🦿","🦵","🦶","👂","👃","👀","👁","👅","👄"],
        ["🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🙈","🙉","🙊","🐔","🐧","🐦","🐤","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🐛","🦋","🐌","🐞","🐜","🐢","🐍","🦎","🐙","🦑","🦐","🦀","🐡","🐠","🐟","🐬","🐳","🐋","🦈"],
        ["🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🍈","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥒","🌶","🌽","🥕","🧄","🧅","🥔","🍠","🥐","🍞","🥖","🧀","🍗","🍖","🥩","🍳","🥞","🧇","🍕","🌭","🍔","🍟","🌮","🌯","🍿","🧂","🍰","🎂","🍩","🍪"],
        ["🚗","🚕","🚙","🚌","🚎","🏎","🚓","🚑","🚒","🚐","🚚","🚛","🚜","🏍","🛵","🚲","🛴","✈️","🚀","🛸","🚁","⛵","🚤","🏠","🏢","🏥","🏫","🏰","🗼","🗽","⛪","🕌","🌍","🌎","🌏","🌑","🌕","🌙","⭐","🌟"],
        ["⚡","💥","🔥","✨","🌟","💫","🎉","🎊","🎈","🎆","🎇","✅","❌","❓","❗","⚠️","🔴","🟠","🟡","🟢","🔵","🟣","⚫","⚪","🏁","🚩","🎌","🏳️","🇹🇷","💯","🔔","🎵","🎶","📸","💬","📌","📎","🔑","💡","🚀"]
    ]
}

enum AppGroupKeys {
    static let suiteName = "group.com.soner.NovaAI"

    static let nativeLanguage = "native_language"
    static let targetLanguage = "target_language"
    static let keyboardLayout = "keyboard_layout"
    static let keyboardHeight = "keyboard_height"
    static let keyHeight = "key_height"
    static let fontSize = "font_size"
    static let keySounds = "key_sounds"
    static let hapticFeedback = "haptic_feedback"
    static let groqApiKey = "groq_api_key"
    static let textShortcuts = "text_shortcuts"
}

extension Notification.Name {
    static let novaKeyboardDidAppear = Notification.Name("novaKeyboardDidAppear")
}

/// SharedSettings: multi-layer settings bridge that works across
/// host app ↔ keyboard extension, even without proper provisioning
/// (TrollStore, ad-hoc, etc).
///
/// Write path (host app):  saves to ALL layers
/// Read path (extension):  tries each layer until one succeeds
///
/// Layers:
///   1. App Group UserDefaults (suiteName) — standard iOS
///   2. File-based shared container — TrollStore fallback
///   3. Standard UserDefaults — last resort (only works with Full Access)
enum SharedSettings {

    private static let fileName = "nova_shared_settings.plist"

    // MARK: - Write (call from host app)

    static func save(_ dict: [String: Any]) {
        // Layer 1: App Group UserDefaults
        if let suite = UserDefaults(suiteName: AppGroupKeys.suiteName) {
            for (key, value) in dict {
                suite.set(value, forKey: key)
            }
            suite.synchronize()
        }

        // Layer 2: File-based plist in shared container
        if let url = fileURL() {
            let existing = (NSDictionary(contentsOf: url) as? [String: Any]) ?? [:]
            var merged = existing
            for (key, value) in dict {
                merged[key] = value
            }
            (merged as NSDictionary).write(to: url, atomically: true)
        }

        // Layer 3: Standard UserDefaults (keyboard can read with Full Access)
        for (key, value) in dict {
            UserDefaults.standard.set(value, forKey: "nova_\(key)")
        }
        UserDefaults.standard.synchronize()
    }

    // MARK: - Read (call from keyboard extension)

    static func string(forKey key: String) -> String? {
        // Layer 1: App Group UserDefaults
        if let suite = UserDefaults(suiteName: AppGroupKeys.suiteName),
           let val = suite.string(forKey: key), !val.isEmpty {
            return val
        }

        // Layer 2: File-based plist
        if let url = fileURL(),
           let dict = NSDictionary(contentsOf: url) as? [String: Any],
           let val = dict[key] as? String, !val.isEmpty {
            return val
        }

        // Layer 3: Standard UserDefaults (with "nova_" prefix)
        if let val = UserDefaults.standard.string(forKey: "nova_\(key)"), !val.isEmpty {
            return val
        }

        return nil
    }

    static func double(forKey key: String) -> Double? {
        if let suite = UserDefaults(suiteName: AppGroupKeys.suiteName) {
            if suite.object(forKey: key) != nil {
                return suite.double(forKey: key)
            }
        }
        if let url = fileURL(),
           let dict = NSDictionary(contentsOf: url) as? [String: Any],
           let val = dict[key] as? NSNumber {
            return val.doubleValue
        }
        if UserDefaults.standard.object(forKey: "nova_\(key)") != nil {
            return UserDefaults.standard.double(forKey: "nova_\(key)")
        }
        return nil
    }

    static func bool(forKey key: String, defaultValue: Bool = true) -> Bool {
        if let suite = UserDefaults(suiteName: AppGroupKeys.suiteName) {
            if suite.object(forKey: key) != nil {
                return suite.bool(forKey: key)
            }
        }
        if let url = fileURL(),
           let dict = NSDictionary(contentsOf: url) as? [String: Any],
           let val = dict[key] as? Bool {
            return val
        }
        if UserDefaults.standard.object(forKey: "nova_\(key)") != nil {
            return UserDefaults.standard.bool(forKey: "nova_\(key)")
        }
        return defaultValue
    }

    // MARK: - Shared container file URL

    private static func fileURL() -> URL? {
        // Try App Group container first
        if let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroupKeys.suiteName
        ) {
            return container.appendingPathComponent(fileName)
        }
        // Fallback: app's own documents (won't be shared, but at least won't crash)
        return nil
    }
}
