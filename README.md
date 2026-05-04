# Nova Keyboard AI 🧠⌨️

<p align="center">
  <img src="assets/banner.png" width="100%" alt="Nova Keyboard AI Banner">
</p>

A powerful, professional-grade AI-enhanced iOS keyboard extension built with SwiftUI. Designed for the sideloading community (TrollStore/AltStore) with a focus on privacy, performance, and advanced AI integration.

[![Version](https://img.shields.io/badge/Version-1.0.0-cyan.svg)](https://github.com/Son3ra1n/NovaKeyboardAI/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%2014.0%20--%2017.0+-lightgrey.svg)](#)

---

## ✨ Features

### 🎭 AI-Powered Intelligence
Nova isn't just a keyboard; it's an assistant. Using the **Groq API (Llama 3.3 70B)**, it brings desktop-class AI to your fingertips with zero latency.

<p align="center">
  <img src="assets/tone_menu.png" width="30%" alt="AI Tone Menu">
  <img src="assets/keyboard_dark.png" width="30%" alt="Dark Mode">
  <img src="assets/keyboard_light.png" width="30%" alt="Light Mode">
</p>

- **AI Tone Shift (Swipe Up):** Instantly rewrite any text to be Professional, Casual, Friendly, or Creative.
- **AI Translation (Swipe Down):** Real-time translation between 13+ languages.
- **AI Spell Check (Swipe Left):** Fix grammar and spelling errors instantly.
- **Rich Emoji Grid:** 300+ emojis organized into 7 searchable categories.
- **Smart Shortcuts:** Define custom triggers (e.g., `@@` → `your@email.com`).

### 🛠️ Professional Customization
Tailor the keyboard to your typing style.

<p align="center">
  <img src="assets/settings_main.png" width="45%" alt="Settings Main">
  <img src="assets/settings_setup.png" width="45%" alt="Gestures and Setup">
</p>

- **Dynamic Sizing:** Adjust Keyboard Height, Key Height, and Font Size.
- **Haptic & Sound:** Premium tactile feedback and key sounds.
- **Dual Layouts:** Full support for Turkish and English layouts.
- **Cursor Control:** Hold Space Bar + Drag for precise text navigation.

---

## 🔐 Privacy & Security

- **Bring Your Own Key (BYOK):** Use your own personal [Groq API Key](https://console.groq.com/keys).
- **On-Device Storage:** Your API key and shortcuts never leave your device.
- **Zero Analytics:** No tracking, no data collection.
- **Secure Handling:** Uses iOS App Groups for secure local storage.

---

## 📱 Requirements

- **iOS 14.0 - 17.0+** (Tested on TrollStore 2 & Sideloaded environments)
- **Groq API Key** (Free tier available)

---

## 🚀 Installation & Setup

1. **Sideload:** Install the `.tipa` via TrollStore or AltStore.
2. **Enable:** Go to `Settings > General > Keyboard > Keyboards > Add New Keyboard`.
3. **Full Access:** Select `Nova Keyboard AI` and toggle **Allow Full Access** (Required for AI features).
4. **Configure:** Open the Nova app, paste your Groq key, and you're ready!

---

## 🏗️ Performance Highlights

- **Cached Engine:** Zero `UserDefaults` reads during active typing.
- **Simultaneous Gestures:** Swipe detection doesn't block tap latency.
- **Static Locales:** Optimized for Turkish language processing.
- **SwiftUI + UIKit Hybrid:** The best of both worlds for performance and UI flexibility.

---

## 👤 Author

**Son3ra1n** — [GitHub](https://github.com/Son3ra1n) | [Reddit](https://reddit.com/u/Son3ra1n)

---

*Built with ❤️ and AI for the iOS Community.*
