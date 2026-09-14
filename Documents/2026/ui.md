# 画面表示とタスクの変更点

Chapter 2・3・5のList、Identity、State、NavigationStackの基礎は引き続き使います。元の説明や画像は残し、差分をここにまとめます。

## 画像の状態と色（Chapter 2）

[RecipeImage](../../MiniCookpad/View/RecipeImage.swift) に画像の表示を共通化します。URLなし、取得待ち、成功、失敗を区別し、成功時は領域をscaledToFillで埋めてclipします。画像領域のサイズは呼び出し側が指定します。レシピ名と重複する装飾画像としてVoiceOverから隠しているため、写真の内容を伝える機能に流用する際は説明も設計します。

本文はprimary、補助情報はsecondaryなどの意味に応じた色を使います。画面全体を固定の黒文字と白背景にしないことで、ダークモードへ適応できます。

## タスクと値に基づく遷移（Chapter 3）

画面の初期読み込みは `.task` に置きます。元の一秒待つ演習の `onAppear { Task.detached { @MainActor in ... } }` も、次の形で試してください。

```swift
.task {
    do {
        try await Task.sleep(for: .seconds(1))
        try Task.checkCancellation()
        items = RecipeListSampleDataProvider.makeRecipeListSampleData()
    } catch is CancellationError {
        // 画面が不要になったため、状態を変えない。
    } catch {
        // 演習ではコンソールで確認。通信失敗の表示はChapter 4の補足で扱う。
        print(error)
    }
}
```

SwiftUIはViewが消えるとtaskをキャンセルしますが、処理側が協調して終了する必要があります。`.task` は「アプリ全体で一回だけ」実行する仕組みではありません。入力に応じて読み直すなら `.task(id:)` を検討します。

完成版の一覧は `NavigationLink(value: item.id)` でレシピIDを渡し、Listの外側の `navigationDestination(for: Int64.self)` で詳細画面を作ります。将来pathを使って特定のレシピへ遷移する課題にも拡張できます。単純な遷移に元のNavigationLinkの書き方を使うことも可能です。

## 詳細の表示と寿命（Chapter 5）

詳細はrecipeIDと共有Storeを受け取り、画面固有のViewModelをStateで所有します。initで通信を始めず、taskから読み込みます。recipeIDは一つの遷移先の間は固定です。同じIdentityでIDを変える画面へ拡張する場合は、モデルと取得タスクの切り替えも設計します。

材料と手順には各要素のIDを使い、手順番号に使うoffsetをIdentityにしません。詳細は読み込み中と失敗・再試行を表示し、長い本文やタグを全文読めるようにします。文字サイズを大きくして、最後までスクロールできることを確認してください。

対応コード: [一覧](../../MiniCookpad/View/RecipeList/RecipeListView.swift)、[詳細](../../MiniCookpad/View/RecipeDetail/RecipeDetailView.swift)

## 新SDKでの発展事項

本編はXcode 26.3で検証します。WWDC26で紹介されたStateのマクロ化による遅延初期化、AsyncImageのHTTPキャッシュ改善・URLRequest・カスタムURLSessionのAPIは、本編には未採用・未検証です。対応SDKで進める際は [WWDC26の解説](https://developer.apple.com/videos/play/wwdc2026/269/) を参照してください。

Liquid Glassはまず標準のナビゲーション、ツールバー、Form、Buttonで外観を確認します。レシピ本文全体をガラス素材にすることを目標にはしません。[新デザインの導入](https://developer.apple.com/videos/play/wwdc2025/323/)
