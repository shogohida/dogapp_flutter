import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 犬プロフィールカードをOSの共有シート経由でシェアする実処理。
/// Instagramにはアプリから直接投稿するAPIが無いため、共有シートで
/// Instagram(ストーリーズ等)を選んでもらう形にしている。
/// テストではネイティブのプラットフォームチャンネルが使えないため、
/// DogProfileScreen.shareImageとしてフェイクに差し替えられるようにしている。
Future<void> shareDogProfileImage(Uint8List pngBytes, String dogName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/dog_profile_$dogName.png');
  await file.writeAsBytes(pngBytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: dogName),
  );
}
