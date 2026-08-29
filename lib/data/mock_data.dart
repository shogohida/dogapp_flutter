import '../models/dog.dart';
import '../theme/app_theme.dart';

/// Web版(DogHealthApp.jsx)と同じモックデータをDartに移植したもの。
/// 本番では dogapp-api の GET /owners/{ownerId}/dogs 等から取得する。

final List<Dog> mockDogs = [
  Dog(
    id: 'leo',
    name: 'レオ',
    breed: 'スタンダードプードル',
    color: 'アプリコット',
    birthYear: 2021,
    accent: AppColors.marigold,
    weightHistory: const [
      WeightEntry(month: '3月', kg: 24.8),
      WeightEntry(month: '4月', kg: 25.1),
      WeightEntry(month: '5月', kg: 24.9),
      WeightEntry(month: '6月', kg: 25.3),
      WeightEntry(month: '7月', kg: 25.4),
      WeightEntry(month: '8月', kg: 25.2),
    ],
    records: [
      HealthRecord(
        id: '1',
        type: 'vaccine',
        label: '混合ワクチン接種',
        date: DateTime(2026, 7, 12),
        cost: 8000,
      ),
      HealthRecord(
        id: '2',
        type: 'grooming',
        label: 'トリミング(サマーカット)',
        date: DateTime(2026, 8, 2),
        cost: 6500,
      ),
      HealthRecord(
        id: '3',
        type: 'vet',
        label: '定期健診',
        date: DateTime(2026, 8, 15),
        cost: 4500,
      ),
    ],
  ),
  Dog(
    id: 'noa',
    name: 'ノア',
    breed: 'スタンダードプードル',
    color: 'ブラック',
    birthYear: 2022,
    accent: AppColors.sageDark,
    weightHistory: const [
      WeightEntry(month: '3月', kg: 22.1),
      WeightEntry(month: '4月', kg: 22.3),
      WeightEntry(month: '5月', kg: 22.6),
      WeightEntry(month: '6月', kg: 22.4),
      WeightEntry(month: '7月', kg: 22.8),
      WeightEntry(month: '8月', kg: 23.0),
    ],
    records: [
      HealthRecord(
        id: '1',
        type: 'grooming',
        label: 'トリミング(全身カット)',
        date: DateTime(2026, 8, 5),
        cost: 7000,
      ),
      HealthRecord(
        id: '2',
        type: 'vaccine',
        label: '狂犬病予防接種',
        date: DateTime(2026, 6, 20),
        cost: 3500,
      ),
    ],
  ),
];

final List<UpcomingItem> mockUpcoming = [
  UpcomingItem(
    id: '1',
    dogId: 'leo',
    label: '次回トリミング予約',
    date: DateTime(2026, 9, 1),
    type: RecordType.grooming,
  ),
  UpcomingItem(
    id: '2',
    dogId: 'noa',
    label: 'フィラリア予防投薬',
    date: DateTime(2026, 8, 28),
    type: RecordType.medication,
  ),
  UpcomingItem(
    id: '3',
    dogId: 'leo',
    label: '定期健診フォローアップ',
    date: DateTime(2026, 9, 10),
    type: RecordType.vet,
  ),
];

/// AIチェックの模擬レスポンス。
/// 本番では dogapp-api の POST /dogs/{dogId}/ai-check を呼び出し、
/// Claude APIによる実際の画像解析結果に置き換える(README参照)。
final List<AICheckResult> mockAIResults = [
  const AICheckResult(
    level: AICheckLevel.normal,
    title: '特に気になる所見はありません',
    detail: '被毛のツヤ・皮膚の赤みともに正常範囲内に見えます。プードルは巻き毛の根元が蒸れやすいため、'
        'この状態を保つには週2〜3回のブラッシングを継続してください。',
  ),
  const AICheckResult(
    level: AICheckLevel.watch,
    title: '軽度の乾燥が見られます',
    detail: '被毛の一部にパサつきが見られます。シャンプーの頻度が高すぎないか、保湿系のケア用品を'
        '使っているかを確認してください。1週間ほど様子を見て変化がなければ問題ありません。',
  ),
  const AICheckResult(
    level: AICheckLevel.concern,
    title: '赤み・脱毛が疑われます',
    detail: '皮膚の赤みと部分的な脱毛のような所見が見られます。プードルはアレルギー性皮膚炎に'
        'なりやすい犬種です。自己判断せず、早めに動物病院での診察をおすすめします。',
  ),
];
