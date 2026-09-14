# Observationで画面を更新する

Chapter 4では、通信で取得したレシピをViewModelに保存し、Viewに表示しました。2026年版でも、この役割分担は同じです。変わるのは、**モデルの変更をSwiftUIが知る仕組み**です。ここでは、2023年版の書き方と比べながら、その違いを見ていきます。

## 同じ画面を二つの書き方で比べる

まず、レシピ名を表示するだけの小さな例で考えましょう。次の二つは比較用のコードなので、それぞれ別に試してください。

2023年版では、モデルを `ObservableObject` に準拠させ、変更を通知するプロパティに `@Published` を付けていました。Viewは `@StateObject` でモデルを保持します。

```swift
import SwiftUI

@MainActor
final class RecipeModel: ObservableObject {
    @Published var title = "オムライス"
    @Published var isLoading = false
}

struct RecipeView: View {
    @StateObject private var model = RecipeModel()

    var body: some View {
        Text(model.title)
    }
}
```

この書き方では、`title` と `isLoading` のどちらの変更も、モデルからViewへの通知になります。Viewが表示に使っていない `isLoading` の変更も、`body` を再評価するきっかけになります。

Observationを使う場合は、モデルに `@Observable` を付け、Viewでは `@State` で保持します。各プロパティの `@Published` は不要です。

```swift
import SwiftUI
import Observation

@MainActor
@Observable
final class RecipeModel {
    var title = "オムライス"
    var isLoading = false
}

struct RecipeView: View {
    @State private var model = RecipeModel()

    var body: some View {
        Text(model.title)
    }
}
```

SwiftUIは `body` の実行中に、どのプロパティが読まれたかを記録します。この例で読んでいるのは `title` だけです。そのため、`title` が変わると表示の更新が必要だとわかります。一方、`isLoading` だけが変わっても、ObservationによってこのViewの更新が必要になることはありません。

では、`body` に次の表示も加えたらどうでしょうか。

```swift
if model.isLoading {
    ProgressView()
}
```

条件を判定するために `isLoading` を読むようになるので、その変更も更新のきっかけになります。**モデル単位で変更の通知を受ける書き方から、表示に使ったプロパティの変更を追う書き方になった**、という違いです。なお、親Viewの更新など、Observation以外の理由で `body` が実行されることもあります。`body` の再評価が、そのまま画面全体の描き直しを意味するわけではありません。

## `@Observable` があっても `@State` を使う理由

`@Observable` と `@State` は、それぞれ役割が違います。

`@Observable` は、プロパティの読み取りや変更を追跡できるようにするマクロです。モデルのインスタンスを保存しておく機能ではありません。

SwiftUIのViewは構造体で、表示の更新に伴って作り直されます。画面の中で作ったモデルを `@State` に入れておくと、同じ画面として扱われている間、SwiftUIがモデルを保持してくれます。Viewが作り直されるたびに、入力や取得済みのデータを失わずに済みます。この役割は、以前 `@StateObject` が担っていたものです。

一方、親が保持しているモデルを子に渡して表示するだけなら、通常のプロパティで受け取れます。

```swift
struct RecipeTitleView: View {
    let model: RecipeModel

    var body: some View {
        Text(model.title)
    }
}
```

ここでも `body` が `title` を読むので、その変更は追跡されます。以前のように、受け取る側に `@ObservedObject` を付ける必要はありません。

## 入力欄につなぐときは `@Bindable`

`TextField` は、現在の値を読むだけでなく、入力された値をモデルへ書き戻します。そのために必要なのが `Binding` です。`@Observable` なモデルからBindingを作るときは、`@Bindable` を使います。

```swift
struct RecipeTitleEditor: View {
    @Bindable var model: RecipeModel

    var body: some View {
        TextField("レシピ名", text: $model.title)
    }
}
```

`$model.title` が、モデルの `title` と入力欄をつなぎます。`@Bindable` を付けても別のモデルを作るわけではなく、親から受け取ったインスタンスを編集します。

