import 'package:flutter/material.dart';
import '../models/dog.dart';

/// React版の `<DogAvatar>` に対応。犬種アイコンを、犬ごとのアクセントカラーで
/// 縁取った円の中に表示する(実際の写真は本番でネットワーク画像に差し替え)。
class DogAvatar extends StatelessWidget {
  final Dog dog;
  final double size;

  const DogAvatar({super.key, required this.dog, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dog.accent.withValues(alpha: 0.13),
        border: Border.all(color: dog.accent, width: 2),
      ),
      child: Icon(Icons.pets, color: dog.accent, size: size * 0.42),
    );
  }
}
