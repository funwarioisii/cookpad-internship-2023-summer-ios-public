# レシピ一覧の行を作ろう

対応ファイル: [RecipeListRow.swift](../MiniCookpad/View/RecipeList/RecipeListRow.swift)、[RecipeImage.swift](../MiniCookpad/View/RecipeImage.swift)

## Viewは状態から見た目を記述する

`RecipeListRow` は `RecipeListItem` を受け取り、画像・タイトル・作者・材料・タグを並べます。行自身はAPIを呼ばず、入力を表示する役割にします。

```swift
struct RecipeListRow: View {
    let item: RecipeListItem

    var body: some View {
        HStack(alignment: .top) {
            RecipeImage(url: URL(string: item.recipe.imageUrl ?? ""))
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            VStack(alignment: .leading, spacing: 6) {
                Text(item.recipe.title).font(.headline)
                Text("by \(item.recipe.user.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

`HStack` は横、`VStack` は縦に並べます。`alignment` は配置の基準、`spacing` は間隔です。ModifierはViewから新しいViewを作り、適用順が見た目に影響します。

## 画像の成功・待機・失敗

`RecipeImage` の中では `AsyncImage` のphaseを分岐します。

- URLなし: 写真の代替アイコン。
- 取得待ち: `ProgressView`。
- 成功: `resizable` と `scaledToFill` で領域を埋め、はみ出しをclip。
- 失敗: 失敗を表す写真アイコン。

画像の大きさは呼び出すViewが指定します。画像を取得するたびに行の高さが変わらないよう、領域を先に確保します。`RecipeImage` は周囲のタイトルと重複する装飾画像としてVoiceOverから隠しています。画像自体の内容が重要な機能に流用するなら、アクセシビリティ説明も設計してください。

この検証環境の `AsyncImage` では独自URLSessionの注入は行っていません。画像キャッシュを明示的に制御する発展課題は [2026年版の設計](modernization_2026.md) を参照してください。

## サイズと色の意味を指定する

本文は `.primary`、補助情報は `.secondary` を使います。固定の黒文字・白背景より、ダークモードにも適応しやすくなります。文字には `.headline` や `.caption` などのテキストスタイルを使い、Dynamic Typeへ追従させます。

固定画像サイズは使っても、文章全体の高さは固定しません。省略を許す材料などには `lineLimit` を付け、詳細画面では全文を読めるようにします。

## 演習

1. 行のPreviewでタイトル・材料・タグを長くして、レイアウトを確認する。
2. 明るい外観と暗い外観で文字が読めるか確認する。
3. 文字サイズをアクセシビリティサイズまで上げ、タイトルが画像と重ならないか確認する。
4. 無効な画像URLを渡して、待機中と失敗後を区別できるか確認する。

[Chapter 3へ](chapter_03.md)
