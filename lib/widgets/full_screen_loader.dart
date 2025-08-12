import 'package:flutter/material.dart';

/// Full-screen premium loading overlay with dark background, glow, and animated logo.
class FullScreenLoader extends StatefulWidget {
  const FullScreenLoader({super.key});

  @override
  State<FullScreenLoader> createState() => _FullScreenLoaderState();
}
  
class _FullScreenLoaderState extends State<FullScreenLoader> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.2,
                  colors: const [
                    Color(0xFF0B0B10),
                    Color(0xFF0E0E12),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x33007BFF), Color(0x333800FF)],
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseController, _rotateController]),
              builder: (context, _) {
                final scale = _pulseController.value;
                return Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft neon glow behind logo
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                              blurRadius: 80,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00D4FF).withValues(alpha: 0.18),
                              blurRadius: 100,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      // Rotating thin ring
                      Transform.rotate(
                        angle: _rotateController.value * 6.28318530718,
                        child: CustomPaint(
                          size: const Size(200, 200),
                          painter: _GradientRingPainter(),
                        ),
                      ),
                      // Logo
                      Image.asset(
                        'assets/img/ideaxy_logo_only.png',
                        width: 140,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = SweepGradient(
      colors: const [
        Color(0xFF7C4DFF),
        Color(0xFF00D4FF),
        Color(0xFF7C4DFF),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    final radius = (size.shortestSide / 2) - paint.strokeWidth;
    canvas.drawArc(Rect.fromCircle(center: size.center(Offset.zero), radius: radius), 0, 6.28318530718, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple API to show/hide loader as an overlay.
class AppLoaderOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => const FullScreenLoader(),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    try {
      if (_entry?.mounted == true) {
        _entry!.remove();
      }
    } catch (_) {
      // Overlay may have been disposed during route change; ignore.
    } finally {
      _entry = null;
    }
  }
}


