import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/dogs_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../theme/app_theme.dart';

enum _CheckStep { idle, analyzing, result, error }

enum _CheckMedia { photo, video }

/// 画像選択の実処理。「撮る・選ぶ」の両方に対応するため、まずカメラ/ギャラリーを
/// 選ばせてからImagePickerを呼ぶ。テストではネイティブのプラットフォームチャンネルが
/// 使えないため、[AICheckScreen.pickImage]としてフェイクに差し替えられるようにしている。
Future<Uint8List?> pickCheckImage(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                const Icon(Icons.photo_camera_outlined, color: AppColors.ink),
            title: Text(l10n.takePhoto, style: AppText.body),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_library_outlined, color: AppColors.ink),
            title: Text(l10n.chooseFromGallery, style: AppText.body),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final picked =
      await ImagePicker().pickImage(source: source, imageQuality: 85);
  if (picked == null) return null;
  return picked.readAsBytes();
}

/// 動画選択の実処理。歩行チェックは短い動画で十分なため15秒に制限している。
/// バイト列だけでなく元のファイル名(拡張子)もmultipartアップロードに必要なため、
/// [XFile]をそのまま返す。
Future<XFile?> pickCheckVideo(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.videocam_outlined, color: AppColors.ink),
            title: Text(l10n.recordVideo, style: AppText.body),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading:
                const Icon(Icons.video_library_outlined, color: AppColors.ink),
            title: Text(l10n.chooseVideoFromGallery, style: AppText.body),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return ImagePicker()
      .pickVideo(source: source, maxDuration: const Duration(seconds: 15));
}

class AICheckScreen extends StatefulWidget {
  final List<Dog> dogs;
  final DogsRepository repository;
  final Future<Uint8List?> Function(BuildContext context) pickImage;
  final Future<XFile?> Function(BuildContext context) pickVideo;

  const AICheckScreen({
    super.key,
    required this.dogs,
    required this.repository,
    this.pickImage = pickCheckImage,
    this.pickVideo = pickCheckVideo,
  });

  @override
  State<AICheckScreen> createState() => _AICheckScreenState();
}

class _AICheckScreenState extends State<AICheckScreen> {
  _CheckStep _step = _CheckStep.idle;
  _CheckMedia _media = _CheckMedia.photo;
  AICheckResult? _result;
  String? _errorMessage;
  late String _selectedDogId = widget.dogs.first.id;

  void _selectMedia(_CheckMedia media) {
    setState(() {
      _media = media;
      _step = _CheckStep.idle;
      _result = null;
      _errorMessage = null;
    });
  }

  /// 撮影/選択→解析のフロー。
  /// 写真はBase64化してPOST /dogs/{dogId}/ai-checkへ、動画は
  /// multipart/form-dataでPOST /dogs/{dogId}/gait-checkへ送信する。
  Future<void> _runCheck() async {
    Uint8List? photoBytes;
    XFile? video;
    if (_media == _CheckMedia.photo) {
      photoBytes = await widget.pickImage(context);
      if (photoBytes == null) return;
    } else {
      video = await widget.pickVideo(context);
      if (video == null) return;
    }
    if (!mounted) return;
    setState(() => _step = _CheckStep.analyzing);
    try {
      final result = _media == _CheckMedia.photo
          ? await widget.repository
              .runAiCheck(dogId: _selectedDogId, imageBytes: photoBytes!)
          : await widget.repository.runGaitCheck(
              dogId: _selectedDogId,
              videoBytes: await video!.readAsBytes(),
              filename: video.name,
            );
      if (!mounted) return;
      setState(() {
        _result = result;
        _step = _CheckStep.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
        _step = _CheckStep.error;
      });
    }
  }

