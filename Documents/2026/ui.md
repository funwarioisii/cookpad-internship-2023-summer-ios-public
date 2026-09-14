# [Chapter 2・3・5 補足] 画像の表示と画面遷移

Chapter 2・3・5 で作成した画面について、2026 年版の完成サンプルで変更した部分を説明します。
List、State、NavigationStack の基本的な使い方は同じなので、各章で作ったコードと比べながら見ていきましょう。

## 画像の表示（Chapter 2）

### AsyncImage の読み込み中・失敗時の表示

レシピの画像を表示するには、URL から画像を取得する必要があります。取得に時間がかかる場合や、取得に失敗した場合は、どのような表示にすればよいでしょうか。

完成サンプルでは、画像を表示する部分を`RecipeImage`という View にまとめています。[RecipeImage.swift](../../MiniCookpad/View/RecipeImage.swift) を開いてみましょう。

`AsyncImage`に渡すクロージャで、画像の取得状態を表す`phase`を受け取り、`switch`で表示を切り替えています。

- `.success`の場合は、取得した画像を表示する
- `.failure`の場合は、取得できなかったことを表すアイコンを表示する
- `.empty`の場合は、URL があれば読み込み中の表示、URL がなければ画像がないことを表すアイコンを表示する

これにより、読み込みを待っているのか、画像を取得できなかったのかを、表示から区別できるようになります。

### 画像の大きさ

一覧と詳細では画像を表示する大きさが異なるため、`RecipeImage`を使う側で大きさを指定します。以下は、ハッシュタグ追加画面で使っている例です。

```swift
RecipeImage(url: URL(string: item.recipe.imageUrl ?? ""))
    .frame(width: 64, height: 64)
    .clipShape(Circle())
```

`RecipeImage`の内部では`scaledToFill`で表示領域を埋め、はみ出した部分を`clipped()`で切り取っています。画像の縦横比を崩さずに、指定した大きさで表示するためです。

今回は画像を装飾として扱い、VoiceOver の読み上げ対象から外しています。写真の内容自体を伝える機能を作る場合は、画像の説明も用意するようにしましょう。

### ダークモードでの表示

本文の色には`primary`、補助的な情報には`secondary`を使います。文字を黒、背景を白に固定する代わりに、役割に応じた色を指定することで、ダークモードにも対応できます。

シミュレータの表示をダークモードに切り替え、レシピ名や材料が読めることを確認してみてください。

## 非同期処理と画面遷移（Chapter 3）

### task

Chapter 3 では、`onAppear`の中で`Task.detached`を使い、1 秒待ってからサンプルデータを表示しました。
この部分を、Chapter 4 でも紹介した`task` Modifier を使って書いてみましょう。

```swift
.task {
    do {
        try await Task.sleep(for: .seconds(1))
        try Task.checkCancellation()
        items = RecipeListSampleDataProvider.makeRecipeListSampleData()
    } catch is CancellationError {
        // キャンセルされた場合は、データを変更せずに終了する
    } catch {
        print(error)
    }
}
```

`task` Modifier を使うと、View の表示に合わせて非同期処理を開始できます。また、処理が完了する前に View が消えると、SwiftUI がタスクをキャンセルします。

ただし、キャンセルされたらその場で全てのコードが止まる、というわけではありません。処理側もキャンセルを受け取って終了する必要があります。この例では、待っている間のキャンセルを`catch`で受け取り、待ち終わった直後にも`Task.checkCancellation()`で確認しています。

元の演習の`onAppear`を置き換えて、シミュレータで実行してみましょう。1 秒ほど待った後に、これまでと同じサンプルデータが表示されれば OK です。

なお、`.task`はアプリ全体で一度だけ実行されるものではありません。画面を開き直すと再び実行される場合があります。検索条件などの値が変わるたびに処理をやり直したい場合は、`.task(id:)`を使う方法もあります。

### レシピ ID を渡して画面遷移する

Chapter 3 では、NavigationLink に遷移先の View を直接記述しました。この書き方も引き続き利用できますが、完成サンプルではレシピ ID を渡す方法を使っています。

[RecipeListView.swift](../../MiniCookpad/View/RecipeList/RecipeListView.swift) を開き、NavigationLink の部分を見てみましょう。

```swift
NavigationLink(value: item.id) {
    RecipeListRow(item: item)
}
```

ここでは、遷移先の View ではなく、表示したいレシピの ID を渡しています。では、どの View に遷移するかはどこで決めるのでしょうか。

List の外側に付けた`navigationDestination` Modifier で、以下のように指定しています。

```swift
.navigationDestination(for: Int64.self) { id in
    RecipeDetailView(recipeID: id, store: viewModel.store)
}
```

`Int64`型の値が渡された時に、その値をレシピ ID として RecipeDetailView を作成します。行の部分では「どのレシピを開くか」を指定し、遷移先の定義を別の場所にまとめることができました。

今回は、後から遷移履歴を管理する課題につなげられるように、この書き方を使っています。単純に詳細画面を開くために、必ず変更しなければならないというわけではありません。

## 詳細画面の表示（Chapter 5）

### ViewModel と読み込み処理

詳細画面でも、一覧と同じように ViewModel を使います。[RecipeDetailView.swift](../../MiniCookpad/View/RecipeDetail/RecipeDetailView.swift) では、受け取ったレシピ ID と Store を使って ViewModel を作成し、`@State`で保持しています。

API リクエストは初期化時ではなく、`task` Modifier の中から送ります。読み込み中の表示に加えて、失敗した場合にはメッセージと再試行ボタンを表示してみましょう。ViewModel の値を View に反映する仕組みは、[Observation の補足](state.md) を参照してください。

このサンプルでは、一つの詳細画面が表示されている間、レシピ ID は変わりません。同じ画面のまま別のレシピに切り替える場合は、ViewModel のデータや実行中の取得処理も切り替える必要があります。

### 材料と手順の ID

材料と手順を並べる際は、それぞれのデータが持っている ID を使います。手順の表示番号を ID にすると、並べ替えた場合に同じ手順を識別できなくなるためです。Chapter 3 の Identity の説明も思い出してみてください。

### 長い本文の表示

本文やハッシュタグが長い場合にも、最後まで読めるようにしてみましょう。途中で省略せずに表示し、画面に収まらない部分はスクロールできるようにします。

実装できたら、文字サイズを大きくした場合も確認してみてください。必要な情報が隠れていないか、最後の手順までスクロールできるかを見てみましょう。

## [補足] 新しい SDK で試してみる

完成サンプルは Xcode 26.3 で動作を確認しています。WWDC26 で紹介された State のマクロ化による遅延初期化や、AsyncImage の HTTP キャッシュ、URLRequest、カスタム URLSession への対応は、このサンプルには取り入れていません。対応する SDK で試したい方は、[WWDC26 の解説](https://developer.apple.com/videos/play/wwdc2026/269/) を見てみてください。

Liquid Glass については、まず標準のナビゲーションやツールバー、Form、Button がどのように表示されるかを確認してみましょう。詳しくは [新しいデザインの導入](https://developer.apple.com/videos/play/wwdc2025/323/) を参照してください。
