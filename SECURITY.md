# Security

## API key

- The Groq API key is stored in **shared App Group `UserDefaults`** so the host app and keyboard extension can read it.
- It is **not** sent to any server except **Groq** as the `Authorization: Bearer` header when you use AI gestures.
- Anyone with device access could extract app data from a jailbroken or compromised device; this is expected for a sideloaded utility.

## Data sent to Groq

When you use **swipe translate**, **tone shift**, or **spell check**, the relevant text (from the keyboard’s document context) is sent to **Groq’s API** over HTTPS. See [Groq’s policies](https://groq.com/privacy) for how they handle requests.

## Reporting issues

For security-sensitive bugs in **this repository’s code** (not Groq’s service), please open a **private security advisory** on GitHub or contact the maintainer via GitHub profile.
