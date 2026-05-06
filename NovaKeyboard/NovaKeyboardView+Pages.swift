import SwiftUI

extension NovaKeyboardView {

    var lettersPage: some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(cachedRow1, id: \.self) { key in charKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)

            HStack(spacing: 3) {
                ForEach(cachedRow2, id: \.self) { key in charKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)

            HStack(spacing: 3) {
                shiftButton

                ForEach(cachedRow3, id: \.self) { key in charKey(key) }

                deleteButton
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
        }
    }

    var numbersPage: some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(KeyboardLayouts.numRow1, id: \.self) { key in specialCharKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)

            HStack(spacing: 3) {
                ForEach(KeyboardLayouts.numRow2, id: \.self) { key in specialCharKey(key) }
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

                ForEach(KeyboardLayouts.numRow3, id: \.self) { key in specialCharKey(key) }

                deleteButton
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
        }
    }

    var symbolsPage: some View {
        VStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(KeyboardLayouts.symRow1, id: \.self) { key in specialCharKey(key) }
            }.padding(.horizontal, 3).frame(height: customKeyHeight)

            HStack(spacing: 3) {
                ForEach(KeyboardLayouts.symRow2, id: \.self) { key in specialCharKey(key) }
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

                ForEach(KeyboardLayouts.symRow3, id: \.self) { key in specialCharKey(key) }

                deleteButton
            }.padding(.horizontal, 3).frame(height: customKeyHeight)
        }
    }

    var emojiPage: some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                ForEach(0..<EmojiCatalog.categoryIcons.count, id: \.self) { i in
                    Button {
                        selectedEmojiCategory = i
                        playKeySound()
                    } label: {
                        Text(EmojiCatalog.categoryIcons[i])
                            .font(.system(size: 18))
                            .frame(width: 30, height: 28)
                            .background(selectedEmojiCategory == i ? Color(red: 0, green: 0.8, blue: 0.85).opacity(0.3) : Color.clear)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 8)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 8), spacing: 4) {
                    ForEach(EmojiCatalog.data[selectedEmojiCategory], id: \.self) { emoji in
                        Button {
                            engine.insertText(emoji)
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
}
