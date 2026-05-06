# Known Issues

## Keyboard Extension Limitations (iOS / App Store)

### Context Access
- `documentContextBeforeInput` may return `nil` or empty string in certain apps (banking apps, some WebViews, WKWebView-based fields). When this happens, AI operations (translate, rewrite, spell check) will copy results to clipboard instead of auto-replacing.
- Some apps limit the amount of text returned by `documentContextBeforeInput` to ~4000 characters.

### Full Access
- Without "Full Access" enabled in iOS Settings, the keyboard extension **cannot** read the App Group UserDefaults (where the Groq API key is stored). The keyboard will show a one-time alert directing users to enable it.
- Clipboard access also requires Full Access.

### Secure Text Fields
- iOS automatically disables custom keyboard extensions in password fields (`isSecureTextEntry`). This is by design and cannot be overridden.

### Timer / RunLoop
- Delete key repeat uses `Timer.scheduledTimer` which may pause during scroll events in certain views. This is a known iOS RunLoop limitation for keyboard extensions.

## AI / Network
- Groq API free tier has rate limits. Users may see "Rate limited. Wait a moment." during heavy usage.
- Network requests have a 15-second timeout. Slow connections may trigger "Network error" before completion.

## Gesture Conflicts
- In apps with complex gesture hierarchies (e.g., Maps, Games), the keyboard's swipe gestures (translate, spell check, tone shift) may occasionally conflict with the host app's gestures. A 1.5s cooldown between AI swipes mitigates double-triggers.

## Known App-Specific Behaviors
| App | Behavior |
|-----|----------|
| WhatsApp | Works normally |
| Notes | Works normally |
| Safari | Address bar is single-line; context limited |
| Telegram | Works normally |
| Banking apps | Secure fields block custom keyboard |
| Search bars | Context may be limited to visible text |
