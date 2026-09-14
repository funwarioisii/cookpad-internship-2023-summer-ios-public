# List・Identity・状態・画面遷移

対応ファイル: [RecipeListView.swift](../MiniCookpad/View/RecipeList/RecipeListView.swift)、[RecipeListItem.swift](../MiniCookpad/Entity/RecipeListItem.swift)

## ListとIdentity

```swift
List(viewModel.items) { item in
    NavigationLink(value: item.id) {
        RecipeListRow(item: item)
    }
}
```

`RecipeListItem` は `Identifiable` に準拠し、`recipe.id` を返します。SwiftUIはこのIDで行を識別します。同じレシピなら同じIDになり、別のレシピと重複しない値が必要です。並び替えるリストで配列の添字をIDにすると、行の状態が別の項目に対応してしまうことがあります。

明示的にIDを指定しないViewは、View階層内の型や位置による構造的Identityを持ちます。Viewの構造を変えることは、状態の寿命を変えることにもつながります。

## @Stateで状態を所有する

Viewは構造体で何度も生成されます。`@State` の値はViewの構造体そのものとは別にSwiftUIが管理し、同じIdentityのViewが存続する間保持します。

次の小さなViewを作り、ボタンでタイトルを変える演習をしてみましょう。

```swift
struct StateExercise: View {
    @State private var title = "レシピ一覧"

    var body: some View {
        Button(title) { title = "お気に入り" }
    }
}
```

完成版では `@State` にObservation対応のViewModelを保持します。詳しくは次章で扱います。

## 画面表示に結び付いた非同期処理

一秒待って状態を変える演習には、Viewに `.task` を付けます。

```swift
.task {
    do {
        try await Task.sleep(for: .seconds(1))
        try Task.checkCancellation()
        title = "読み込み完了"
    } catch is CancellationError {
        // このViewが不要になった場合は状態を変えない。
    } catch {
        title = "失敗しました"
    }
}
```

SwiftUIはViewが消えると、このタスクをキャンセルします。キャンセルは処理の強制停止ではなく、処理側が検知して協調的に終了します。`Task.sleep` はキャンセル時にthrowします。

`onAppear { Task.detached { ... } }` を画面の初期読み込みに使う必要はありません。`Task.detached` は呼び出し元のactor隔離などを引き継がず、Viewの寿命にも自動では結び付きません。

また、`.task` は「アプリで一回だけ実行する」仕組みではありません。再表示時の再読み込みや、必要に応じたキャッシュは別に設計します。検索語など入力が変わるたびに取得をやり直すなら `.task(id: query)` が使えます。

## 値に基づく画面遷移

アプリの入口は `NavigationStack` です。行は遷移先のViewを直接生成する代わりに、レシピIDを渡します。

```swift
.navigationDestination(for: Int64.self) { id in
    RecipeDetailView(recipeID: id, store: viewModel.store)
}
```

このModifierはListの行の中ではなく、Listの外側に置きます。遷移先を一か所で決められ、将来はpathを管理して特定のレシピIDを開く機能にも拡張できます。簡単な遷移では `NavigationLink { DetailView() }` も引き続き使えます。

## 演習

- 一覧の表示順を逆にし、IDがレシピと対応していることを確認する。
- 読み込み途中で画面を離れ、不要な結果が表示されないか確認する。
- 発展: `NavigationStack(path:)` にレシピIDの配列を渡し、ボタンで特定の詳細へ遷移する。

参考: [Understanding the navigation stack](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack)

[Chapter 4へ](chapter_04.md)
