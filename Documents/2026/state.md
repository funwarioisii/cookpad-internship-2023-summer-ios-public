# [Chapter 4 補足] Observation を使って ViewModel の変更を検知する

Chapter 4 では、ViewModel に取得したデータを保持し、そのデータを View に表示しました。
ここでは、`ObservableObject`を使っていた部分を、iOS 17 から利用できる Observation を使って書く方法を説明します。

- `@Observable`を使って property の変更を検知する方法
- ViewModel のインスタンスを`@State`で保持する方法
- 一覧と詳細で同じハッシュタグを表示する方法

について見ていきましょう。

前半では、Chapter 4 のコードを使って Observation に関する変更だけを説明します。完成サンプルではハッシュタグを共有するための`RecipeStore`も追加しているので、その部分は後半で説明します。

## ObservableObject から Observable に変更する

### RecipeListViewModel

まず、Chapter 4 で作成した`RecipeListViewModel`を見てみましょう。API 通信の部分を省略すると、以下のようになっていました。

```swift
@MainActor
final class RecipeListViewModel: ObservableObject {
    @Published var items: [RecipeListItem] = []
}
```

`ObservableObject` protocol に準拠し、`items` property に`@Published`属性を付けることで、View から変更を監視できるようにしていました。

Observation を使う場合は、`import Observation`を追加した上で、以下のように変更します。

```diff
 @MainActor
-final class RecipeListViewModel: ObservableObject {
-    @Published var items: [RecipeListItem] = []
+@Observable
+final class RecipeListViewModel {
+    var items: [RecipeListItem] = []
 }
```

`ObservableObject`への準拠を外し、クラスに`@Observable`を付けました。これにより、`items`に`@Published`を付けなくても、property の読み取りや変更を追跡できるようになります。

ここで追加した`@Observable`はマクロです。Chapter 4 では`@Published`などを Property Wrapper として説明しましたが、`@`で始まるものが全て Property Wrapper というわけではありません。今回はマクロの実装については割愛します。

### State

次に、View 側の書き方を見てみましょう。Chapter 4 では、ViewModel を`RecipeListView`内で作成するために`@StateObject`を使っていました。

`@Observable`を付けたクラスの場合は、以下のように`@State`を使います。

```diff
 struct RecipeListView: View {
-    @StateObject private var viewModel = RecipeListViewModel()
+    @State private var viewModel = RecipeListViewModel()
```

View の`body`では、これまでと同じように`viewModel.items`を使うことができます。

```swift
List(viewModel.items) { item in
    RecipeListRow(item: item)
}
```

これで、`items` property にサンプルデータや API から取得したデータを代入すると、一覧の表示も更新されるようになります。

では、`@Observable`を付けていても、なぜ`@State`が必要なのでしょうか。

Chapter 3 で説明したように、View の struct のインスタンスは、画面の更新に伴って作り直されます。`@State`を使うことで、同じ Identity の View が存続している間、SwiftUI が管理するストレージに ViewModel のインスタンスを保持できます。

`@Observable`は property の変更を追跡するための仕組みであり、インスタンスを保持するための仕組みではありません。以前`@StateObject`を使っていた箇所でも、Observation ではこの二つの役割を分けて考えます。

## どの property の変更で View が更新されるのか

ここまでは、属性を付け替えただけのように見えるかもしれません。では、変更を検知する仕組みにはどのような違いがあるのでしょうか。

ViewModel に、読み込み中かどうかを表す`isLoading` property がある場合を考えてみましょう。

```swift
// ObservableObject を使う場合
@Published var items: [RecipeListItem] = []
@Published var isLoading = false
```

`ObservableObject`を使う場合は、どちらの`@Published` property の変更も、そのオブジェクトを監視する View への通知になります。View が`items`しか表示していなくても、`isLoading`の変更は`body`が再び実行されるきっかけになります。

一方、Observation では、SwiftUI が`body`を実行した際に**実際に読んだ property**を追跡します。先程の`List(viewModel.items)`だけを表示している場合は、`items`の変更を追跡します。`isLoading`だけが変わっても、その変更によってこの View を更新する必要はありません。

それでは、読み込み中の表示も追加したらどうでしょうか。

```swift
VStack {
    if viewModel.isLoading {
        ProgressView()
    }
    List(viewModel.items) { item in
        RecipeListRow(item: item)
    }
}
```

今度は`if`の条件で`isLoading`を読んでいるため、この property の変更も追跡されます。つまり、Observation を使うと、View が表示に使っている property に応じて、変更を検知できるようになります。

(なお、親 View の更新など、他の理由で`body`が実行されることもあります。また、`body`が実行されることと、画面全体が描き直されることは同じではありません。)

## 他の View に ViewModel を渡す

