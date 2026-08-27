import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dogapp/main.dart';
import 'package:dogapp/screens/home_screen.dart';

import 'fakes/fake_dogapp_api_client.dart';

/// デフォルトのテスト画面サイズ(800x600)は横長で、この電話向けUIには
/// 小さすぎる(ボトムナビの分だけ本文が画面外に出て、要素にタップが
/// 当たらなくなる)。実機に近いサイズに変更してから各テストを実行する。
Future<void> _pumpApp(
  WidgetTester tester, {
  Future<Uint8List?> Function(BuildContext context)? pickImage,
  Future<XFile?> Function(BuildContext context)? pickVideo,
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
  ));
  await tester.pump(); // loadDogs()の完了を待つ
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
    expect(find.text('混合ワクチン接種'), findsOneWidget);
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
  });

  testWidgets('記録タブで追加ボタンをタップするとモーダルが開き、2つのドロップダウンが表示される', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();

    expect(find.text('記録を追加'), findsOneWidget);

    await tester.tap(find.text('記録を追加'));
    await tester.pumpAndSettle();

    // find.byType(DropdownButtonFormField)はジェネリック型引数(<dynamic>)を
    // 厳密一致で比較するため<String>/<RecordType>のインスタンスを拾えない。
    // is判定を使うpredicateで型引数を問わずに数える。
    final anyDropdown =
        find.byWidgetPredicate((w) => w is DropdownButtonFormField);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(anyDropdown, findsNWidgets(2));

    // 閉じるボタンでモーダルが閉じることを確認
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(anyDropdown, findsNothing);
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
}
