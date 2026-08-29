import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja')
  ];

  /// アプリタイトル
  ///
  /// In ja, this message translates to:
  /// **'犬の健康管理'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get tabHome;

  /// No description provided for @tabDogs.
  ///
  /// In ja, this message translates to:
  /// **'犬たち'**
  String get tabDogs;

  /// No description provided for @tabHealthCheck.
  ///
  /// In ja, this message translates to:
  /// **'健康チェック'**
  String get tabHealthCheck;

  /// No description provided for @tabRecords.
  ///
  /// In ja, this message translates to:
  /// **'記録'**
  String get tabRecords;

  /// No description provided for @tabWalk.
  ///
  /// In ja, this message translates to:
  /// **'散歩'**
  String get tabWalk;

  /// No description provided for @loadErrorTitle.
  ///
  /// In ja, this message translates to:
  /// **'dogapp-apiに接続できませんでした'**
  String get loadErrorTitle;

  /// No description provided for @retry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;

  /// No description provided for @noDogsRegistered.
  ///
  /// In ja, this message translates to:
  /// **'登録されている犬がいません'**
  String get noDogsRegistered;

  /// No description provided for @loginTitle.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get loginTitle;

  /// No description provided for @signupTitle.
  ///
  /// In ja, this message translates to:
  /// **'アカウント作成'**
  String get signupTitle;

  /// No description provided for @emailLabel.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get loginButton;

  /// No description provided for @signupButton.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを作成'**
  String get signupButton;

  /// No description provided for @switchToSignup.
  ///
  /// In ja, this message translates to:
  /// **'アカウントをお持ちでない方はこちら'**
  String get switchToSignup;

  /// No description provided for @switchToLogin.
  ///
  /// In ja, this message translates to:
  /// **'すでにアカウントをお持ちの方はこちら'**
  String get switchToLogin;

  /// No description provided for @authFailed.
  ///
  /// In ja, this message translates to:
  /// **'認証に失敗しました: {error}'**
  String authFailed(String error);

  /// No description provided for @passwordTooShort.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは8文字以上で入力してください'**
  String get passwordTooShort;

  /// No description provided for @logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get logout;

  /// No description provided for @addDog.
  ///
  /// In ja, this message translates to:
  /// **'犬を追加'**
  String get addDog;

  /// No description provided for @welcomeBack.
  ///
  /// In ja, this message translates to:
  /// **'おかえりなさい'**
  String get welcomeBack;

  /// No description provided for @healthRecordsSummary.
  ///
  /// In ja, this message translates to:
  /// **'{count}匹の健康記録、今日も欠かさず。'**
  String healthRecordsSummary(int count);

  /// No description provided for @upcoming.
  ///
  /// In ja, this message translates to:
  /// **'今後の予定'**
  String get upcoming;

  /// No description provided for @addUpcoming.
  ///
  /// In ja, this message translates to:
  /// **'予定を追加'**
  String get addUpcoming;

  /// No description provided for @noUpcomingItems.
  ///
  /// In ja, this message translates to:
  /// **'今後の予定はありません'**
  String get noUpcomingItems;

  /// No description provided for @date.
  ///
  /// In ja, this message translates to:
  /// **'日付'**
  String get date;

  /// No description provided for @dogInfoLine.
  ///
  /// In ja, this message translates to:
  /// **'{color} ・ {age}歳'**
  String dogInfoLine(String color, int age);

  /// No description provided for @dogsTitle.
  ///
  /// In ja, this message translates to:
  /// **'犬たち'**
  String get dogsTitle;

  /// No description provided for @weightHistory.
  ///
  /// In ja, this message translates to:
  /// **'体重推移'**
  String get weightHistory;

  /// No description provided for @currentWeight.
  ///
  /// In ja, this message translates to:
  /// **'体重'**
  String get currentWeight;

  /// No description provided for @recordsTitle.
  ///
  /// In ja, this message translates to:
  /// **'記録'**
  String get recordsTitle;

  /// No description provided for @shareProfile.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールをシェア'**
  String get shareProfile;

  /// No description provided for @editProfile.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを編集'**
  String get editProfile;

  /// No description provided for @dogNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'名前'**
  String get dogNameLabel;

  /// No description provided for @dogBreedLabel.
  ///
  /// In ja, this message translates to:
  /// **'犬種'**
  String get dogBreedLabel;

  /// No description provided for @dogColorLabel.
  ///
  /// In ja, this message translates to:
  /// **'毛色'**
  String get dogColorLabel;

  /// No description provided for @dogBirthYearLabel.
  ///
  /// In ja, this message translates to:
  /// **'生まれた年'**
  String get dogBirthYearLabel;

  /// No description provided for @invalidBirthYear.
  ///
  /// In ja, this message translates to:
  /// **'正しい生まれた年を入力してください'**
  String get invalidBirthYear;

  /// No description provided for @profileFieldsRequired.
  ///
  /// In ja, this message translates to:
  /// **'名前・犬種・毛色を入力してください'**
  String get profileFieldsRequired;

  /// No description provided for @updateDogFailed.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールの更新に失敗しました: {error}'**
  String updateDogFailed(String error);

  /// No description provided for @shareFailed.
  ///
  /// In ja, this message translates to:
  /// **'シェアに失敗しました: {error}'**
  String shareFailed(String error);

  /// No description provided for @breedColorLine.
  ///
  /// In ja, this message translates to:
  /// **'{breed} ・ {color}'**
  String breedColorLine(String breed, String color);

  /// No description provided for @healthCheckTitle.
  ///
  /// In ja, this message translates to:
  /// **'健康チェック'**
  String get healthCheckTitle;

  /// No description provided for @healthCheckDescription.
  ///
  /// In ja, this message translates to:
  /// **'皮膚・被毛の写真を撮ると、気になる変化がないかを簡易チェックします。診断ではなく、動物病院に相談すべきかどうかの目安です。'**
  String get healthCheckDescription;

  /// No description provided for @takeOrChoosePhoto.
  ///
  /// In ja, this message translates to:
  /// **'写真を撮る・選ぶ'**
  String get takeOrChoosePhoto;

  /// No description provided for @tapToUpload.
  ///
  /// In ja, this message translates to:
  /// **'タップしてアップロード'**
  String get tapToUpload;

  /// No description provided for @takePhoto.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択'**
  String get chooseFromGallery;

  /// No description provided for @analyzing.
  ///
  /// In ja, this message translates to:
  /// **'解析しています…'**
  String get analyzing;

  /// No description provided for @analysisFailed.
  ///
  /// In ja, this message translates to:
  /// **'解析に失敗しました'**
  String get analysisFailed;

  /// No description provided for @tryAgain.
  ///
  /// In ja, this message translates to:
  /// **'もう一度試す'**
  String get tryAgain;

  /// No description provided for @checkAgain.
  ///
  /// In ja, this message translates to:
  /// **'もう一度チェックする'**
  String get checkAgain;

  /// No description provided for @aiCheckDisclaimer.
  ///
  /// In ja, this message translates to:
  /// **'※ これはAIによる簡易チェックです。診断ではないため、心配な症状は動物病院を受診してください。'**
  String get aiCheckDisclaimer;

  /// No description provided for @healthCheckRecordLabel.
  ///
  /// In ja, this message translates to:
  /// **'健康チェック: {title}'**
  String healthCheckRecordLabel(String title);

  /// No description provided for @gaitCheckRecordLabel.
  ///
  /// In ja, this message translates to:
  /// **'歩行チェック: {title}'**
  String gaitCheckRecordLabel(String title);

  /// No description provided for @healthCheckModePhoto.
  ///
  /// In ja, this message translates to:
  /// **'写真'**
  String get healthCheckModePhoto;

  /// No description provided for @healthCheckModeVideo.
  ///
  /// In ja, this message translates to:
  /// **'動画(歩行)'**
  String get healthCheckModeVideo;

  /// No description provided for @gaitCheckDescription.
  ///
  /// In ja, this message translates to:
  /// **'歩き方に違和感がないか、短い動画から簡易チェックします。診断ではなく、動物病院に相談すべきかどうかの目安です。'**
  String get gaitCheckDescription;

  /// No description provided for @takeOrChooseVideo.
  ///
  /// In ja, this message translates to:
  /// **'動画を撮る・選ぶ'**
  String get takeOrChooseVideo;

  /// No description provided for @tapToUploadVideo.
  ///
  /// In ja, this message translates to:
  /// **'タップして動画をアップロード'**
  String get tapToUploadVideo;

  /// No description provided for @recordVideo.
  ///
  /// In ja, this message translates to:
  /// **'動画を撮影'**
  String get recordVideo;

  /// No description provided for @chooseVideoFromGallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから動画を選択'**
  String get chooseVideoFromGallery;

  /// No description provided for @addRecord.
  ///
  /// In ja, this message translates to:
  /// **'記録を追加'**
  String get addRecord;

  /// No description provided for @recordTypeHint.
  ///
  /// In ja, this message translates to:
  /// **'種別(例: ワクチン接種)'**
  String get recordTypeHint;

  /// No description provided for @recordTypeRequired.
  ///
  /// In ja, this message translates to:
  /// **'種別を入力してください'**
  String get recordTypeRequired;

  /// No description provided for @noteOptional.
  ///
  /// In ja, this message translates to:
  /// **'メモ(任意)'**
  String get noteOptional;

  /// No description provided for @costOptional.
  ///
  /// In ja, this message translates to:
  /// **'費用(任意)'**
  String get costOptional;

  /// No description provided for @invalidCost.
  ///
  /// In ja, this message translates to:
  /// **'費用は0以上の数値で入力してください'**
  String get invalidCost;

  /// No description provided for @totalCost.
  ///
  /// In ja, this message translates to:
  /// **'費用の合計: {amount}'**
  String totalCost(String amount);

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存する'**
  String get save;

  /// No description provided for @saveFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存に失敗しました: {error}'**
  String saveFailed(String error);

  /// No description provided for @recordTypeVaccine.
  ///
  /// In ja, this message translates to:
  /// **'ワクチン接種'**
  String get recordTypeVaccine;

  /// No description provided for @recordTypeGrooming.
  ///
  /// In ja, this message translates to:
  /// **'トリミング'**
  String get recordTypeGrooming;

  /// No description provided for @recordTypeVet.
  ///
  /// In ja, this message translates to:
  /// **'通院'**
  String get recordTypeVet;

  /// No description provided for @recordTypeMedication.
  ///
  /// In ja, this message translates to:
  /// **'投薬'**
  String get recordTypeMedication;

  /// No description provided for @walkTitle.
  ///
  /// In ja, this message translates to:
  /// **'散歩'**
  String get walkTitle;

  /// No description provided for @startWalk.
  ///
  /// In ja, this message translates to:
  /// **'散歩を始める'**
  String get startWalk;

  /// No description provided for @stopWalk.
  ///
  /// In ja, this message translates to:
  /// **'散歩を終える'**
  String get stopWalk;

  /// No description provided for @recording.
  ///
  /// In ja, this message translates to:
  /// **'記録中…'**
  String get recording;

  /// No description provided for @distance.
  ///
  /// In ja, this message translates to:
  /// **'距離'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In ja, this message translates to:
  /// **'時間'**
  String get duration;

  /// No description provided for @pace.
  ///
  /// In ja, this message translates to:
  /// **'ペース'**
  String get pace;

  /// No description provided for @walkHistory.
  ///
  /// In ja, this message translates to:
  /// **'散歩の記録'**
  String get walkHistory;

  /// No description provided for @recommendedCourses.
  ///
  /// In ja, this message translates to:
  /// **'おすすめ散歩コース'**
  String get recommendedCourses;

  /// No description provided for @noWalksYet.
  ///
  /// In ja, this message translates to:
  /// **'まだ散歩の記録がありません'**
  String get noWalksYet;

  /// No description provided for @noRecommendationsYet.
  ///
  /// In ja, this message translates to:
  /// **'散歩を記録すると、よく歩くコースをおすすめします'**
  String get noRecommendationsYet;

  /// No description provided for @walkedNTimes.
  ///
  /// In ja, this message translates to:
  /// **'{count}回歩いたコース'**
  String walkedNTimes(int count);

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ja, this message translates to:
  /// **'位置情報の利用が許可されていません'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In ja, this message translates to:
  /// **'位置情報サービスが無効になっています'**
  String get locationServiceDisabled;

  /// No description provided for @saveWalkFailed.
  ///
  /// In ja, this message translates to:
  /// **'散歩記録の保存に失敗しました: {error}'**
  String saveWalkFailed(String error);

  /// No description provided for @loadWalksFailed.
  ///
  /// In ja, this message translates to:
  /// **'散歩記録の読み込みに失敗しました: {error}'**
  String loadWalksFailed(String error);

  /// No description provided for @discardWalk.
  ///
  /// In ja, this message translates to:
  /// **'破棄する'**
  String get discardWalk;

  /// No description provided for @discardWalkConfirm.
  ///
  /// In ja, this message translates to:
  /// **'この散歩の記録を破棄しますか?'**
  String get discardWalkConfirm;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @km.
  ///
  /// In ja, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @minutesShort.
  ///
  /// In ja, this message translates to:
  /// **'分'**
  String get minutesShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
