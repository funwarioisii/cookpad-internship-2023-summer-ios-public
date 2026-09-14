# Swift 6と通信の変更点

このページは2023年版のChapter 4・6に対する補足です。画面の状態共有と入力の変更は後続PRで扱います。

## 設定を明示する理由

Swift 6言語モード、Strict Concurrency Checking: Complete、Default Actor Isolation: nonisolated、Approachable Concurrency: Yesに揃えます。新規プロジェクトの既定値によってサンプルの説明が変わらないよう、隔離境界を明示するためです。Deployment Targetは、次のObservation移行に必要なiOS 17とします。

`@MainActor` を付けたAPIClientとUIモデルが、可変状態を保護します。APIClientはSendableを要求し、リクエストとレスポンスはSendableな値型にします。これにより `async let` の子タスクからもクライアントを安全に参照できます。グローバルapiClientはこの段階ではMainActorに隔離し、次のPRで初期化時の注入へ置き換えます。

## asyncと並行実行

`async` は別スレッドで実行するという指定ではありません。`URLSession.data(for:)` は通信待ちの間タスクを中断するため、MainActorを占有し続けません。一方、重い同期処理はUIの応答を遅らせます。必要なら計測したうえで別actorや `@concurrent` な関数へ移します。

一覧は取得したレシピIDがタグ取得に必要なので順にawaitします。詳細とタグはどちらもIDだけで取得できるため `async let` で同時に待てます。

Approachable Concurrencyのnonisolated asyncが呼び出し元のactorを引き継ぐ設定と、Default Actor Isolationは別の設定です。警告を消す目的で `@unchecked Sendable` を追加せず、状態を誰が管理するかを考えます。

## POSTとキャンセル

`PostRecipeHashtagsRequest.makeBody()` でEncodableなBodyをJSONEncoderに渡します。`[String: Any]` の辞書ではなく送信データの構造を型で表します。レスポンス名も `PostRecipeHashtagsResponse` に揃えます。

APIClientはURLSessionのキャンセルを通常の接続エラーで包まず、CancellationErrorとして上位へ返します。画面で失敗とキャンセルを区別するためです。POSTのキャンセルはサーバーの更新取り消しを保証しません。

対応コード: [APIClient](../../MiniCookpad/Networking/APIClient/APIClient.swift)、[APIRequest](../../MiniCookpad/Networking/APIClient/APIRequest.swift)、[POST](../../MiniCookpad/Networking/Request/PostRecipeHashtagsRequest.swift)

参考: [Swift 6.2](https://www.swift.org/blog/swift-6.2-released/)、[Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
