# MiniCookpad

## 目標

レシピの一覧・詳細・タグ追加を作りながら、SwiftUIの状態管理、API通信、画面をまたぐデータ更新を学びます。成功画面に加えて、空・失敗・再試行・キャンセルの振る舞いまで実装します。

## 開発環境と設定

- Xcode 26.3以上（この版の検証環境はXcode 26.3）
- Swift 6言語モード、Strict Concurrency Checking: Complete
- Default Actor Isolation: nonisolated
- Approachable Concurrency: Yes
- Deployment Target: iOS 17（Observationを標準採用）

この教材では隔離境界を説明しやすいよう、UIモデル・Store・APIClientに `@MainActor` を明示します。新規Xcodeプロジェクトの既定値と同じとは限りません。最新版SDKに置き換えても、上記設定を確認してください。

## 進め方

このブランチは**完成サンプルを読み、変更を加えて理解する**構成です。まず動かし、各章の対応ファイルを読んでから章末の演習に取り組みます。2023年の `chN-initial` ブランチへの切り替えは行いません。

1. [Chapter 1: 起動とサンプルAPI](chapter_01.md)
2. [Chapter 2: 行のViewとレイアウト](chapter_02.md)
3. [Chapter 3: List・Identity・状態・画面遷移](chapter_03.md)
4. [Chapter 4: Observation・依存の受け渡し・非同期処理](chapter_04.md)
5. [Chapter 5: 詳細画面と状態の寿命](chapter_05.md)
6. [Chapter 6: タグ追加と画面間の同期](chapter_06.md)
7. [Chapter 7: Swift TestingとUIテスト](chapter_07.md)

[2026年版の設計と発展課題](modernization_2026.md)

## 作るもの

一覧からレシピを選び、材料・手順を確認します。詳細右上の「#」からタグを追加すると、詳細と一覧の両方に反映されます。サンプルAPIの変更はアプリを終了すると消えます。

以前の画面イメージは [MiniCookpad](minicookpad.md) にあります。2026年版では標準部品と環境に応じたレイアウトを優先するため、スクリーンショットと見た目は異なります。
