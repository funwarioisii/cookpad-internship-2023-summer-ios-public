# 画像の読み込みと画面遷移を見直す

Chapter 2・3・5で学ぶList、State、NavigationStackの基礎は、2026年版でも使います。このページでは、完成サンプルで変えた部分と、その理由を説明します。

## 画像を取得できない場合も表示を用意する

Chapter 2のレシピ画像は、[RecipeImage](../../MiniCookpad/View/RecipeImage.swift) にまとめています。画像のURLがない場合、読み込み中、成功、失敗を区別して表示します。画像を表示できない場合にも、空白のままにせず、状況に応じた代わりの表示を用意します。

取得した画像は `scaledToFill` で表示領域を埋め、はみ出した部分を切り取ります。表示領域の大きさは、一覧の行や詳細画面など、使う側で指定します。

このサンプルでは画像を装飾として扱い、VoiceOverの読み上げ対象から外しています。写真の内容自体を利用者に伝えたい場合は、画像の説明も用意してください。

文字の色には、本文を表す `primary`、補助的な情報を表す `secondary` などを使います。文字を黒、背景を白と固定するよりも、ライトモードとダークモードの両方に対応しやすくなります。

## 画面に必要な読み込みを `.task` で始める

Chapter 3には、1秒待ってからサンプルデータを表示する演習があります。元の `onAppear { Task.detached { @MainActor in ... } }` を、次のように書き換えて試してみましょう。

```swift
.task {
    do {
        try await Task.sleep(for: .seconds(1))
        try Task.checkCancellation()
        items = RecipeListSampleDataProvider.makeRecipeListSampleData()
    } catch is CancellationError {
        // 画面が不要になった場合は、データを変更せずに終了する。
    } catch {
        print(error)
    }
}
```

`.task` を使うと、SwiftUIが画面の表示に合わせて非同期処理を始め、画面が消えるとキャンセルします。処理側も、キャンセルを受け取ったら終了するように書きます。この例では、待ち時間中のキャンセルを `catch` で受け取り、待ち終わった直後にも確認しています。

`.task` は、アプリ全体で一度だけ実行する仕組みではありません。同じ画面を開き直すと、再び実行される場合があります。また、検索条件などの変更に合わせて読み込み直したい場合は、`.task(id:)` を使う方法もあります。

完成サンプルでは、一覧と詳細の通信を `.task` から呼び出しています。通信に失敗した場合は、コンソールに出すだけでなく、画面に説明と再試行ボタンを表示します。

## レシピIDを渡して詳細へ進む

一覧では `NavigationLink(value: item.id)` でレシピIDを渡します。移動先の画面は、Listの外側に付けた `navigationDestination(for: Int64.self)` で指定します。

これにより、一覧の行では「どのレシピを開くか」を指定し、遷移先の定義では「そのIDからどの画面を作るか」を記述できます。Chapter 3の、NavigationLinkに遷移先のViewを直接書く方法も引き続き利用できます。値を渡す方法は、後から遷移履歴を管理する課題につなげるために採用しています。

## 詳細画面でモデルを保持する

詳細画面はレシピIDと共有のStoreを受け取り、その画面用のViewModelを `@State` で保持します。通信は初期化時ではなく、`.task` から始めます。

このサンプルでは、一つの詳細画面が表示されている間、レシピIDは変わりません。同じ画面を使ったまま別のレシピに切り替える場合は、ViewModelが持つデータや実行中の取得処理も切り替える必要があります。

材料と手順を並べるときは、それぞれの要素が持つIDを使います。手順の表示番号をそのままIDにすると、並べ替えたときに別の手順と区別できなくなるためです。

また、長い本文やタグを途中で省略せず、スクロールして最後まで読めるようにします。端末の文字サイズを大きくした場合にも、必要な情報やボタンが隠れないか確認してみましょう。

対応コード: [RecipeListView](../../MiniCookpad/View/RecipeList/RecipeListView.swift)、[RecipeDetailView](../../MiniCookpad/View/RecipeDetail/RecipeDetailView.swift)

## 新しいSDKで試す発展課題

完成サンプルの検証にはXcode 26.3を使っています。WWDC26で紹介されたStateのマクロ化による遅延初期化や、AsyncImageのHTTPキャッシュ、URLRequest、カスタムURLSessionへの対応は、このサンプルには取り入れていません。対応するSDKで学ぶ場合は、[WWDC26の解説](https://developer.apple.com/videos/play/wwdc2026/269/) を参考に試してみてください。

Liquid Glassについては、まず標準のナビゲーション、ツールバー、Form、Buttonがどのように表示されるかを確認しましょう。独自の装飾を加える前に、本文の読みやすさや操作のしやすさを確かめます。参考: [新しいデザインの導入](https://developer.apple.com/videos/play/wwdc2025/323/)
