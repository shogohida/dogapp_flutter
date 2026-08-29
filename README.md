# dogapp_flutter

犬の健康管理アプリのFlutter版。Web版プロトタイプ(`DogHealthApp.jsx`)と
同じ画面構成・デザイントークンを踏襲しつつ、`dogapp-api`(Go実装、Claude API連携)
への実HTTP接続・日英ローカライズ・GPSによる散歩記録機能を備えたもの。

## 構成

```
lib/
  main.dart                  アプリのエントリーポイント。ログイン状態(_AppRoot)に応じて
                              LoginScreen⇄MainShellを切り替え、APIクライアント等を組み立てる
  config/api_config.dart     dogapp-apiのbaseUrl(--dart-defineで上書き可)
  theme/app_theme.dart       デザイントークン(色・タイポグラフィ)
  l10n/                      日本語(ja)・英語(en)のARBファイルと生成コード
  models/
    dog.dart                 Dog, HealthRecord, WeightEntry, AICheckResult, UpcomingItem
    user.dart                AppUser, AuthResult(signup/loginのレスポンス)
    walk.dart                GeoPoint, WalkRoute, RecommendedCourse
  data/
    mock_data.dart           サンプルデータ(レオ・ノア) / フェイクテストの種データ
    auth_repository.dart     signup/login/ログアウトとセッション復元(SharedPreferences)
    dogs_repository.dart     犬一覧の読み込み・追加・記録追加を管理するChangeNotifier
    walks_repository.dart    散歩記録のGPS計測・保存・おすすめコース集計
  services/
    dogapp_api_client.dart   dogapp-apiへのHTTPクライアント(タイムアウト付き)
    auth_token_store.dart    ログイン中のJWTを保持する薄い箱(APIクライアントが購読)
    location_service.dart    geolocatorへの薄いラッパー
  utils/geo.dart             2点間距離(Haversine公式)
  widgets/dog_avatar.dart, weight_chart.dart
  screens/
    login_screen.dart        ログイン/アカウント作成画面
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

`dogapp-api`は別リポジトリ(`../dogapp-api`、Go実装)にある実際のバックエンド。
セットアップ済みなら以下で起動してから`flutter run`すればそのまま繋がる
(デフォルトのbaseUrlが`http://localhost:8080`のため)。

```bash
cd ../dogapp-api && go run .
```

まだセットアップしていない/手早く動作確認したいだけの場合は、同梱の
簡易モックサーバーでも代用できる(dogapp-apiと同じポートで同じJSON形状を返す)。

```bash
dart run tool/mock_server.dart   # http://localhost:8080 で待ち受け
flutter run -d chrome            # デフォルトでlocalhost:8080に接続する
```

本番のdogapp-apiに繋ぐ場合はビルド時にURLを差し替える。

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

## ログイン

自前実装(外部の認証サービスは使わない)。起動時、`AuthRepository`が
`SharedPreferences`に保存済みのトークンを復元し、あればそのままホーム画面へ、
無ければ`LoginScreen`(ログイン⇄アカウント作成を切り替え可能)を表示する。
ログイン後はトークンを`AuthTokenStore`(`ChangeNotifier`)に保持し、
`HttpDogappApiClient`がリクエストの度にそこから読んで`Authorization: Bearer`
ヘッダーを付与する(コンストラクタに渡す`getToken`コールバック経由なので、
ログイン/ログアウトのたびにAPIクライアントを作り直す必要はない)。
ホーム画面右上のアイコンからログアウトできる。

サインアップ直後は犬が1匹も登録されていないため、「犬たち」タブの
「+」ボタン(または犬0匹時の案内)から`POST /dogs`で自分の犬を追加する。

## dogapp-apiとの連携

`lib/services/dogapp_api_client.dart`が以下のエンドポイントを呼び出す。
フィールド名・enumの文字列表現は実際の`dogapp-api`(`../dogapp-api`)の
JSONスキーマと完全に一致させてある。`/auth/*`以外は`Authorization: Bearer`
ヘッダーが必須で、`/dogs/{dogId}/...`系はトークンの持ち主が所有する犬しか
操作できない。

| メソッド | パス | 用途 |
|---|---|---|
| POST | `/auth/signup` | アカウント作成、トークンを取得 |
| POST | `/auth/login` | ログイン、トークンを取得 |
| GET | `/dogs` | 自分の犬一覧の取得 |
| POST | `/dogs` | 犬を追加(呼び出し元が所有者になる) |
| PATCH | `/dogs/{dogId}` | 犬のプロフィール(名前・犬種・毛色・生まれた年)を更新 |
| POST | `/dogs/{dogId}/weight` | 体重記録を追加 |
| POST | `/dogs/{dogId}/ai-check` | 写真(Base64)を送りAI健康チェック結果を取得 |
| POST | `/dogs/{dogId}/gait-check` | 短い動画(multipart/form-data)を送り歩行の異常を判定 |
| POST | `/dogs/{dogId}/records` | 通院・ワクチン等の記録を追加(種別は自由入力) |
| GET | `/dogs/{dogId}/walks` | 散歩記録の一覧取得 |
| POST | `/dogs/{dogId}/walks` | GPSで記録した散歩ルートの保存 |
| GET | `/upcoming` | 今後の予定一覧の取得 |
| POST | `/dogs/{dogId}/upcoming` | 今後の予定の追加 |

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
日本語ロケールに固定している。ログイン画面をスキップしたいテストは
`DogHealthApp(initialToken: "...")`でログイン済み状態を再現できる
(ログイン/ログアウト自体を検証するテストだけ`initialToken: null`を渡す)。

## Web版との対応関係

| Web版(DogHealthApp.jsx) | Flutter版 |
|---|---|
| `useState`によるタブ切り替え | `MainShell`の`IndexedStack` |
| lucide-react アイコン | Material Icons(組み込み) |
| recharts の`LineChart` | `WeightChart`(CustomPainterで自前実装) |
| `border-dashed` (Tailwind) | `DottedBorderBox`(CustomPainterで自前実装) |
