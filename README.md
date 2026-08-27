# dogapp_flutter

犬の健康管理アプリのFlutter版。Web版プロトタイプ(`DogHealthApp.jsx`)と
同じ画面構成・データ・デザイントークンを、iOS/Android向けにDartへ移植したもの。

## 構成

```
lib/
  main.dart                アプリのエントリーポイント
  theme/app_theme.dart      デザイントークン(色・タイポグラフィ) - Web版と統一
  models/dog.dart           ドメインモデル(Dog, HealthRecord, WeightEntry, AICheckResult)
  data/mock_data.dart       モックデータ(レオ・ノア) - Web版と同じ内容
  widgets/dog_avatar.dart   犬アバター
  widgets/weight_chart.dart 体重推移チャート(CustomPainterによる自前実装)
  screens/
    main_shell.dart         ボトムタブナビゲーション
    home_screen.dart        ホーム画面
    dogs_screen.dart        犬一覧・プロフィール画面
    ai_check_screen.dart    健康チェック画面(AIチェックのモックフロー)
    records_screen.dart     記録画面(一覧・追加モーダル)
test/
  widget_test.dart          画面遷移・インタラクションのウィジェットテスト
scripts/
  check_dart_syntax.py      括弧・文字列リテラルの対応を検証する簡易構文チェッカー
```

## 依存パッケージについて

外部pubパッケージには依存していない(Flutter SDK標準機能のみ)。
Web版ではrechartsを使っていた体重推移グラフも、`CustomPainter`で自前実装している。
これは`apilab`のGraphQLエンジンを`reflect`だけで書いたのと同じ、
このポートフォリオ全体の"no deps"方針を踏襲したもの。

## 検証について(重要な注記)

**このコードは `flutter analyze` / `flutter test` を実際に実行して検証したものではない。**

理由は、このリポジトリを作成した開発環境にFlutter SDK/Dart SDKが
インストールされておらず、かつネットワークアクセスが特定ドメインに
制限されているため、SDKの配布元(`storage.googleapis.com`など)から
ダウンロードすることもできなかったため。

代わりに、以下の検証を行っている。

1. **手動コードレビュー**: 全ファイルを見直し、Dartの型システムに関する
   既知の落とし穴(`num`/`double`の暗黙変換がされない、`clamp()`が`num`を
   返すため`double`引数箇所で型エラーになる、など)を2箇所発見し修正した
   (`lib/widgets/weight_chart.dart`, `lib/screens/ai_check_screen.dart`)。
2. **`scripts/check_dart_syntax.py`**: 文字列リテラル・コメントを考慮しながら
   丸括弧・波括弧・角括弧の対応を検証する自作スクリプト。全12ファイルで
   問題なしを確認済み。

```bash
python3 scripts/check_dart_syntax.py
```

**このリポジトリを実際に使う場合、必ずローカルで以下を実行してほしい。**

```bash
flutter pub get
flutter analyze   # 型チェック・lintを含む本来の静的解析
flutter test      # test/widget_test.dart の実行
flutter run       # 実機/シミュレータでの動作確認
```

`check_dart_syntax.py`は`dart analyze`の代替にはならない
(型不整合、存在しないメンバー参照、未使用importなどは検出できない)。
できないことをできるように見せるより、どこまで検証していて、
どこから先はSDKのある環境が必要かを正直に書いておくことの方が
重要だと考えている(`zeroboard-infra`のterraform validateに関する
注記と同じ方針)。

## Web版との対応関係

| Web版(DogHealthApp.jsx) | Flutter版 |
|---|---|
| `useState`によるタブ切り替え | `MainShell`の`IndexedStack` |
| lucide-react アイコン | Material Icons(組み込み、依存追加不要) |
| recharts の`LineChart` | `WeightChart`(CustomPainterで自前実装) |
| `border-dashed` (Tailwind) | `DottedBorderBox`(CustomPainterで自前実装) |
| `setTimeout`によるAI解析のモック | `Future.delayed`によるモック |

## 今後の実装(バックエンド接続)

現在はモックデータ・モック応答で完結しているプロトタイプ。
`dogapp-api`(Go実装、Claude API連携済み)と接続する場合:

- `mock_data.dart`のデータ取得を、`dogapp-api`の`GET /owners/{ownerId}/dogs`
  等へのHTTP呼び出し(`http`パッケージなど)に置き換える
- `ai_check_screen.dart`の`_runCheck()`を、実際に撮影した画像をBase64化して
  `POST /dogs/{dogId}/ai-check`に送信する処理に置き換える
- `records_screen.dart`の保存処理を、`POST /dogs/{dogId}/records`への
  実際のリクエストに置き換える

これらは全て、モック関数の中身を差し替えるだけで済むよう、
画面側のロジックとデータ取得処理を分離した設計にしている。
