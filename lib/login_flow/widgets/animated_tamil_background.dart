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
    // Speed up the background animation so letters move faster.
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    // Spread letters evenly across the horizontal axis with increased
    // padding to create more space between glyphs. Use a small jitter so
    // positions feel organic but remain well separated.
    final n = _letters.length;
    const double hPad = 0.12; // horizontal padding fraction on each side
    _xFactors = List.generate(n, (i) {
      final base = (i + 0.5) / n; // evenly spaced center positions in [0,1]
      final jitter = (_rng.nextDouble() - 0.5) * 0.12; // +/-6% jitter
      final pos = (hPad + base * (1 - 2 * hPad) + jitter).clamp(0.02, 0.98);
      return pos;
    });
    // Keep vertical positions varied but constrained to avoid edge overlap.
    _yFactors = List.generate(n, (_) => 0.18 + _rng.nextDouble() * 0.64);
    // Use a fixed uniform font size for all glyphs to reduce visual clutter.
    _sizes = List.generate(n, (_) => 34.0);
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

    // Colors matching level selection buttons: light blue (beginner),
    // yellow (intermediate), and red (expert).
    const yellow = Color(0xFFFFC107);
    const red = Color(0xFFF44336);
    const lightBlue = Color(0xFF00BCD4);
    final colors = [lightBlue, yellow, red];

    for (var i = 0; i < letters.length; i++) {
      final x = (xFactors[i] * size.width);
      final baseY = (yFactors[i] * size.height);
      // Faster vertical oscillation so the letters feel lively.
      final y = baseY + sin(time * 1.6 + i * 0.9) * 12.0;
      // Fixed opacity so colors are vivid but not overpowering.
      final clamped = 0.30;
      final color = colors[i % colors.length].withAlpha((clamped * 255).round());
      final textStyle = TextStyle(color: color, fontSize: sizes[i], fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 2, color: Colors.black.withAlpha(80))]);
      final textSpan = TextSpan(text: letters[i], style: textStyle);
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      canvas.save();
      canvas.translate(x - tp.width / 2, y - tp.height / 2);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _TamilPainter old) => old.time != time;
}