  void _reset() {
    setState(() {
      _step = _CheckStep.idle;
      _result = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canInteract = _step == _CheckStep.idle;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Text(l10n.healthCheckTitle, style: AppText.display),
        const SizedBox(height: 6),
        Text(
          _media == _CheckMedia.photo
              ? l10n.healthCheckDescription
              : l10n.gaitCheckDescription,
          style: AppText.bodySoft,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MediaModeButton(
                label: l10n.healthCheckModePhoto,
                icon: Icons.photo_camera_outlined,
                selected: _media == _CheckMedia.photo,
                onTap:
                    canInteract ? () => _selectMedia(_CheckMedia.photo) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MediaModeButton(
                label: l10n.healthCheckModeVideo,
                icon: Icons.videocam_outlined,
                selected: _media == _CheckMedia.video,
                onTap:
                    canInteract ? () => _selectMedia(_CheckMedia.video) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: widget.dogs.map((dog) {
            final selected = dog.id == _selectedDogId;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: dog == widget.dogs.first ? 8 : 0),
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedDogId = dog.id),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? dog.accent.withValues(alpha: 0.1)
                        : Colors.white,
                    side: BorderSide(
                      color: selected
                          ? dog.accent
                          : AppColors.ink.withValues(alpha: 0.12),
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(dog.name, style: AppText.body),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _buildStepContent(),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _CheckStep.idle:
        return _IdleCard(onTap: _runCheck, media: _media);
      case _CheckStep.analyzing:
        return _AnalyzingCard(
          accent: widget.dogs.firstWhere((d) => d.id == _selectedDogId).accent,
        );
      case _CheckStep.result:
        return _ResultCard(result: _result!, onReset: _reset);
      case _CheckStep.error:
        return _ErrorCard(message: _errorMessage!, onRetry: _reset);
    }
  }
}

class _MediaModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _MediaModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? AppColors.ink.withValues(alpha: 0.06) : Colors.white,
        side: BorderSide(
            color: selected
                ? AppColors.ink
                : AppColors.ink.withValues(alpha: 0.12)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      icon: Icon(icon, size: 16, color: AppColors.ink),
      label: Text(label, style: AppText.body),
    );
  }
}

class _IdleCard extends StatelessWidget {
  final VoidCallback onTap;
  final _CheckMedia media;

  const _IdleCard({required this.onTap, required this.media});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVideo = media == _CheckMedia.video;
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: DottedBorderBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVideo ? Icons.videocam_outlined : Icons.camera_alt_outlined,
                  color: AppColors.ink,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(isVideo ? l10n.takeOrChooseVideo : l10n.takeOrChoosePhoto,
                  style: AppText.body),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_outlined,
                      size: 12, color: AppColors.inkSoft),
                  const SizedBox(width: 4),
                  Text(isVideo ? l10n.tapToUploadVideo : l10n.tapToUpload,
                      style: AppText.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 破線の枠。React版の border-dashed に相当するものを
/// CustomPainterで簡易的に描画する(パッケージ不使用)。
class DottedBorderBox extends StatelessWidget {
  final Widget child;

  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        // 注: num.clamp()はnumを返すためdouble引数箇所では型エラーになる。
        // ここでは明示的にdoubleのままmin相当の計算をする。
        final end = next > metric.length ? metric.length : next;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnalyzingCard extends StatelessWidget {
  final Color accent;

  const _AnalyzingCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(accent),
                  backgroundColor: AppColors.ink.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.analyzing,
                  style: AppText.bodySoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.concernBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.concernBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 20, color: AppColors.concernBorder),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      Text(l10n.analysisFailed, style: AppText.displaySmall)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: AppText.body),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.concernBorder),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.tryAgain, style: AppText.body),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final AICheckResult result;
  final VoidCallback onReset;

  const _ResultCard({required this.result, required this.onReset});

  ({Color bg, Color border, IconData icon}) get _style {
    switch (result.level) {
      case AICheckLevel.normal:
        return (
          bg: AppColors.normalBg,
          border: AppColors.normalBorder,
          icon: Icons.check_circle_outline
        );
      case AICheckLevel.watch:
        return (
          bg: AppColors.watchBg,
          border: AppColors.watchBorder,
          icon: Icons.error_outline
        );
      case AICheckLevel.concern:
        return (
          bg: AppColors.concernBg,
          border: AppColors.concernBorder,
          icon: Icons.error_outline
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
            ),
            child: Icon(Icons.pets,
                size: 40, color: AppColors.ink.withValues(alpha: 0.15)),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: s.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(s.icon, size: 20, color: s.border),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(result.title, style: AppText.displaySmall)),
                ],
              ),
              const SizedBox(height: 8),
              Text(result.detail, style: AppText.body),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.ink.withValues(alpha: 0.18)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(l10n.checkAgain, style: AppText.body),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.aiCheckDisclaimer,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
