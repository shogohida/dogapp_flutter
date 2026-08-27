# dogapp_flutter

犬の健康管理アプリのFlutter版。Web版プロトタイプ(`DogHealthApp.jsx`)と
同じ画面構成・デザイントークンを踏襲しつつ、`dogapp-api`(Go実装、Claude API連携)
への実HTTP接続・日英ローカライズ・GPSによる散歩記録機能を備えたもの。

## 構成

```
lib/
  main.dart                  アプリのエントリーポイント(l10n/API/位置情報の依存性注入)
  config/api_config.dart     dogapp-apiのbaseUrl/ownerId(--dart-defineで上書き可)
  theme/app_theme.dart       デザイントークン(色・タイポグラフィ)
  l10n/                      日本語(ja)・英語(en)のARBファイルと生成コード
  models/
    dog.dart                 Dog, HealthRecord, WeightEntry, AICheckResult
    walk.dart                GeoPoint, WalkRoute, RecommendedCourse
  data/
    mock_data.dart           サンプルデータ(レオ・ノア) / フェイクテストの種データ
    dogs_repository.dart     犬一覧の読み込み・記録追加を管理するChangeNotifier
    walks_repository.dart    散歩記録のGPS計測・保存・おすすめコース集計
  services/
    dogapp_api_client.dart   dogapp-apiへのHTTPクライアント(タイムアウト付き)
    location_service.dart    geolocatorへの薄いラッパー
  utils/geo.dart             2点間距離(Haversine公式)
  widgets/dog_avatar.dart, weight_chart.dart
  screens/
    main_shell.dart          ボトムタブナビゲーション(ホーム/犬たち/健康チェック/記録/散歩)
    home_screen.dart, dogs_screen.dart, ai_check_screen.dart,
    records_screen.dart, walk_screen.dart
test/
  widget_test.dart           画面遷移・インタラクションのウィジェットテスト
  models/, services/, data/  JSON変換・APIクライアント・リポジトリのユニットテスト
  fakes/                     実ネットワーク/ネイティブプラグインに依存しないフェイク実装
tool/
  mock_server.dart           dogapp-apiの簡易モック(ローカル動作確認用、本物ではない)
scripts/
  check_dart_syntax.py       括弧・文字列リテラルの対応を検証する簡易構文チェッカー
```

## 実行方法

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome        # または実機/シミュレータ
```

`dogapp-api`がまだ無い場合は、同梱の簡易モックサーバーで動作確認できる。

```bash
dart run tool/mock_server.dart   # http://localhost:8080 で待ち受け
flutter run -d chrome            # デフォルトでlocalhost:8080に接続する
```

本番のdogapp-apiに繋ぐ場合はビルド時にURLを差し替える。

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

## dogapp-apiとの連携

`lib/services/dogapp_api_client.dart`が以下のエンドポイントを呼び出す。
フィールド名・enumの文字列表現は実際のdogapp-apiのJSONスキーマに合わせて
`lib/models/dog.dart` / `lib/models/walk.dart` の `fromJson`/`toJson` を
調整する想定(未接続の状態で作られた推測値)。

| メソッド | パス | 用途 |
|---|---|---|
| GET | `/owners/{ownerId}/dogs` | 犬一覧の取得 |
| POST | `/dogs/{dogId}/ai-check` | 写真(Base64)を送りAI健康チェック結果を取得 |
| POST | `/dogs/{dogId}/gait-check` | 短い動画(multipart/form-data)を送り歩行の異常を判定 |
| POST | `/dogs/{dogId}/records` | 通院・ワクチン等の記録を追加 |
| GET | `/dogs/{dogId}/walks` | 散歩記録の一覧取得 |
| POST | `/dogs/{dogId}/walks` | GPSで記録した散歩ルートの保存 |

## 散歩GPS記録・おすすめコース

「散歩」タブでは以下を行う。

- `geolocator`で位置情報をストリーム取得し、`flutter_map`(OpenStreetMapタイル、
  APIキー不要)でルートをリアルタイム描画
- 記録終了時に距離(Haversine公式で算出)・時間とともに`dogapp-api`へ保存
- 「おすすめ散歩コース」は外部の地図/検索APIを使わず、自分の過去の散歩履歴を
  開始地点の近さ(約100m四方)でグルーピングし、歩いた回数が多い順に提示する
  簡易ロジック(`WalksRepository.recommendedCourses()`)

Web版のブラウザで動かす場合、位置情報の利用にはブラウザ側の許可が必要。

## 動画による歩行チェック

「健康チェック」タブで写真/動画の2モードを切り替えられる。動画モードでは
足を引きずっていないかなど歩き方の異常を判定する。

- 動画は最大15秒(`ImagePicker.pickVideo(maxDuration: ...)`)に制限
- 写真(Base64+JSON)とは異なり、動画はサイズが大きくなりやすいため
  `http.MultipartRequest`で`multipart/form-data`アップロードする
- レスポンスの形は写真判定と同じ`AICheckResult`(level/title/detail)を再利用

## ローカライズ(日本語/英語)

Flutter標準の`flutter_localizations` + `intl`(ARBファイル)方式。
`lib/l10n/app_ja.arb`が原本、`app_en.arb`が英語訳。文言を追加・変更する場合は
両方のARBを編集してから以下で生成コードを更新する。

```bash
flutter gen-l10n
```

表示言語は端末のロケール設定に従う(`MaterialApp.supportedLocales`に`ja`/`en`を登録)。
犬の名前・品種・記録のラベルなど`dogapp-api`から取得するデータ自体は翻訳対象外
(ユーザーデータであり、アプリのUI文言ではないため)。

## テストについて

`flutter test`は実ネットワーク・実GPS・ネイティブプラグイン(image_picker/
geolocator)に依存せず、すべて`test/fakes/`のフェイク実装や
`http/testing.dart`の`MockClient`で完結する。ウィジェットテストは
既定のテスト画面サイズ(800x600、電話向けUIには小さすぎる)と英語ロケールの
まま失敗しがちなため、`test/widget_test.dart`のヘルパーでiPhoneサイズ・
日本語ロケールに固定している。

## Web版との対応関係

| Web版(DogHealthApp.jsx) | Flutter版 |
|---|---|
| `useState`によるタブ切り替え | `MainShell`の`IndexedStack` |
| lucide-react アイコン | Material Icons(組み込み) |
| recharts の`LineChart` | `WeightChart`(CustomPainterで自前実装) |
| `border-dashed` (Tailwind) | `DottedBorderBox`(CustomPainterで自前実装) |
