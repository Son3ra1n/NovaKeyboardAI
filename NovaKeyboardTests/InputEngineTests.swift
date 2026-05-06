import XCTest
import UIKit

// MARK: - Mock Text Proxy

/// In-memory mock that simulates UITextDocumentProxy behavior.
/// Tracks insertions, deletions, and cursor adjustments.
final class MockTextProxy: TextProxyProtocol {
    var buffer: String = ""
    var cursorPosition: Int = 0
    var deleteCount: Int = 0
    var insertHistory: [String] = []
    var cursorAdjustments: [Int] = []

    var documentContextBeforeInput: String? {
        if buffer.isEmpty { return nil }
        let endIdx = buffer.index(buffer.startIndex, offsetBy: min(cursorPosition, buffer.count))
        return String(buffer[buffer.startIndex..<endIdx])
    }

    func insertText(_ text: String) {
        let idx = buffer.index(buffer.startIndex, offsetBy: min(cursorPosition, buffer.count))
        buffer.insert(contentsOf: text, at: idx)
        cursorPosition += text.count
        insertHistory.append(text)
    }

    func deleteBackward() {
        guard cursorPosition > 0 else { return }
        let idx = buffer.index(buffer.startIndex, offsetBy: cursorPosition - 1)
        buffer.remove(at: idx)
        cursorPosition -= 1
        deleteCount += 1
    }

    func adjustTextPosition(byCharacterOffset offset: Int) {
        cursorPosition = max(0, min(buffer.count, cursorPosition + offset))
        cursorAdjustments.append(offset)
    }

    /// Helper to set up buffer and cursor at end
    func setup(_ text: String) {
        buffer = text
        cursorPosition = text.count
        deleteCount = 0
        insertHistory = []
        cursorAdjustments = []
    }
}

// MARK: - InputEngine Tests

final class InputEngineTests: XCTestCase {

    var mock: MockTextProxy!
    var engine: InputEngine!

    override func setUp() {
        super.setUp()
        mock = MockTextProxy()
        engine = InputEngine(mockProxy: mock)
    }

    // MARK: - Basic Operations

    func testInsertText() {
        engine.insertText("Hello")
        XCTAssertEqual(mock.buffer, "Hello")
        XCTAssertEqual(mock.cursorPosition, 5)
    }

    func testDeleteBackward() {
        mock.setup("abc")
        engine.deleteBackward()
        XCTAssertEqual(mock.buffer, "ab")
        XCTAssertEqual(mock.deleteCount, 1)
    }

    func testDeleteBackwardOnEmpty() {
        mock.setup("")
        engine.deleteBackward()
        XCTAssertEqual(mock.buffer, "")
        XCTAssertEqual(mock.deleteCount, 0) // nothing to delete
    }

    func testAdjustCursor() {
        mock.setup("Hello World")
        engine.adjustCursor(by: -5)
        XCTAssertEqual(mock.cursorPosition, 6)
        XCTAssertEqual(mock.cursorAdjustments, [-5])
    }

    func testContextBeforeInput() {
        mock.setup("Hello World")
        XCTAssertEqual(engine.contextBeforeInput, "Hello World")
    }

    func testContextBeforeInputEmpty() {
        mock.setup("")
        XCTAssertEqual(engine.contextBeforeInput, "")
    }

    // MARK: - Auto-Capitalization

    func testAutoCapitalizeEmptyContext() {
        mock.setup("")
        XCTAssertTrue(engine.shouldAutoCapitalize())
    }

    func testAutoCapitalizeAfterPeriod() {
        mock.setup("Hello. ")
        XCTAssertTrue(engine.shouldAutoCapitalize())
    }

    func testAutoCapitalizeAfterExclamation() {
        mock.setup("Wow! ")
        XCTAssertTrue(engine.shouldAutoCapitalize())
    }

    func testAutoCapitalizeAfterQuestion() {
        mock.setup("Really? ")
        XCTAssertTrue(engine.shouldAutoCapitalize())
    }

