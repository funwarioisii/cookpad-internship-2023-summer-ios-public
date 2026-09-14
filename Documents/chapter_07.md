# Swift TestingとUIテスト

対応ファイル: [MiniCookpadTests.swift](../MiniCookpadTests/MiniCookpadTests.swift)、[MiniCookpadUITests.swift](../MiniCookpadUITests/MiniCookpadUITests.swift)

## テストを実行する

Xcodeで実行先にiOSシミュレーターを選び、Product → Test（⌘U）を実行します。サンプルAPIを使うため外部サーバーは不要です。

単体テストはSwift Testing、画面を操作するテストはXCTest/XCUIAutomationを使います。新しい単体テストを `@Test` な関数として定義し、`#expect` で期待を記述します。

```swift
@Test func emptyListDoesNotRequestTags() async {
    let client = TestClient()
    client.recipes = []
    let model = RecipeListViewModel(store: RecipeStore(client: client))
    await model.request()
    #expect(client.tagRequests == 0)
    #expect(model.hasLoaded && model.items.isEmpty)
}
```

## 何を検証するか

- 全角＃・空白・改行の正規化（引数付きテスト）。
- POSTのJSONキー・値・Content-Type。
- タグの返却順が違う場合、タグのないレシピがある場合。
- 空一覧ならタグAPIを呼ばないこと。
- 取得失敗→再試行→成功。
- キャンセル後の古い取得結果を適用しないこと。
- タグ追加が一覧と詳細に、再取得なしで反映されること。
- 同じIDのタグが重複しないこと。
- 古いGETがPOSTの後に返っても、新しいタグを上書きしないこと。
- 二重送信の防止、保存失敗時の入力保持、空入力の拒否。
- サンプルAPIで追加後の再取得にもタグが残ること。

Swift Testingはテストを並行に実行できるため、各テストが自分専用のクライアントとStoreを作ります。共有グローバルの差し替えはしません。

## 非同期テストの順序を制御する

「0.5秒待てば通信中のはず」のようなテストは不安定になります。テスト用Gateで応答を止め、テスト側が到達を確認してからPOST・キャンセル・応答再開を行います。

```swift
let load = Task { try await store.loadRecipes() }
await gate.waitUntilEntered()
try await store.addHashtags(recipeID: 1, value: "#新規")
gate.release()
_ = try await load.value
```

Gateはテスト専用です。通常のアプリ実装に待ち合わせ機構を増やすためのものではありません。

## UI操作の検証

UIテストはアプリを起動し、一覧→詳細→タグ入力→保存→詳細で確認→一覧へ戻って確認、の一連の流れを操作します。Viewとモデルの接続が合っていることを検証するためです。

同じロジックをUIテストで大量に繰り返す必要はありません。正規化のパターンや通信の順序は単体テストで、画面間の接続は少数のUIテストで確認します。

## 演習

1. テスト用APIのタグの順序を変えてもテストが通ることを確認する。
2. Storeの変更番号チェックを一時的に外し、古いGETのテストが失敗することを確認して戻す。
3. 発展: 通信待ちの間に詳細画面を閉じるUIテストを追加する。

参考: [Appleのテストガイド](https://developer.apple.com/documentation/xcode/testing)