整理すると、モデルを画面内に保持するための `@State`、受け取って読むだけなら通常のプロパティ、入力欄へBindingを渡すための `@Bindable`、と使い分けます。これらをすべてのViewに付ける必要はありません。

## このアプリでは、なぜ一覧のタグも更新されるのか

完成サンプルではObservationへの移行に加え、**一覧と詳細が同じタグのデータを使う**ように設計を変えています。これはObservationを使うための必須条件ではなく、画面間でタグの表示が食い違うのを防ぐための変更です。

アプリの起動時に一つの `RecipeStore` を作り、一覧・詳細・タグ追加の各画面へ渡します。タグは、このStoreの `hashtagsByRecipeID` にレシピIDごとに保存します。各画面の読み込み状況やエラーメッセージは、その画面のViewModelに持たせます。

[RecipeListViewModel](../../MiniCookpad/View/RecipeList/RecipeListViewModel.swift) の `items` は、取得したレシピとStoreのタグを組み合わせる計算プロパティです。

```swift
var items: [RecipeListItem] {
    recipes.map {
        .init(recipe: $0, hashtags: store.hashtagsByRecipeID[$0.id, default: []])
    }
}
```

一覧の `body` が `items` を読むと、この計算の中で `recipes` と `store.hashtagsByRecipeID` も読まれます。ViewModelとStoreはどちらも `@Observable` なので、SwiftUIはこの読み取りも追跡できます。計算プロパティの結果を別途 `@Published` に保存し直す必要はありません。

タグを追加すると、次の順に表示へ反映されます。

1. タグ追加画面がStoreへ保存を依頼します。
2. 通信が成功したら、Storeが返ってきたタグを `hashtagsByRecipeID` に追加します。
3. 同じStoreのタグを読んでいる一覧と詳細で、更新後の内容が表示されます。

ここで追跡するのは `hashtagsByRecipeID` という辞書のプロパティです。レシピIDごとに別々のプロパティとして追跡しているわけではありません。

もし一覧と詳細で別々のStoreを作ったら、片方を更新しても、もう片方のデータは変わりません。**同じデータを渡すのがStoreを共有する設計、データの変更を表示につなぐのがObservation**です。この二つを分けて理解しましょう。

## 通信処理との関係

通信には待ち時間があるため、ViewModelにはデータだけでなく、読み込み中かどうかやエラーメッセージも持たせます。一覧では取得前・読み込み中・空の結果・失敗を区別し、失敗したら再試行できるようにしています。キャンセルは利用者に通信エラーとして表示しません。

モデルの `@MainActor` は、これらの状態へアクセスする場所を揃える指定です。Observationとは別の仕組みです。通信待ちとMainActorの関係は [Swift 6で通信を扱う](concurrency.md) で説明します。

実装を読むときは、[MiniCookpadApp](../../MiniCookpad/MiniCookpadApp.swift) でStoreを作る箇所から、[一覧画面](../../MiniCookpad/View/RecipeList/RecipeListView.swift)、ViewModel、[RecipeStore](../../MiniCookpad/Library/RecipeStore.swift) の順に追ってみてください。Storeを作るときに通信クライアントも渡すので、テストでは通信の結果を自由に変えられます。

## 確かめてみよう

- 小さな例の `body` にブレークポイントを置き、`title` と `isLoading` を変更したときの違いを比べてみましょう。次に `ProgressView` の条件を加えて、`isLoading` の変更も表示に使われることを確かめてください。
- タグを追加した後で一覧に戻り、再取得を呼び出さなくても追加したタグが表示されることを確認しましょう。どの画面が同じStoreを受け取っているか、コードで追ってみてください。

ObservationはiOS 17以降で利用できます。`ObservableObject` を使う既存コードをすべて書き換える必要はありません。この教材では、iOS 17以降を対象に新しく実装する方法として採用しています。

参考: Appleの [Observationへの移行ガイド](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)、[Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
