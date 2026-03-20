import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../meeting/presentation/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward();
    _goToHome();
  }

  Future<void> _goToHome() async {
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0C0E), Color(0xFF060709)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(lineColor: const Color(0x13262B36)),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final glow = Curves.easeInOut.transform(_controller.value);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.14),
                        radius: 0.86 + (0.08 * glow),
                        colors: const [Color(0x14FFFFFF), Color(0x00000000)],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return _AnagramSequence(t: _controller.value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnagramSequence extends StatelessWidget {
  const _AnagramSequence({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.78, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        _MorphWord(word: 'Record', letter: 'R', index: 0, t: t, scale: scale),
        _MorphWord(word: 'Organize', letter: 'O', index: 1, t: t, scale: scale),
        _MorphWord(word: 'Work', letter: 'W', index: 2, t: t, scale: scale),
      ],
    );
  }
}

class _MorphWord extends StatelessWidget {
  const _MorphWord({
    required this.word,
    required this.letter,
    required this.index,
    required this.t,
    required this.scale,
  });

  final String word;
  final String letter;
  final int index;
  final double t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final rest = word.substring(1);

    final startY = (index - 1) * (82 * scale);
    final targetX = (index - 1) * (72 * scale);
    final finalX = (index - 1) * (64 * scale);

    final enterStart = 0.06 + (index * 0.09);
    final enterEnd = enterStart + 0.24;
    final enter = _segment(t, enterStart, enterEnd, Curves.easeOutCubic);

    final shrink = _segment(t, 0.38, 0.62, Curves.easeInOutCubic);
    final move = _segment(t, 0.56, 0.82, Curves.easeInOutCubic);
    final settle = _segment(t, 0.82, 0.95, Curves.easeOutCubic);

    final xStage = lerpDouble(0, targetX, move)!;
    final x = lerpDouble(xStage, finalX, settle)!;
    final y = lerpDouble(startY, 0, move)!;

    final restFactor = (1 - shrink).clamp(0.0, 1.0);
    final letterScale = lerpDouble(1.0, 1.18, move)!;
    final opacity = enter;

    final letterStyle = TextStyle(
      fontSize: 56 * scale,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFF2F4F8),
      height: 1.0,
      letterSpacing: 0.4,
    );
    final wordStyle = TextStyle(
      fontSize: 44 * scale,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFC7CCD7),
      height: 1.0,
      letterSpacing: 0.2,
    );

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(x, y),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: letterScale,
              child: Text(letter, style: letterStyle),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: restFactor,
                child: Opacity(
                  opacity: restFactor,
                  child: Padding(
                    padding: EdgeInsets.only(left: 6 * restFactor),
                    child: Text(rest, style: wordStyle),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _segment(double t, double begin, double end, Curve curve) {
  if (t <= begin) {
    return 0;
  }
  if (t >= end) {
    return 1;
  }
  final normalized = (t - begin) / (end - begin);
  return curve.transform(normalized);
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const spacing = 42.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
