// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '犬の健康管理';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabDogs => '犬たち';

  @override
  String get tabHealthCheck => '健康チェック';

  @override
  String get tabRecords => '記録';

  @override
  String get tabWalk => '散歩';

  @override
  String get loadErrorTitle => 'dogapp-apiに接続できませんでした';

  @override
  String get retry => '再試行';

  @override
  String get noDogsRegistered => '登録されている犬がいません';

  @override
  String get welcomeBack => 'おかえりなさい';

  @override
  String healthRecordsSummary(int count) {
    return '$count匹の健康記録、今日も欠かさず。';
  }

  @override
  String get upcoming => '今後の予定';

  @override
  String dogInfoLine(String color, int age) {
    return '$color ・ $age歳';
  }

  @override
  String get dogsTitle => '犬たち';

  @override
  String get weightHistory => '体重推移';

  @override
  String get recordsTitle => '記録';

  @override
  String breedColorLine(String breed, String color) {
    return '$breed ・ $color';
  }

  @override
  String get healthCheckTitle => '健康チェック';

  @override
  String get healthCheckDescription =>
      '皮膚・被毛の写真を撮ると、気になる変化がないかを簡易チェックします。診断ではなく、動物病院に相談すべきかどうかの目安です。';

  @override
  String get takeOrChoosePhoto => '写真を撮る・選ぶ';

  @override
  String get tapToUpload => 'タップしてアップロード';

  @override
  String get takePhoto => 'カメラで撮影';

  @override
  String get chooseFromGallery => 'ギャラリーから選択';

  @override
  String get analyzing => '解析しています…';

  @override
  String get analysisFailed => '解析に失敗しました';

  @override
  String get tryAgain => 'もう一度試す';

  @override
  String get checkAgain => 'もう一度チェックする';

  @override
  String get aiCheckDisclaimer =>
      '※ これはAIによる簡易チェックです。診断ではないため、心配な症状は動物病院を受診してください。';

  @override
  String get healthCheckModePhoto => '写真';

  @override
  String get healthCheckModeVideo => '動画(歩行)';

  @override
  String get gaitCheckDescription =>
      '歩き方に違和感がないか、短い動画から簡易チェックします。診断ではなく、動物病院に相談すべきかどうかの目安です。';

  @override
  String get takeOrChooseVideo => '動画を撮る・選ぶ';

  @override
  String get tapToUploadVideo => 'タップして動画をアップロード';

  @override
  String get recordVideo => '動画を撮影';

  @override
  String get chooseVideoFromGallery => 'ギャラリーから動画を選択';

  @override
  String get addRecord => '記録を追加';

  @override
  String get noteOptional => 'メモ(任意)';

  @override
  String get save => '保存する';

  @override
  String saveFailed(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get recordTypeVaccine => 'ワクチン接種';

  @override
  String get recordTypeGrooming => 'トリミング';

  @override
  String get recordTypeVet => '通院';

  @override
  String get recordTypeMedication => '投薬';

  @override
  String get walkTitle => '散歩';

  @override
  String get startWalk => '散歩を始める';

  @override
  String get stopWalk => '散歩を終える';

  @override
  String get recording => '記録中…';

  @override
  String get distance => '距離';

  @override
  String get duration => '時間';

  @override
  String get pace => 'ペース';

  @override
  String get walkHistory => '散歩の記録';

  @override
  String get recommendedCourses => 'おすすめ散歩コース';

  @override
  String get noWalksYet => 'まだ散歩の記録がありません';

  @override
  String get noRecommendationsYet => '散歩を記録すると、よく歩くコースをおすすめします';

  @override
  String walkedNTimes(int count) {
    return '$count回歩いたコース';
  }

  @override
  String get locationPermissionDenied => '位置情報の利用が許可されていません';

  @override
  String get locationServiceDisabled => '位置情報サービスが無効になっています';

  @override
  String saveWalkFailed(String error) {
    return '散歩記録の保存に失敗しました: $error';
  }

  @override
  String loadWalksFailed(String error) {
    return '散歩記録の読み込みに失敗しました: $error';
  }

  @override
  String get discardWalk => '破棄する';

  @override
  String get discardWalkConfirm => 'この散歩の記録を破棄しますか?';

  @override
  String get cancel => 'キャンセル';

  @override
  String get km => 'km';

  @override
  String get minutesShort => '分';
}
