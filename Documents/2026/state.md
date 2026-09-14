# Observation・依存の受け渡し・非同期処理

対応ファイル:
- [RecipeListViewModel.swift](../../MiniCookpad/View/RecipeList/RecipeListViewModel.swift)
- [RecipeStore.swift](../../MiniCookpad/Library/RecipeStore.swift)
- [APIClient.swift](../../MiniCookpad/Networking/APIClient/APIClient.swift)
- [MiniCookpadApp.swift](../../MiniCookpad/MiniCookpadApp.swift)

このページはChapter 4の2026年版の差分です。元の教材本文は残し、置き換える状態管理と通信の説明をここにまとめます。Swift 6の設定については [通信の変更点](concurrency.md) も参照してください。

## View・ViewModel・Storeの役割

この教材では、Viewは表示と操作、ViewModelはその画面の読み込み状態、Storeは画面間で共有するタグとAPI通信を担当します。大きなアーキテクチャの採用を前提にせず、「どこが状態を所有するか」を明示するための分割です。

一覧と詳細が同じレシピのタグを別々に持つと、片方だけ更新される原因になります。`MiniCookpadApp` が一つの `RecipeStore` を所有し、各画面へ引数で渡します。APIクライアントもStoreの初期化時に渡します。

```swift
let store = RecipeStore(client: StubAPIClient())
let model = RecipeListViewModel(store: store)
```

実API・サンプルAPI・テスト用APIを、利用する場所で差し替えられます。グローバルな `apiClient` は作りません。

## Observation

`RecipeListViewModel` は `@Observable` なクラスです。

```swift
@MainActor
@Observable
final class RecipeListViewModel {
    let store: RecipeStore
    private var recipes: [GetRecipeListResponse.Recipe] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    var items: [RecipeListItem] {
        recipes.map {
            .init(recipe: $0, hashtags: store.hashtagsByRecipeID[$0.id, default: []])
        }
    }
    // initとrequest()は対応ファイルを参照。
}
```

SwiftUIはbodyの評価で実際に読んだObservableプロパティへの依存を追跡します。`items` の計算で読まれるStoreのタグも対象です。このためStoreのタグが変わると、各画面の表示へ反映されます。

| 用途 | 使用する仕組み |
| --- | --- |
| Viewがモデルを所有する | `@State` |
| 親から受け取ったモデルを読む | 通常のプロパティ |
| モデルの値へのBindingを作る | `@Bindable` |
| View階層にモデルを渡す | `.environment(model)` と `@Environment(Model.self)` |

完成版は依存関係を追いやすいよう引数渡しを使います。Environmentは、階層が深くなったときの発展課題です。

`@Observable` はマクロです。`@State` などと見た目が似ていても、`@` の付く機能をすべてProperty Wrapperと考えないでください。2023年の `ObservableObject`・`@Published`・`@StateObject`・`@ObservedObject` を使うコードは、古いOSをサポートするコードを読む際に学べます。

## MainActorとSwift 6

UIの可変状態は `@MainActor` で隔離します。ViewModelだけでなく、この小規模な教材ではStoreとAPIClientの操作もMainActorで行います。APIClientはMainActor隔離に加えて `Sendable` な契約を持ち、`async let` の子タスクから安全に参照できます。リクエストとレスポンスもSendableな値型にします。

ここで `async` は「バックグラウンドスレッドで実行する」の意味ではありません。`URLSession.data(for:)` の通信待ちではタスクを中断できるため、MainActor上から呼び出しても通信待ちの間UIを占有しません。一方、大量のJSON変換など同期処理が重ければMainActorを占有します。プロファイルしたうえで、必要な仕事を `@concurrent` な関数や別actorに移すのが発展課題です。

このプロジェクトはSwift 6モードとApproachable Concurrencyを有効にし、既定の隔離はnonisolatedに固定しています。Approachable Concurrencyではnonisolated asyncが呼び出し元のactorを引き継ぐ設定が含まれます。Default Actor Isolationとは別の設定です。警告を消すために `@unchecked Sendable` を追加するのではなく、可変状態を誰が保護するかを考えます。

## 順番に待つ場合・同時に待つ場合

一覧では、まずレシピを取得し、そのIDを使ってタグを取得します。後のリクエストが前の結果に依存するため、順番に待ちます。空の一覧ならタグAPIは呼びません。

詳細とタグはレシピIDさえあれば取得できるので、次のように同時に待てます。

```swift
async let detail = client.send(request: GetRecipeDetailRequest(recipeId: id))
async let tags = client.send(request: GetRecipeHashtagsRequest(recipeIds: [id]))
let (detailResponse, tagsResponse) = try await (detail, tags)
try Task.checkCancellation()
```

`async let` は構造化された子タスクです。`Task {}` で新しいタスクを作る場合と、寿命・キャンセルの関係が異なります。ボタン操作をasync処理へつなぐときは `Task {}` を使いますが、処理を誰が完了まで管理するかも決めます。

## loading・empty・error・cancelled

`request()` は重複した読み込みを防ぎ、開始時にisLoadingを設定し、`defer` で必ず解除します。

- 成功: レシピを保持してhasLoadedをtrueにする。
- 空: 成功した空配列として、空状態の説明を表示する。
- 失敗: 利用者向けの説明と再試行を表示する。以前のデータがある場合は保持する。
- キャンセル: エラーとして表示せず、不要な結果を適用しない。

APIClientではURLSessionのキャンセルを通常の接続エラーで包まないようにします。Storeは各GETの待機後にもキャンセルを確認します。`.task` のキャンセルだけで、以後の同期処理が自動で停止するわけではありません。

タグAPIの結果は `zip` で結合せず、レシピIDで対応付けます。返却順が変わったりタグのないレシピが省略されたりしても、一覧の行を落とさないためです。

## 演習

- 一覧と詳細が同じStoreを参照する経路を追う。
- `request()` の成功・空・失敗・キャンセルの分岐を確認する。
- グローバルapiClientを参照していた箇所が、初期化時に渡す依存へ変わったことを確認する。

参考: [Observationへの移行](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)、[Swift 6.2の並行処理](https://www.swift.org/blog/swift-6.2-released/)

[元のChapter 5](../chapter_05.md)
