# 詳細画面と状態の寿命

対応ファイル: [RecipeDetailView.swift](../MiniCookpad/View/RecipeDetail/RecipeDetailView.swift)、[RecipeDetailViewModel.swift](../MiniCookpad/View/RecipeDetail/RecipeDetailViewModel.swift)

## 詳細のモデルをどこで保持するか

一覧は選んだレシピIDと共有Storeを渡します。詳細画面は自分の読み込み状態を管理するViewModelを `@State` で所有します。

```swift
@State private var viewModel: RecipeDetailViewModel

init(recipeID: Int64, store: RecipeStore) {
    _viewModel = State(initialValue: RecipeDetailViewModel(recipeID: recipeID, store: store))
}
```

Viewが再評価されるたびに、保持するモデルを作り直す意図ではありません。Stateの寿命はViewのIdentityに対応します。この画面のrecipeIDは一つのナビゲーション先の間は固定です。同じIdentityで別IDを表示する画面へ拡張するなら、ID変更時のモデルとタスクの扱いも設計してください。

このXcode 26.3向けの書き方では、Viewの初期化式は再実行され得るため、ViewModelのinitで通信を始めません。読み込みは `.task` に置きます。新しいStateマクロの遅延初期化については [補足](modernization_2026.md) を参照してください。

## レシピ本体と共有タグ

ViewModelはレシピ本体を保持し、表示する `RecipeDetailItem` を計算するときにStoreのタグを参照します。

```swift
var recipeDetailItem: RecipeDetailItem? {
    recipe.map {
        .init(recipe: $0, hashtags: store.hashtagsByRecipeID[recipeID, default: []])
    }
}
```

これにより、タグ追加時に詳細のレシピ本体を再取得する必要がありません。通信状態を共有Storeに全部集めると、一画面の読み込みが他画面の読み込み表示を変えてしまいます。この教材では画面固有のisLoadingとerrorMessageをViewModel側に残しています。

## 表示の構成

`ScrollView` の中に、レシピ画像・タイトル・作者・タグ・説明・材料・手順を並べます。

- レシピ未取得かつ読み込み中: `ProgressView`。
- 失敗: メッセージと再試行ボタン。取得済みの内容は残す。
- 取得済み: レシピ本文。本文の高さは文字サイズと内容に応じて変わる。

材料の `ForEach` には材料ID、手順には手順IDを使います。手順番号は `enumerated()` のoffsetから表示しますが、番号をIdentityには使いません。

画像はChapter 2の `RecipeImage` を再利用します。材料・手順・タグは全文を読めるようにし、本文の黒色固定や画面全体の固定高さを避けます。

## 演習

1. 長いレシピ名・説明・材料を表示して確認する。
2. Dynamic Typeを最大にして、最後の手順までスクロールできることを確認する。
3. 通信待ち中に一覧へ戻り、キャンセルが失敗扱いにならないことを確かめる。
4. 発展: iPadでは `NavigationSplitView` を使い、一覧と詳細を同時に表示する。同じStoreを渡す設計がそのまま使えるか考える。

[Chapter 6へ](chapter_06.md)
