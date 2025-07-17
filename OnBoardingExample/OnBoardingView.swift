//
//  OnBoardingView.swift
//  OnBoardingExample
//
//  Created by cano on 2025/07/17.
//


import SwiftUI

// OnBoarding カードのデータ構造（Identifiableに準拠）
struct OnBoardingCard: Identifiable {
    var id: String = UUID().uuidString
    var symbol: String
    var title: String
    var subTitle: String
}

// OnBoardingカードを複数構築できるカスタム resultBuilder
@resultBuilder
struct OnBoardingCardResultBuilder {
    static func buildBlock(_ components: OnBoardingCard...) -> [OnBoardingCard] {
        components.compactMap { $0 }
    }
}

// OnBoarding全体ビュー（アイコン・カード・フッターを受け取る汎用View）
struct OnBoardingView<Icon: View, Footer: View>: View {
    var tint: Color
    var title: String
    var icon: Icon
    var cards: [OnBoardingCard]
    var footer: Footer
    var onContinue: () -> ()

    // イニシャライザ（@ViewBuilder / @resultBuilder を使用）
    init(
        tint: Color,
        title: String,
        @ViewBuilder icon: @escaping () -> Icon,
        @OnBoardingCardResultBuilder cards: @escaping () -> [OnBoardingCard],
        @ViewBuilder footer: @escaping () -> Footer,
        onContinue: @escaping () -> Void
    ) {
        self.tint = tint
        self.title = title
        self.icon = icon()
        self.cards = cards()
        self.footer = footer()
        self.onContinue = onContinue

        // カードの数だけアニメーションフラグを初期化
        self._animateCards = .init(initialValue: Array(repeating: false, count: self.cards.count))
    }

    // アニメーション用の状態変数
    @State private var animateIcon: Bool = false
    @State private var animateTitle: Bool = false
    @State private var animateCards: [Bool]
    @State private var animateFooter: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // スクロールエリア（アイコン・タイトル・カード）
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    icon
                        .frame(maxWidth: .infinity)
                        .blurSlide(animateIcon)

                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .blurSlide(animateTitle)

                    CardsView()
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            // フッターと「Continue」ボタン
            VStack(spacing: 0) {
                footer

                Button(action: onContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    #if os(macOS)
                        .padding(.vertical, 8)
                    #else
                        .padding(.vertical, 4)
                    #endif
                }
                .tint(tint)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.bottom, 10)
            }
            .blurSlide(animateFooter)
        }
        .frame(maxWidth: 330) // 幅を制限
        .interactiveDismissDisabled() // スワイプで閉じるのを無効化
        .allowsHitTesting(animateFooter) // フッターが表示されるまで操作不可
        .task {
            // 各要素を順にアニメーション
            guard !animateIcon else { return }

            await delayedAnimation(isMac ? 0.1 : 0.35) {
                animateIcon = true
            }

            await delayedAnimation(0.2) {
                animateTitle = true
            }

            try? await Task.sleep(for: .seconds(0.2))

            for index in animateCards.indices {
                let delay = Double(index) * 0.1
                await delayedAnimation(delay) {
                    animateCards[index] = true
                }
            }

            await delayedAnimation(0.2) {
                animateFooter = true
            }
        }
        .setUpOnBoarding()
    }

    /// カード表示用View（アニメーション付き）
    @ViewBuilder
    func CardsView() -> some View {
        Group {
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: card.symbol)
                        .font(.title2)
                        .foregroundStyle(tint)
                        .symbolVariant(.fill)
                        .frame(width: 45)
                        .offset(y: 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.title)
                            .font(.title3)
                            .lineLimit(1)

                        Text(card.subTitle)
                            .lineLimit(2)
                    }
                }
                .blurSlide(animateCards[index])
            }
        }
    }

    /// 一定時間後にアニメーションを実行する非同期処理
    func delayedAnimation(_ delay: Double, action: @escaping () -> ()) async {
        try? await Task.sleep(for: .seconds(delay))
        withAnimation(.smooth) {
            action()
        }
    }
}

// MARK: - View拡張（カスタムアニメーションやデバイス対応）

extension View {
    /// ふわっとしたスライド表示アニメーション
    @ViewBuilder
    func blurSlide(_ show: Bool) -> some View {
        self
            .compositingGroup()
            .blur(radius: show ? 0 : 10)
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 100)
    }

    /// デバイスに応じた見た目設定
    @ViewBuilder
    fileprivate func setUpOnBoarding() -> some View {
        #if os(macOS)
        self
            .padding(.horizontal, 20)
            .frame(minHeight: 600)
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            if #available(iOS 18, *) {
                self
                    .presentationSizing(.fitted)
                    .padding(.horizontal, 25)
            } else {
                self
                    .padding(.bottom, 15)
            }
        } else {
            self
        }
        #endif
    }

    /// macOS判定フラグ
    fileprivate var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - プレビュー
#Preview {
    ContentView()
}
