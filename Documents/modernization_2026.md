# 2026年版の設計と発展課題

## このブランチで変えたこと

| 2023年版 | 2026年版 | 学ぶこと |
| --- | --- | --- |
| ObservableObject / Published | Observable / State / Bindable | 実際に読まれる状態への依存と所有 |
| グローバルapiClient | Storeへの初期化時の注入 | 依存の受け渡しとテスト |
| 一覧・詳細が個別にタグを保持 | レシピIDごとの共有Store | 画面間の一貫性 |
| 実行時の警告を見てMainActor追加 | Swift 6のチェックと明示的な隔離 | 非同期と並行、Sendable |
| 初期演習のTask.detached | Viewのtask | 寿命とキャンセル |
| print(error) | 失敗表示・再試行・入力保持 | 通信中も含めた操作の設計 |
| 固定レスポンスのStub | 状態を保持するStub | オフラインでの更新・再取得 |
| XCTestの単体テスト雛形 | Swift Testingと操作のUIテスト | 状態変化・競合・接続の検証 |
| 画面位置の固定補正 | Formと標準部品・意味に応じた色 | 文字サイズ・キーボード・ダークモード |

サポート下限はiOS 17にし、Xcode 26.3でビルドできるAPIを本編に採用します。新SDK限定の機能を使う際は、そのSDKと実行OSを揃えて確認します。

## 続けて学ぶ価値がある部分

SwiftUIのIdentity、Stateの寿命、List、NavigationStack、URLSessionのasync API、async letは引き続き中心です。ViewModelという分け方も、Observationの採用だけで不要になるわけではありません。

## 新しいSDKで進める場合

以下は本編コードでは未採用・未検証の発展事項です。

- **Stateのマクロ化と遅延初期化**: WWDC26では、ObservableクラスをStateで保持する際の余分な初期化を避ける変更が紹介されています。対応ツールチェーンでは初期化の説明を更新し、既定値とinitで二重に代入するパターンなどの互換性も確認します。
- **AsyncImageのキャッシュ設定**: WWDC26ではHTTPキャッシュへの対応改善、URLRequestとカスタムURLSessionの利用が紹介されています。画像の再取得回数・HTTPヘッダー・キャッシュポリシーを観察する課題にできます。サードパーティの画像ライブラリや独自キャッシュを導入する前に、必要な機能を確認します。
- **Liquid Glass**: 標準のNavigationStack・toolbar・Form・Buttonの外観を確認し、必要な操作部品だけカスタマイズします。レシピ本文全体をガラス素材にすることを目的にしません。
- **NavigationSplitView**: iPadの一覧・詳細同時表示。共有Storeを両方へ渡す構成を試せます。
- **Environmentでの依存の共有**: 深いView階層で引数が増えたときに検討します。最初からすべてを暗黙的な依存にしません。
- **重い処理の隔離**: InstrumentsでUIの応答を測り、重い同期処理だけを別actorや `@concurrent` な関数へ移します。

永続化が必要ならSwiftData等を比較する課題を追加できますが、この教材のAPI取得・更新に必須ではありません。

## 参照

- [Observationへの移行](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [Swift 6.2: Approachable Concurrency](https://www.swift.org/blog/swift-6.2-released/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [WWDC26: What's new in SwiftUI（State・AsyncImage）](https://developer.apple.com/videos/play/wwdc2026/269/)
- [WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Swift TestingとUIテスト](https://developer.apple.com/documentation/xcode/testing)
