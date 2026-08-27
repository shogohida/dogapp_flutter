import 'package:flutter/material.dart';
import '../models/dog.dart';
import '../theme/app_theme.dart';

/// React版でrechartsを使っていた体重推移グラフを、外部パッケージなしで
/// CustomPainterにより自前実装したもの。
/// "no deps"方針(apilabのGraphQLエンジンを標準ライブラリのreflectだけで
/// 書いたのと同じ考え方)をFlutter版でも踏襲している。
class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final Color accent;
  final double height;

  const WeightChart({
    super.key,
    required this.entries,
    required this.accent,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WeightChartPainter(entries: entries, accent: accent),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final Color accent;

  _WeightChartPainter({required this.entries, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const leftPadding = 32.0;
    const rightPadding = 8.0;
    const topPadding = 12.0;
    const bottomPadding = 20.0;

    final plotWidth = size.width - leftPadding - rightPadding;
    final plotHeight = size.height - topPadding - bottomPadding;

    final kgValues = entries.map((e) => e.kg).toList();
    final minKg = kgValues.reduce((a, b) => a < b ? a : b) - 1;
    final maxKg = kgValues.reduce((a, b) => a > b ? a : b) + 1;
    // 注: double.clamp() は num を返すため、そのままOffset等のdouble引数に
    // 渡すと型エラーになる。ここでは明示的にdoubleのまま計算する。
    final rawRange = maxKg - minKg;
    final double range = rawRange < 0.1 ? 0.1 : rawRange;

    Offset pointFor(int index, double kg) {
      final x = leftPadding +
          (entries.length == 1
              ? plotWidth / 2
              : plotWidth * index / (entries.length - 1));
      final y = topPadding + plotHeight * (1 - (kg - minKg) / range);
      return Offset(x, y);
    }

    // Y軸の目盛り線(min/mid/max)
    final gridPaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final t in [0.0, 0.5, 1.0]) {
      final y = topPadding + plotHeight * t;
      canvas.drawLine(Offset(leftPadding, y),
          Offset(size.width - rightPadding, y), gridPaint);

      final labelValue = maxKg - (maxKg - minKg) * t;
      final tp = TextPainter(
        text: TextSpan(
          text: labelValue.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 9,
            fontFamily: 'monospace',
            color: AppColors.inkSoft,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // 折れ線
    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final p = pointFor(i, entries[i].kg);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // データ点とX軸ラベル(月)
    final dotPaint = Paint()..color = accent;
    for (var i = 0; i < entries.length; i++) {
      final p = pointFor(i, entries[i].kg);
      canvas.drawCircle(p, 3, dotPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: entries[i].month,
          style: const TextStyle(
            fontSize: 9,
            fontFamily: 'monospace',
            color: AppColors.inkSoft,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(p.dx - tp.width / 2, size.height - bottomPadding + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.entries != entries || oldDelegate.accent != accent;
  }
}