ViewModel を作成する側では`@State`を使いました。では、既に作成された ViewModel を受け取る側はどう書けばよいのでしょうか。

表示するだけであれば、通常の property として受け取ることができます。

```swift
struct RecipeCountView: View {
    let viewModel: RecipeListViewModel

    var body: some View {
        Text("レシピ数: \(viewModel.items.count)")
    }
}
```

この場合も、`body`で`items`を読むことで変更が追跡されます。`ObservableObject`を受け取る時に使っていた`@ObservedObject`は必要ありません。

### Bindable

一方、Chapter 6 の入力画面では、ユーザーが入力した値を ViewModel に書き戻す必要があります。
`TextField`に渡す Binding を作るために、`@Bindable`を使ってみましょう。

以下は、完成サンプルの`AddRecipeHashtagsView`の`body`から抜粋したものです。

```swift
@Bindable var model = viewModel
TextField("#タグ1 #タグ2（スペース区切り）", text: $model.text, axis: .vertical)
```

`$model.text`を渡すことで、TextField が ViewModel の`text`を読み書きできるようになります。ここで新しい ViewModel を作っているわけではありません。View が`@State`で保持しているインスタンスに対して、Binding を作っています。

## 一覧と詳細でハッシュタグを共有する

ここからは完成サンプルの実装を見ていきます。

Chapter 6 では、ハッシュタグ追加画面を閉じた後に、詳細画面へ追加したハッシュタグを表示しました。一覧に戻った時にも同じハッシュタグを表示するには、どうすればよいでしょうか。

一覧と詳細がそれぞれハッシュタグの配列を持っていると、詳細側だけを更新しても一覧には反映されません。そこで今回は、ハッシュタグを保持する`RecipeStore`というクラスを作り、一覧と詳細から同じインスタンスを参照することにします。

これは画面間でデータを共有するための設計で、Observation を使うために必ず必要なものではありません。

### RecipeStore の受け渡し

[MiniCookpadApp.swift](../../MiniCookpad/MiniCookpadApp.swift) を開いてみましょう。アプリ側で一つの RecipeStore を作成し、View に引数として渡しています。View は受け取った Store を ViewModel の初期化時にも渡します。

一方、読み込み中かどうかやエラーメッセージなどは、画面ごとに異なるため、それぞれの ViewModel に保持します。

### `items` property

次に、完成サンプルの [RecipeListViewModel.swift](../../MiniCookpad/View/RecipeList/RecipeListViewModel.swift) を見てみましょう。前半の例と異なり、`items`は以下のような計算プロパティになっています。

```swift
var items: [RecipeListItem] {
    recipes.map {
        .init(recipe: $0, hashtags: store.hashtagsByRecipeID[$0.id, default: []])
    }
}
```

レシピのデータは`recipes`、ハッシュタグは Store の`hashtagsByRecipeID`から取得して、表示する項目を作っています。

View が`items`を読むと、この計算の中で`recipes`と`hashtagsByRecipeID`も読まれます。ViewModel と Store はどちらも`@Observable`を付けたクラスなので、この読み取りも追跡されます。計算プロパティを経由していても、元になったデータの変更を検知できるということです。

ハッシュタグの追加に成功すると、Store の`hashtagsByRecipeID`が更新されます。同じ Store の値を使っている一覧と詳細も、この変更に応じて表示が更新されます。

ここで、画面ごとに別の Store を作った場合を考えてみてください。`@Observable`が付いていても、別のインスタンスに入っているデータまで同じ値になるわけではありません。**同じ Store を渡すことでデータを共有し、Observation を使ってその変更を表示に反映している**、という関係になります。

(追跡する単位は`hashtagsByRecipeID`という辞書の property です。辞書の中のレシピ ID ごとに、別々の property として追跡しているわけではありません。)

ここまで読めたら、完成サンプルでハッシュタグを追加し、一覧へ戻ってみましょう。再取得をしなくても追加したハッシュタグが表示されていれば OK です。[RecipeListView](../../MiniCookpad/View/RecipeList/RecipeListView.swift) から [RecipeStore](../../MiniCookpad/Library/RecipeStore.swift) まで、同じインスタンスが渡されていることも確認してみてください。

## [補足] MainActor との違い

ViewModel には`@Observable`と`@MainActor`の両方を付けています。`@Observable`が property の変更を追跡する仕組みであるのに対し、`@MainActor`は、そのデータを扱う処理を MainActor 上で実行するための指定です。通信との関係は [Swift 6 と API 通信の補足](concurrency.md) で説明します。

Observation について詳しく知りたい方は、Apple の [移行ガイド](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro) や [Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/) も見てみてください。`ObservableObject`も引き続き利用できますが、今回は iOS 17 以降を対象に Observation を使っています。
