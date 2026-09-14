# ハッシュタグ追加と画面間の同期

対応ファイル:
- [AddRecipeHashtagsView.swift](../../MiniCookpad/View/AddRecipeHashtags/AddRecipeHashtagsView.swift)
- [AddRecipeHashtagsViewModel.swift](../../MiniCookpad/View/AddRecipeHashtags/AddRecipeHashtagsViewModel.swift)
- [PostRecipeHashtagsRequest.swift](../../MiniCookpad/Networking/Request/PostRecipeHashtagsRequest.swift)
- [RecipeStore.swift](../../MiniCookpad/Library/RecipeStore.swift)

このページはChapter 6の2026年版の差分です。

この教材のタグはレシピに紐付く簡略化された仕様です。

## 完成条件

1. 詳細画面の「#」でモーダルを開く。
2. 入力を正規化する（全角スペース→半角、全角＃→半角、前後の空白・改行除去）。
3. 空入力なら送信しない。送信中は再送信・編集・モーダルを閉じる操作を無効にする。
4. 失敗したら入力を残し、説明を表示して再試行できる。
5. 成功したらモーダルを閉じ、一覧と詳細の両方に新しいタグが表示される。

2023年版の成功アラートは省き、画面を閉じた後のタグ表示を成功のフィードバックにします。

## 入力をモデルへBindingする

ViewはAddRecipeHashtagsViewModelをStateで所有し、body内でBindingを作ります。

```swift
@Bindable var model = viewModel
TextField("#タグ1 #タグ2（スペース区切り）", text: $model.text, axis: .vertical)
```

`@Bindable` は値の所有者を変えるものではありません。モデルのプロパティへ書き込むためのBindingを作ります。フォームには標準の `Form`、`Section`、`Button` を使い、キーボードや文字サイズに応じてスクロールできるようにします。

## POSTのデータを型で表す

```swift
func makeBody() throws -> Data? {
    struct Body: Encodable {
        let recipe_id: Int64
        let value: String
    }
    return try JSONEncoder().encode(Body(recipe_id: recipeID, value: value))
}
```

`[String: Any]` で組み立てず、送信する構造をEncodableな値で表します。APIRequestはSendableで、Bodyは必要な時点でDataへ変換します。

## 二重送信とタスクの寿命

ボタンからは `Task { await viewModel.save() }` を呼びます。UIでボタンを無効化するだけでなく、save側でもcanSaveを確認して、同じ画面からの重複実行を防ぎます。isSavingは最初のawaitより前に設定します。

この教材では、利用者が始めたPOSTは完了まで待つ方針です。送信中はキャンセルボタンとインタラクティブなシート終了を無効にします。別の事情で画面が消えても、開始したTaskは自動でキャンセルせず、成功結果を共有Storeへ適用します。アプリ終了後も継続する仕組みではありません。

GETのキャンセルと違い、POSTの通信キャンセルやタイムアウトはサーバー側の更新取り消しを保証しません。画面内の二重タップ防止だけでは、再試行を含むサーバーの重複更新は防げません。実サービスではサーバーの冪等性・同名タグの扱いも設計します。

## 一覧と詳細を同期する

POSTのレスポンスは**追加したタグ**の配列です。Storeは既存タグにIDでマージし、同じIDは置き換えます。レスポンスでタグ全体を置き換えて既存タグを消さないようにします。

一覧と詳細は同じ `hashtagsByRecipeID` を読んでいるので、コールバックで各画面を再取得する必要がありません。シートを閉じたとき `onAppear` が呼ばれることにも依存しません。

## awaitの前後に別の操作が入る

MainActorは「一つのasync関数の開始から終了まで、他の操作を止める」仕組みではありません。await中に別の操作が実行されます。

たとえば古いタグのGETが待機中にPOSTが成功し、その後古いGETが返ると、新しいタグを消してしまうおそれがあります。StoreはレシピIDごとの変更番号をPOST成功時に進め、GET開始時と番号が違えばその結果のタグを適用しません。これはローカルのGET/POST競合を防ぐ仕組みで、サーバー側の更新順序や他端末との同期まで保証するものではありません。

## 演習

- 入力を全角の `＃夕食　＃簡単` にして送信結果を見る。
- タグ追加後、一覧へ戻る・再び詳細を開く・再読み込みする、のすべてで新しいタグが残ることを確認する。
- 失敗するAPIClientを注入して、失敗しても入力が残ることを確認する（失敗シナリオのStubは後続PRで追加）。
- Chapter 7のテストで、古いGETが新しいPOSTの後に返る状況を再現する。

テストの追加は後続PRで扱います。
