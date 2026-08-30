import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dogapp/main.dart';
import 'package:dogapp/screens/home_screen.dart';

import 'fakes/fake_dogapp_api_client.dart';
import 'fakes/fake_token_storage.dart';

/// デフォルトのテスト画面サイズ(800x600)は横長で、この電話向けUIには
/// 小さすぎる(ボトムナビの分だけ本文が画面外に出て、要素にタップが
/// 当たらなくなる)。実機に近いサイズに変更してから各テストを実行する。
Future<void> _pumpApp(
  WidgetTester tester, {
  Future<Uint8List?> Function(BuildContext context)? pickImage,
  Future<XFile?> Function(BuildContext context)? pickVideo,
  Future<void> Function(Uint8List pngBytes, String dogName)? shareImage,
  // ログイン画面をスキップしてMainShellへ直接入るためのテスト専用オーバーライド。
  // ログイン/ログアウト自体を検証するテストではnullを渡す。
  String? initialToken = 'test-token',
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // テストの期待文言は日本語で書かれているため、ロケール(既定では英語のことが
  // 多いテスト環境の言語)を明示的に日本語に固定する。MaterialAppの既定の
  // ロケール解決は`.locale`ではなく`.locales`(優先順位リスト)を見るため、
  // 両方を設定する必要がある。
  const testLocale = Locale('ja', 'JP');
  tester.platformDispatcher.localeTestValue = testLocale;
  tester.platformDispatcher.localesTestValue = [testLocale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(DogHealthApp(
    apiClient: FakeDogappApiClient(),
    pickImage: pickImage,
    pickVideo: pickVideo,
    shareImage: shareImage,
    tokenStorage: FakeTokenStorage(),
    initialToken: initialToken,
  ));
  await tester.pump(); // loadDogs()/restoreSession()の完了を待つ
}

void main() {
  testWidgets('初期表示はホーム画面で、2匹の名前が表示される', (tester) async {
    await _pumpApp(tester);

    expect(find.text('おかえりなさい'), findsOneWidget);
    // 「レオ」「ノア」はホーム以外のタブ(犬たち一覧・健康チェックの犬選択)にも
    // IndexedStackの裏で同時に存在し、さらにホーム画面内でも今後の予定
    // タイムラインに同じ犬の予定が複数件あれば名前が繰り返し表示されるため、
    // ホーム画面内に「1件以上」表示されていることだけを確認する。
    final home = find.byType(HomeScreen);
    expect(find.descendant(of: home, matching: find.text('レオ')), findsWidgets);
    expect(find.descendant(of: home, matching: find.text('ノア')), findsWidgets);
  });

  testWidgets('「犬たち」タブに切り替えると一覧画面が表示される', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('犬たち').last);
    await tester.pumpAndSettle();

    expect(find.text('スタンダードプードル ・ アプリコット'), findsOneWidget);
  });

  testWidgets('犬一覧からレオをタップするとプロフィール画面(体重推移)に遷移する', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('犬たち').last);
    await tester.pumpAndSettle();

    // 犬一覧画面内の"レオ"カードをタップ(ボトムタブの"犬たち"ラベルと区別するため
    // より具体的な祖先を持つWidgetを探す)
    final leoCard = find.widgetWithText(InkWell, 'レオ');
    expect(leoCard, findsOneWidget);
    await tester.tap(leoCard);
    await tester.pumpAndSettle();

    expect(find.text('体重推移'), findsOneWidget);
    // シェアカードの分だけ縦に長くなり、記録一覧は初期ビューポート外にあるため
    // 見えるようにスクロールしてから確認する。
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('混合ワクチン接種'), findsOneWidget);
  });

  testWidgets('プロフィール画面でシェアボタンをタップするとカード画像がシェア処理に渡される', (tester) async {
    // ネイティブの共有シートはテスト環境で動かないため、フェイクに差し替えて
    // 「どんなバイト列(PNG)・どの犬の名前で呼ばれたか」だけを検証する。
    Uint8List? sharedBytes;
    String? sharedDogName;
    await _pumpApp(
      tester,
      shareImage: (bytes, dogName) async {
        sharedBytes = bytes;
        sharedDogName = dogName;
      },
    );

    await tester.tap(find.text('犬たち').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'レオ'));
    await tester.pumpAndSettle();

    // RenderRepaintBoundary.toImage()/toByteData()は実際のラスタライズ・PNG
    // エンコードを伴う非同期処理のため、フェイクのタイマーではなく実際の
    // 非同期ゲートで待つ必要がある(runAsync)。ただしpumpAndSettle()のように
    // pump()を連続で呼び続けると、そのラスタライズ処理自体が完了する隙が
    // なくなり(pumpAndSettleがタイムアウトするまで)完了しないため、
    // pump()は呼ばずに実時間でポーリングして完了を待つ。
    await tester.tap(find.byKey(const Key('shareProfileButton')));
    await tester.pump();
    await tester.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (sharedDogName == null && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();

    expect(sharedDogName, 'レオ');
    expect(sharedBytes, isNotNull);
    expect(sharedBytes!.isNotEmpty, isTrue);
  });

  testWidgets('プロフィール画面で編集ボタンから名前を変更すると一覧・プロフィールに反映される',
      (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('犬たち').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'レオ'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editProfileButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('editDogNameField')), 'レオ2');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('レオ2'), findsWidgets);
    expect(find.text('レオ'), findsNothing);
  });

  testWidgets('ホーム画面のレオカードをタップすると犬たちタブのプロフィールに直接遷移する', (tester) async {
    await _pumpApp(tester);

    // ホーム画面上のレオカード(DogAvatarを含むInkWell)をタップ
    final leoHomeCard = find.ancestor(
      of: find.descendant(
          of: find.byType(HomeScreen), matching: find.text('レオ')),
      matching: find.byType(InkWell),
    );
    await tester.tap(leoHomeCard.first);
    await tester.pumpAndSettle();

    expect(find.text('体重推移'), findsOneWidget);
  });

  testWidgets('健康チェックタブで写真ボタンをタップすると解析中→結果の順に遷移する', (tester) async {
    // ネイティブの画像ピッカーはテスト環境で動かないため、ダミーの画像バイト列を返す
    await _pumpApp(tester,
        pickImage: (context) async => Uint8List.fromList([0]));

    await tester.tap(find.text('健康チェック').last);
    await tester.pumpAndSettle();

    expect(find.text('写真を撮る・選ぶ'), findsOneWidget);

    await tester.tap(find.text('写真を撮る・選ぶ'));
    await tester.pump(); // pickImage()の完了とanalyzing状態への遷移

    expect(find.text('解析しています…'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('もう一度チェックする'), findsOneWidget);

    // 判定結果は犬の記録としても自動保存される。
    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();
    expect(find.text('健康チェック: 特に気になる所見はありません'), findsOneWidget);
  });

  testWidgets('健康チェックタブで動画モードに切り替えて撮影すると解析中→結果の順に遷移する', (tester) async {
    // ネイティブの動画ピッカーはテスト環境で動かないため、ダミーの動画XFileを返す
    await _pumpApp(
      tester,
      pickVideo: (context) async => XFile.fromData(
        Uint8List.fromList([0]),
        name: 'walk.mp4',
        mimeType: 'video/mp4',
      ),
    );

    await tester.tap(find.text('健康チェック').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('動画(歩行)'));
    await tester.pumpAndSettle();

    expect(find.text('動画を撮る・選ぶ'), findsOneWidget);

    await tester.tap(find.text('動画を撮る・選ぶ'));
    await tester.pump(); // pickVideo()の完了とanalyzing状態への遷移

    expect(find.text('解析しています…'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('もう一度チェックする'), findsOneWidget);

    // 歩行チェックの結果も、写真判定と見分けられるラベルで記録に保存される。
    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();
    expect(find.text('歩行チェック: 特に気になる所見はありません'), findsOneWidget);
  });

  testWidgets('記録タブで追加ボタンをタップするとモーダルが開き、犬選択と種別入力が表示される', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();

    expect(find.text('記録を追加'), findsOneWidget);

    await tester.tap(find.text('記録を追加'));
    await tester.pumpAndSettle();

    // 犬選択のドロップダウンと、種別の自由入力フィールドが表示される。
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byKey(const Key('recordTypeField')), findsOneWidget);

    // 閉じるボタンでモーダルが閉じることを確認
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('記録追加時に費用を入力すると一覧・合計に反映される', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('記録を追加'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('recordTypeField')), '通院');
    await tester.enterText(find.byKey(const Key('recordCostField')), '2500');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('¥2,500'), findsOneWidget);
    // 既存の記録(合計29,500円)+今回の2,500円。
    expect(find.text('費用の合計: ¥32,000'), findsOneWidget);
  });

  testWidgets('記録一覧は日付の新しい順に並んでいる', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();

    // レオの「定期健診」(2026-08-15)が「混合ワクチン接種」(2026-07-12)より先に来るはず
    final vetFinder = find.text('定期健診');
    final vaccineFinder = find.text('混合ワクチン接種');
    expect(vetFinder, findsOneWidget);
    expect(vaccineFinder, findsOneWidget);

    final vetPos = tester.getTopLeft(vetFinder).dy;
    final vaccinePos = tester.getTopLeft(vaccineFinder).dy;
    expect(vetPos, lessThan(vaccinePos));
  });

  testWidgets('未ログイン時はログイン画面が表示される', (tester) async {
    await _pumpApp(tester, initialToken: null);
    await tester.pumpAndSettle();

    expect(find.text('ログイン'), findsWidgets);
    expect(find.text('おかえりなさい'), findsNothing);
  });

  testWidgets('ログインに成功するとホーム画面が表示される', (tester) async {
    await _pumpApp(tester, initialToken: null);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('emailField')), 'user@example.com');
    await tester.enterText(
        find.byKey(const Key('passwordField')), 'correct-password');
    await tester.tap(find.text('ログイン').last);
    await tester.pumpAndSettle();

    expect(find.text('おかえりなさい'), findsOneWidget);
  });

  testWidgets('アカウント作成に切り替えて成功するとホーム画面が表示される', (tester) async {
    await _pumpApp(tester, initialToken: null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('アカウントをお持ちでない方はこちら'));
    await tester.pumpAndSettle();
    expect(find.text('アカウント作成'), findsWidgets);

    await tester.enterText(
        find.byKey(const Key('emailField')), 'new@example.com');
    await tester.enterText(
        find.byKey(const Key('passwordField')), 'correct-password');
    await tester.tap(find.text('アカウントを作成'));
    await tester.pumpAndSettle();

    expect(find.text('おかえりなさい'), findsOneWidget);
  });

  testWidgets('ログアウトするとログイン画面に戻る', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();

    expect(find.text('ログイン'), findsWidgets);
    expect(find.text('おかえりなさい'), findsNothing);
  });

  testWidgets('犬たちタブで犬を追加すると一覧に反映される', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('犬たち').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addDogButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('newDogNameField')), 'ココ');
    await tester.enterText(
        find.byKey(const Key('newDogBreedField')), 'トイプードル');
    await tester.enterText(find.byKey(const Key('newDogColorField')), 'ホワイト');
    await tester.enterText(
        find.byKey(const Key('newDogBirthYearField')), '2023');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('ココ'), findsWidgets);
  });

  testWidgets('プロフィール画面で体重を記録するとグラフに反映される', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('犬たち').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'レオ'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addWeightButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('weightKgField')), '25.6');
    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    // 保存に成功するとモーダルが閉じる(失敗時はエラー文言とともに開いたまま)。
    expect(find.byKey(const Key('weightKgField')), findsNothing);
    expect(find.text('体重推移'), findsOneWidget);
  });
}