    func testAutoCapitalizeAfterNewline() {
        mock.setup("Hello\n")
        XCTAssertTrue(engine.shouldAutoCapitalize())
    }

    func testNoAutoCapitalizeMidSentence() {
        mock.setup("Hello wo")
        XCTAssertFalse(engine.shouldAutoCapitalize())
    }

    func testAutoCapitalizeWhitespaceOnly() {
        mock.setup("   ")
        XCTAssertTrue(engine.shouldAutoCapitalize())
    }

    // MARK: - Safe Replace

    func testSafeReplaceSuccess() {
        mock.setup("Hello World")
        let result = engine.safeReplace(originalText: "World", with: "Swift")
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.reason, "Done!")
        XCTAssertEqual(mock.buffer, "Hello Swift")
    }

    func testSafeReplaceContextChanged() {
        mock.setup("Hello Swift")
        let result = engine.safeReplace(originalText: "World", with: "Swift")
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.reason, "Text changed. Cancelled.")
        // Buffer should be unchanged
        XCTAssertEqual(mock.buffer, "Hello Swift")
    }

    func testSafeReplaceEmptyContext() {
        mock.setup("")
        let result = engine.safeReplace(originalText: "test", with: "replacement")
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.reason.contains("Context lost"))
    }

    func testSafeReplaceExceedsMaxDeleteCap() {
        // Create text longer than 1200 chars
        let longText = String(repeating: "a", count: 1300)
        mock.setup(longText)
        let result = engine.safeReplace(originalText: longText, with: "short")
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.reason.contains("too long"))
        // Buffer should be unchanged
        XCTAssertEqual(mock.buffer, longText)
    }

    func testSafeReplaceExactlyAtCap() {
        let text = String(repeating: "b", count: 1200)
        mock.setup(text)
        let result = engine.safeReplace(originalText: text, with: "replaced")
        XCTAssertTrue(result.success)
        XCTAssertEqual(mock.buffer, "replaced")
    }

    func testSafeReplaceFullText() {
        mock.setup("Merhaba Dünya")
        let result = engine.safeReplace(originalText: "Merhaba Dünya", with: "Hello World")
        XCTAssertTrue(result.success)
        XCTAssertEqual(mock.buffer, "Hello World")
    }

    // MARK: - Shortcuts

    func testShortcutMatch() {
        mock.setup("brb")
        let shortcuts = ["brb": "be right back"]
        let matched = engine.checkAndApplyShortcut(shortcuts: shortcuts)
        XCTAssertTrue(matched)
        XCTAssertEqual(mock.buffer, "be right back")
    }

    func testShortcutNoMatch() {
        mock.setup("hello")
        let shortcuts = ["brb": "be right back"]
        let matched = engine.checkAndApplyShortcut(shortcuts: shortcuts)
        XCTAssertFalse(matched)
        XCTAssertEqual(mock.buffer, "hello")
    }

    func testShortcutEmptyDict() {
        mock.setup("brb")
        let matched = engine.checkAndApplyShortcut(shortcuts: [:])
        XCTAssertFalse(matched)
    }

    func testShortcutPartialMatch() {
        mock.setup("br")
        let shortcuts = ["brb": "be right back"]
        let matched = engine.checkAndApplyShortcut(shortcuts: shortcuts)
        XCTAssertFalse(matched)
    }

    func testShortcutMultiple() {
        mock.setup("omw")
        let shortcuts = ["brb": "be right back", "omw": "on my way", "ty": "thank you"]
        let matched = engine.checkAndApplyShortcut(shortcuts: shortcuts)
        XCTAssertTrue(matched)
        XCTAssertEqual(mock.buffer, "on my way")
    }

    // MARK: - Max Delete Cap Constant

    func testMaxDeleteCapValue() {
        XCTAssertEqual(InputEngine.maxDeleteCap, 1200)
    }
}
