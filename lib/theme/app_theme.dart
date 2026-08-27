import 'package:flutter/material.dart';

/// デザイントークン。Web版(DogHealthApp.jsx)と同じ色を使い、
/// プラットフォームが変わってもブランドの一貫性を保つ。
class AppColors {
  AppColors._();

  static const ink = Color(0xFF1B2A22); // 深い森グリーン、見出し・本文
  static const inkSoft = Color(0xFF5C6B63); // 補助テキスト
  static const paper = Color(0xFFF5EFE2); // カード・画面の背景(暖色系の紙)
  static const paperOuter = Color(0xFFE7E2D5); // 画面外側の背景

  static const marigold = Color(0xFFE2A63B); // レオ(アプリコット)のアクセント
  static const sageDark = Color(0xFF5C6B63); // ノア(ブラック)のアクセント

  /// APIから届く犬の並び順に対してインデックスで割り当てるアクセントカラー。
  /// dogapp-apiのレスポンスに色は含まれないため、表示側で決定的に選ぶ。
  static const accentPalette = [
    marigold,
    sageDark,
    concernBorder,
    normalBorder
  ];

  static const normalBg = Color(0xFFEEF3EE);
  static const normalBorder = Color(0xFF4F7864);
  static const watchBg = Color(0xFFFBF1DE);
  static const watchBorder = Color(0xFFE2A63B);
  static const concernBg = Color(0xFFFBEAE6);
  static const concernBorder = Color(0xFFB5533C);
}

/// タイポグラフィ。本番では pubspec.yaml のコメントの通り
/// Fraunces(見出し) / Inter(本文) / JetBrains Mono(数値・日付) を
/// アセットとして追加すると、Web版とより厳密に統一できる。
/// ここではフォントアセットなしでも破綻しないよう、太さと字間で
/// キャラクターを表現している。
class AppText {
  AppText._();

  static const TextStyle display = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle bodySoft = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSoft,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSoft,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 13,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static const TextStyle monoCaption = TextStyle(
    fontSize: 12,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w500,
    color: AppColors.inkSoft,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.inkSoft,
    letterSpacing: 0.6,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.paperOuter,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.ink),
    fontFamily: null, // システムデフォルトフォントを使用(上記コメント参照)
  );
}
