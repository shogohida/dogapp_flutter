import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/dogs_repository.dart';
import '../models/dog.dart';
import '../theme/app_theme.dart';

enum _CheckStep { idle, analyzing, result, error }

/// 画像選択の実処理。「撮る・選ぶ」の両方に対応するため、まずカメラ/ギャラリーを
/// 選ばせてからImagePickerを呼ぶ。テストではネイティブのプラットフォームチャンネルが
/// 使えないため、[AICheckScreen.pickImage]としてフェイクに差し替えられるようにしている。
Future<Uint8List?> pickCheckImage(BuildContext context) async {
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
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.ink),
            title: const Text('カメラで撮影', style: AppText.body),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.ink),
            title: const Text('ギャラリーから選択', style: AppText.body),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
  if (picked == null) return null;
  return picked.readAsBytes();
}

class AICheckScreen extends StatefulWidget {
  final List<Dog> dogs;
  final DogsRepository repository;
  final Future<Uint8List?> Function(BuildContext context) pickImage;

  const AICheckScreen({
    super.key,
    required this.dogs,
    required this.repository,
    this.pickImage = pickCheckImage,
  });

  @override
  State<AICheckScreen> createState() => _AICheckScreenState();
}

class _AICheckScreenState extends State<AICheckScreen> {
  _CheckStep _step = _CheckStep.idle;
  AICheckResult? _result;
  String? _errorMessage;
  late String _selectedDogId = widget.dogs.first.id;

  /// 写真撮影→解析のフロー。
  /// 選んだ画像をBase64化し、dogapp-apiのPOST /dogs/{dogId}/ai-checkへ送信する。
  Future<void> _runCheck() async {
    final bytes = await widget.pickImage(context);
    if (bytes == null) return;
    if (!mounted) return;
    setState(() => _step = _CheckStep.analyzing);
    try {
      final result = await widget.repository.runAiCheck(dogId: _selectedDogId, imageBytes: bytes);
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text('健康チェック', style: AppText.display),
        const SizedBox(height: 6),
        const Text(
          '皮膚・被毛の写真を撮ると、気になる変化がないかを簡易チェックします。'
          '診断ではなく、動物病院に相談すべきかどうかの目安です。',
          style: AppText.bodySoft,
        ),
        const SizedBox(height: 18),
        Row(
          children: widget.dogs.map((dog) {
            final selected = dog.id == _selectedDogId;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: dog == widget.dogs.first ? 8 : 0),
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedDogId = dog.id),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? dog.accent.withValues(alpha: 0.1) : Colors.white,
                    side: BorderSide(
                      color: selected ? dog.accent : AppColors.ink.withValues(alpha: 0.12),
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
        return _IdleCard(onTap: _runCheck);
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

class _IdleCard extends StatelessWidget {
  final VoidCallback onTap;

  const _IdleCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.ink, size: 26),
              ),
              const SizedBox(height: 12),
              const Text('写真を撮る・選ぶ', style: AppText.body),
              const SizedBox(height: 4),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_outlined, size: 12, color: AppColors.inkSoft),
                  SizedBox(width: 4),
                  Text('タップしてアップロード', style: AppText.caption),
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
              const Text('解析しています…', style: AppText.bodySoft),
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
          const Row(
            children: [
              Icon(Icons.error_outline, size: 20, color: AppColors.concernBorder),
              SizedBox(width: 8),
              Expanded(child: Text('解析に失敗しました', style: AppText.displaySmall)),
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
              child: const Text('もう一度試す', style: AppText.body),
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
        return (bg: AppColors.normalBg, border: AppColors.normalBorder, icon: Icons.check_circle_outline);
      case AICheckLevel.watch:
        return (bg: AppColors.watchBg, border: AppColors.watchBorder, icon: Icons.error_outline);
      case AICheckLevel.concern:
        return (bg: AppColors.concernBg, border: AppColors.concernBorder, icon: Icons.error_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
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
            child: Icon(Icons.pets, size: 40, color: AppColors.ink.withValues(alpha: 0.15)),
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
                  Expanded(child: Text(result.title, style: AppText.displaySmall)),
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
            child: const Text('もう一度チェックする', style: AppText.body),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '※ これはAIによる簡易チェックです。診断ではないため、心配な症状は動物病院を受診してください。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
