# Release checklist (maintainer)

Use this when publishing a version on GitHub **Releases** for TrollStore users.

- [ ] Bump **Marketing / build** version in Xcode if needed.
- [ ] **Archive** → **Distribute App** → **Development** or **Ad Hoc** (or workflow you use) → export `.ipa`.
- [ ] Rename or convert to **`.tipa`** for TrollStore if your pipeline uses that extension.
- [ ] Smoke test on device: add keyboard, **Full Access**, Groq key, translate + tone + spell check once.
- [ ] Create **GitHub Release** with tag `vX.Y.Z`, release notes (features / fixes).
- [ ] Attach **`NovaKeyboardAI.tipa`** (or `.ipa`) as the release asset — do not commit binaries to `main`.
- [ ] Confirm **README** “Releases” link matches your repo name if you rename the project.
