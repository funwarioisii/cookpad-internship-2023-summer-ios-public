# iOSアプリ開発をはじめよう

## 起動

1. このリポジトリの2026年版のコードを取得します。
2. `MiniCookpad.xcodeproj` をXcodeで開きます。
3. Schemeに `MiniCookpad`、実行先にiOSシミュレーターを選びます。
4. Run（⌘R）を実行します。レシピ一覧が表示されれば成功です。

完成コードを読む教材なので、まず全体の操作を試してから各章で実装を追います。新しくViewを作る際は、File → New → FileからSwiftファイルを作り、MiniCookpadターゲットへ追加してください。

## Xcodeで見る場所

- 左側のファイル一覧: View、Entity、Networkingなどの実装を開く。
- 中央のエディター: コードを編集する。
- Canvas: `#Preview` の表示を確認する。
- Debugエリア: コンソールとブレークポイントで状態を確認する。
- Testナビゲーター: Chapter 7のテストを実行する。

## サンプルAPIと実API

SchemeのRun → Arguments → Environment Variablesにある `USE_STUB_API_CLIENT` は、初期値が `1` です。`MiniCookpadApp` が `StubAPIClient` を作り、それを `RecipeStore` に渡します。

サンプルAPIは約300ms待って応答し、追加したタグをアプリ起動中だけ記憶します。レシピ本文は同梱JSONから読み、詳細のIDとタイトルは選択した一覧項目に合わせます。同梱JSONの画像にはダミーURLが含まれるため、画像は代替表示になります。実APIの外部画像は通信環境によって取得に失敗する場合があります。

`0` にすると `MiniCookpadAPIClient` を使います。レシピAPIは `https://localhost:3001`、タグAPIは `https://localhost:3002` が前提です。サーバー実装・起動手順・証明書の準備はこのiOS教材には含まれません。独自のバックエンドに接続する場合は `Networking/Request` 内のURLも合わせて変更してください。

## Previewをネットワークから独立させる

```swift
#Preview {
    NavigationStack {
        RecipeListView(store: RecipeStore(client: StubAPIClient()))
    }
}
```

プレビューは依存を明示して作ります。実行環境を調べてグローバル変数を差し替える仕組みは不要です。

[Chapter 2へ](chapter_02.md)
