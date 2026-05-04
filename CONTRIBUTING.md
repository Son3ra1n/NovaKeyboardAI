# Contributing

Thanks for helping improve Nova Keyboard AI.

## Building

- Open `NovaKeyboardAI.xcodeproj` in Xcode.
- Select the **NovaKeyboardAI** scheme, a physical device (keyboard extensions do not run usefully in Simulator for all features), and set your **Signing** team for both targets:
  - `NovaKeyboardAI` (host app)
  - `NovaKeyboard` (extension)

## Forking with your own bundle ID

If you change the app or extension **bundle identifier**, you must keep the **App Group** in sync everywhere:

1. Xcode → Signing & Capabilities → App Groups (both targets): use the same group, e.g. `group.com.yourname.YourApp`.
2. Replace the suite name string in code (search the project for `group.com.soner.NovaAI`):
   - `NovaKeyboardAI/ContentView.swift`
   - `NovaKeyboard/KeyboardViewController.swift`
3. Update `NovaKeyboardAI/NovaKeyboardAI.entitlements` and `NovaKeyboard/NovaKeyboard.entitlements`.

Without matching App Groups, settings and the API key saved in the host app will not be visible to the keyboard extension.

## AI features

Groq is called only when the user triggers translation, tone rewrite, or spell check. Do not commit API keys; users supply their own in the host app.
