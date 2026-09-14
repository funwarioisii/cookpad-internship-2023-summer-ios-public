# Swift 6で通信を扱う

Chapter 4・6で使う `async/await` は、2026年版でも引き続き使います。Swift 6への移行で見直すのは、複数の処理から同じデータにアクセスしても安全かどうかです。コンパイラが確認できるよう、通信クライアントと送受信する型に、その扱いを明示します。

## 画面の状態をMainActorで扱う

この教材では、画面の状態を持つモデルと通信クライアントに `@MainActor` を付けています。これらの可変データへのアクセスをMainActorに揃え、同時に書き換えられないようにします。

APIClientには `Sendable` への準拠も求めています。`Sendable` は、並行して動く処理の間で安全に渡せる型であることを表します。通信クライアントはMainActorで保護し、リクエストとレスポンスは `Sendable` な値型として定義することで、`async let` の子タスクにも渡せるようにしています。

## 通信を待つ間、画面は動くのか

`async` は「別のスレッドで実行する」という指定ではありません。ただし、`URLSession.data(for:)` は通信の完了を待つ間、タスクの実行を中断できます。MainActorから呼び出しても、通信を待つために画面の操作を止め続けるわけではありません。

一方、大量のデータを変換するなど、時間のかかる同期処理をMainActorで行うと、画面の応答が遅くなります。処理時間を調べて問題があれば、別のactorや `@concurrent` な関数へ移すことを検討します。

また、`await` で待っている間には、別の操作が実行されることがあります。関数の開始から終了まで、ほかの処理が一切入らないという意味ではありません。

## 順番に取得するか、並行して取得するか

一覧では、まずレシピを取得し、そのIDを使ってタグを取得します。後の通信が前の結果を必要とするため、順番に待ちます。

詳細とタグは、どちらもレシピIDさえあれば取得できます。この場合は `async let` で二つの通信を開始し、両方の結果を待てます。

```swift
async let detail = client.send(request: GetRecipeDetailRequest(recipeId: id))
async let tags = client.send(request: GetRecipeHashtagsRequest(recipeIds: [id]))
let (detailResponse, tagsResponse) = try await (detail, tags)
```

`async let` で作る子タスクは、この処理の範囲内で完了を待ちます。二つの結果がそろってから画面に使うことで、詳細だけ取得できてタグがまだない、といった途中の状態を扱わずに済みます。

## 送信データとキャンセル

タグを追加するPOSTでは、送信する項目を `Encodable` な構造体で定義し、`JSONEncoder` でJSONに変換します。`[String: Any]` の辞書を組み立てる方法に比べ、各項目の型がコードからわかるようになります。

通信がキャンセルされた場合、APIClientは通常の接続エラーと区別して `CancellationError` を返します。画面を閉じて不要になった取得処理まで、通信失敗として利用者に伝えないためです。なお、POSTの通信をキャンセルしても、サーバーで行われた更新を取り消せるとは限りません。

## このプロジェクトの設定

プロジェクトでは、次の設定を明示しています。

| 設定 | 値と目的 |
| --- | --- |
| Swift Language Version | Swift 6。並行処理に関する安全性のチェックを有効にします。 |
| Strict Concurrency Checking | Complete。Swift 6モードでは完全なチェックが行われます。 |
| Default Actor Isolation | nonisolated。MainActorで扱う型には `@MainActor` を明記します。 |
| Approachable Concurrency | Yes。呼び出し元のactorでnonisolatedなasync関数を実行する設定などを有効にします。 |
| iOS Deployment Target | iOS 17。Observationを利用できるバージョンを下限にします。 |

Default Actor IsolationとApproachable Concurrencyは別の設定です。新規プロジェクトを作るときの既定値だけに頼らず、このサンプルがどの前提で動くかを確認してください。

対応コード: [APIClient](../../MiniCookpad/Networking/APIClient/APIClient.swift)、[APIRequest](../../MiniCookpad/Networking/APIClient/APIRequest.swift)、[PostRecipeHashtagsRequest](../../MiniCookpad/Networking/Request/PostRecipeHashtagsRequest.swift)

参考: [Swift 6.2の変更点](https://www.swift.org/blog/swift-6.2-released/)、[Swift言語ガイドのConcurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
