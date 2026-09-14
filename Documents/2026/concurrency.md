# [Chapter 4・6 補足] Swift 6 と API 通信

Chapter 4 では、`async`と`await`を使って API リクエストを送りました。2026 年版でも、API クライアントを呼び出して結果を待つ、という流れは同じです。

ここでは、Swift 6 のチェックに対応するために、API クライアントやリクエストの型に追加した指定を説明します。まずは API クライアントの定義から見ていきましょう。

## MainActor と Sendable

[APIClient.swift](../../MiniCookpad/Networking/APIClient/APIClient.swift) を開くと、`APIClient` protocol に以下のような指定があります。

```swift
@MainActor
protocol APIClient: AnyObject, Sendable {
    func send<Request: APIRequest>(request: Request) async throws -> Request.Response
}
```

Chapter 4 では、UI に関する状態をメインスレッドで変更するために、ViewModel に`@MainActor`を付けました。今回は API クライアントについても、内部の状態を MainActor 上で扱うようにしています。

もう一つ追加されている`Sendable`は何でしょうか。

Swift 6 では、並行して実行される処理の間で、データを安全に受け渡せるかどうかをコンパイラがチェックします。`Sendable`は、この受け渡しが安全な型であることを表す protocol です。ただ準拠を宣言すればよいわけではなく、その型のデータが安全に扱えることも確認されます。

今回の API クライアントは MainActor で内部の状態を保護します。また、[APIRequest](../../MiniCookpad/Networking/APIClient/APIRequest.swift) とレスポンスの型も`Sendable`に準拠させています。これにより、後で説明する`async let`の子タスクにも、クライアントや送受信するデータを渡せるようにしています。

## MainActor 上で通信を待つ

では、MainActor 上で通信を行うと、結果が返るまで画面の操作も止まってしまうのでしょうか。

API クライアントは`URLSession.data(for:)`を使って通信しています。このメソッドは、通信の完了を待つ間、タスクの実行を中断できます。その間は他の処理を実行できるため、通信を待つために MainActor を使い続けるわけではありません。

ここで、`async`は「別のスレッドで実行する」という意味ではないことに注意してください。例えば、大量のデータを変換する同期処理を MainActor 上で実行すると、その処理中は画面の応答が遅くなることがあります。

そのような場合は、まず処理時間を調べてみましょう。時間のかかる処理を別の actor や`@concurrent`な関数に移す方法もありますが、今回はその実装については割愛します。

## 二つの API リクエストを待つ

レシピとハッシュタグを取得する処理について、もう少し見てみましょう。

一覧では、レシピを取得した結果から ID の配列を作り、その ID を使ってハッシュタグを取得します。二つ目のリクエストには一つ目の結果が必要なので、順番に`await`します。

一方、詳細画面では既にレシピ ID がわかっています。詳細とハッシュタグのどちらも、その ID だけで取得できるため、以下のように`async let`を使えます。

```swift
async let detail = client.send(request: GetRecipeDetailRequest(recipeId: id))
async let tags = client.send(request: GetRecipeHashtagsRequest(recipeIds: [id]))
let (detailResponse, tagsResponse) = try await (detail, tags)
```

最初の二行でそれぞれ子タスクを作り、二つのリクエストを開始します。最後の行で両方の結果を待っているので、結果がそろってから表示するデータを作ることができます。

`async let`で作った子タスクは、この処理の範囲を抜けるまでに終了を待ちます。ボタン操作から`Task { ... }`を作る場合とは、タスクの管理のされ方が異なります。

## POST リクエストの body を作る

次に、Chapter 6 で使う [PostRecipeHashtagsRequest.swift](../../MiniCookpad/Networking/Request/PostRecipeHashtagsRequest.swift) を見てみましょう。

送信する JSON は、以下のように`Encodable`に準拠した struct から作成しています。

```swift
func makeBody() throws -> Data? {
    struct Body: Encodable {
        let recipe_id: Int64
        let value: String
    }
    return try JSONEncoder().encode(Body(recipe_id: recipeID, value: value))
}
```

`recipe_id`にはレシピ ID、`value`には入力したテキストを渡します。`[String: Any]`の辞書で組み立てる代わりに struct を使うことで、それぞれの項目にどの型の値を渡すかがわかるようになります。

## [補足 1] 通信のキャンセル

画面を閉じた時など、取得中のデータが不要になる場合があります。API クライアントでは、このような通信のキャンセルを通常の接続エラーと区別し、`CancellationError`として呼び出し元に返しています。

ViewModel 側でもキャンセルを区別することで、画面を閉じただけなのに通信失敗のメッセージを表示する、といったことを避けられます。

なお、ハッシュタグを追加する POST リクエストは、通信をキャンセルした時点でサーバー側の更新が終わっている場合もあります。通信をキャンセルすることと、保存したデータを取り消すことは別です。

## [補足 2] プロジェクトの設定

完成サンプルでは、以下の設定を使っています。新しくプロジェクトを作って試す場合は、設定も確認してみてください。

| 設定 | 値 |
| --- | --- |
| Swift Language Version | Swift 6 |
| Strict Concurrency Checking | Complete |
| Default Actor Isolation | nonisolated |
| Approachable Concurrency | Yes |
| iOS Deployment Target | iOS 17 |

Swift 6 モードでは、並行処理に関する完全なチェックが行われます。Default Actor Isolation は nonisolated にしているので、MainActor 上で扱う型には`@MainActor`を明記します。

Approachable Concurrency はこれとは別の設定で、nonisolated な async 関数を呼び出し元の actor で実行する設定などを有効にします。iOS の下限を 17 にしているのは、Observation を利用するためです。

詳しく知りたい方は、[Swift 6.2 の変更点](https://www.swift.org/blog/swift-6.2-released/) や [The Swift Programming Language の Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) も見てみてください。
