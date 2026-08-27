import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogapp/main.dart';

import 'fakes/fake_dogapp_api_client.dart';

void main() {
  testWidgets('初期表示はホーム画面で、2匹の名前が表示される', (tester) async {
    await tester.pumpWidget(DogHealthApp(apiClient: FakeDogappApiClient()));
    await tester.pump(); // loadDogs()の完了を待つ

    expect(find.text('おかえりなさい'), findsOneWidget);
    expect(find.text('レオ'), findsOneWidget);
    expect(find.text('ノア'), findsOneWidget);
  });

  testWidgets('「犬たち」タブに切り替えると一覧画面が表示される', (tester) async {
    await tester.pumpWidget(DogHealthApp(apiClient: FakeDogappApiClient()));
    await tester.pump(); // loadDogs()の完了を待つ

    await tester.tap(find.text('犬たち').last);
    await tester.pumpAndSettle();

    expect(find.text('スタンダードプードル ・ アプリコット'), findsOneWidget);
  });

  testWidgets('犬一覧からレオをタップするとプロフィール画面(体重推移)に遷移する', (tester) async {
    await tester.pumpWidget(DogHealthApp(apiClient: FakeDogappApiClient()));
    await tester.pump(); // loadDogs()の完了を待つ

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
    await tester.pumpWidget(DogHealthApp(apiClient: FakeDogappApiClient()));
    await tester.pump(); // loadDogs()の完了を待つ

    // ホーム画面上のレオカード(DogAvatarを含むInkWell)をタップ
    final leoHomeCard = find.ancestor(
      of: find.text('レオ').first,
      matching: find.byType(InkWell),
    );
    await tester.tap(leoHomeCard.first);
    await tester.pumpAndSettle();

    expect(find.text('体重推移'), findsOneWidget);
  });

  testWidgets('健康チェックタブで写真ボタンをタップすると解析中→結果の順に遷移する', (tester) async {
    await tester.pumpWidget(DogHealthApp(
      apiClient: FakeDogappApiClient(),
      // ネイティブの画像ピッカーはテスト環境で動かないため、ダミーの画像バイト列を返す
      pickImage: () async => Uint8List.fromList([0]),
    ));
    await tester.pump(); // loadDogs()の完了を待つ

    await tester.tap(find.text('健康チェック').last);
    await tester.pumpAndSettle();

    expect(find.text('写真を撮る・選ぶ'), findsOneWidget);

    await tester.tap(find.text('写真を撮る・選ぶ'));
    await tester.pump(); // pickImage()の完了とanalyzing状態への遷移

    expect(find.text('解析しています…'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('もう一度チェックする'), findsOneWidget);
  });

  testWidgets('記録タブで追加ボタンをタップするとモーダルが開き、2つのドロップダウンが表示される', (tester) async {
    await tester.pumpWidget(DogHealthApp(apiClient: FakeDogappApiClient()));
    await tester.pump(); // loadDogs()の完了を待つ

    await tester.tap(find.text('記録').last);
    await tester.pumpAndSettle();

    expect(find.text('記録を追加'), findsOneWidget);

    await tester.tap(find.text('記録を追加'));
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.byType(DropdownButtonFormField), findsNWidgets(2));

    // 閉じるボタンでモーダルが閉じることを確認
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField), findsNothing);
  });

  testWidgets('記録一覧は日付の新しい順に並んでいる', (tester) async {
    await tester.pumpWidget(DogHealthApp(apiClient: FakeDogappApiClient()));
    await tester.pump(); // loadDogs()の完了を待つ

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
