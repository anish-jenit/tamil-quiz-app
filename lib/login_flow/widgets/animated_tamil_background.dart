import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
// constants not required here

/// A subtle animated background showing Tamil letters drifting slowly.
/// Designed to be low-cost: a single [AnimationController] and rebuilt
/// transforms for a few text glyphs.
class AnimatedTamilBackground extends StatefulWidget {
  final Color baseColor;
  const AnimatedTamilBackground({super.key, required this.baseColor});

  @override
  State<AnimatedTamilBackground> createState() => _AnimatedTamilBackgroundState();
}

class _AnimatedTamilBackgroundState extends State<AnimatedTamilBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = Random(42);

  // A small set of Tamil characters to render. Keep them simple and readable.
  static const List<String> _letters = ['அ', 'ஆ', 'இ', 'ஈ', 'உ', 'ஏ', 'ஐ', 'ஒ', 'க', 'ச', 'ற', 'ந'];

  // Precompute random positions and sizes for stable layout across rebuilds.
  late final List<double> _xFactors;
  late final List<double> _yFactors;
  late final List<double> _sizes;

  @override
  void initState() {
    super.initState();
  // Slow down the background animation for a calmer effect. We'll tune
  // motion frequency in the painter for smooth, slower movement.
  _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

    // Spread letters evenly across the horizontal axis with increased
    // padding to create more space between glyphs. Use a small jitter so
    // positions feel organic but remain well separated.
    final n = _letters.length;
  // allow glyphs to be placed closer to edges so their motion can reach
  // the corners when we apply large animated offsets in the painter.
  const double hPad = 0.02; // horizontal padding fraction on each side
    _xFactors = List.generate(n, (i) {
      final base = (i + 0.5) / n; // evenly spaced center positions in [0,1]
      final jitter = (_rng.nextDouble() - 0.5) * 0.06; // +/-3% jitter (reduced)
      final pos = (hPad + base * (1 - 2 * hPad) + jitter).clamp(0.02, 0.98);
      return pos;
    });
    // Keep vertical positions varied but constrained to avoid edge overlap.
    _yFactors = List.generate(n, (_) => 0.18 + _rng.nextDouble() * 0.64);
    // Use small-but-legible, varied font sizes so glyphs are visible without
    // dominating the UI. Values chosen to be subtle but readable.
    _sizes = List.generate(n, (_) => 14.0 + _rng.nextDouble() * 10.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value * 2 * pi;
          return CustomPaint(
            painter: _TamilPainter(
              letters: _letters,
              xFactors: _xFactors,
              yFactors: _yFactors,
              sizes: _sizes,
              time: t,
              baseColor: widget.baseColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _TamilPainter extends CustomPainter {
  final List<String> letters;
  final List<double> xFactors;
  final List<double> yFactors;
  final List<double> sizes;
  final double time;
  final Color baseColor;

  _TamilPainter({
    required this.letters,
    required this.xFactors,
    required this.yFactors,
    required this.sizes,
    required this.time,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Compute a two-stop gradient derived from the provided baseColor so the
    // background matches the app's primary/purple tone. We adjust lightness
    // to obtain a pleasant top->bottom variation.
    final rect = Offset.zero & size;
    final baseHsl = HSLColor.fromColor(baseColor);
    final top = baseHsl.withLightness((baseHsl.lightness * 0.85).clamp(0.0, 1.0)).toColor();
    final bottom = baseHsl.withLightness((baseHsl.lightness * 1.25).clamp(0.0, 1.0)).toColor();
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(size.width, size.height), [top, bottom]);
    canvas.drawRect(rect, bgPaint);

    // Render subtle white glyphs for a clean, subdued decorative background.
    for (var i = 0; i < letters.length; i++) {
      // base positions
      final xBase = (xFactors[i] * size.width);
      final baseY = (yFactors[i] * size.height);
      // Compute larger, canvas-scaled offsets so glyphs can travel toward
      // corners. Use lower frequencies for slower, smoother motion.
      final xOffset = sin(time * 0.6 + i * 0.9) * (size.width * 0.28);
      final yOffset = cos(time * 0.5 + i * 0.7) * (size.height * 0.28);
      final x = xBase + xOffset;
      final y = baseY + yOffset;

      // Fully opaque white fill for clarity
      final fillColor = Colors.white;
      // Thin dark stroke beneath the glyph for contrast against light BGs.
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (sizes[i] * 0.08).clamp(1.0, 3.0)
        ..color = Colors.black.withAlpha(160)
        ..isAntiAlias = true;

      // Stroke text painter
      final strokeStyle = TextStyle(
        foreground: strokePaint,
        fontSize: sizes[i],
        fontWeight: FontWeight.w700,
      );
      final strokeSpan = TextSpan(text: letters[i], style: strokeStyle);
      final strokeTp = TextPainter(text: strokeSpan, textDirection: TextDirection.ltr);
      strokeTp.layout();

      // Fill text painter
      final fillStyle = TextStyle(
        color: fillColor,
        fontSize: sizes[i],
        fontWeight: FontWeight.w700,
        shadows: [Shadow(blurRadius: 2, color: Colors.black.withAlpha(100))],
      );
      final fillSpan = TextSpan(text: letters[i], style: fillStyle);
      final fillTp = TextPainter(text: fillSpan, textDirection: TextDirection.ltr);
      fillTp.layout();

      canvas.save();
      canvas.translate(x - fillTp.width / 2, y - fillTp.height / 2);
      // paint stroke then fill to get outlined text
      strokeTp.paint(canvas, Offset.zero);
      fillTp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TamilPainter old) => old.time != time;
}
