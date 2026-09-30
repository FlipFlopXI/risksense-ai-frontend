import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:medguide/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDuration = Duration(milliseconds: 4600);
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _detailsFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _splashDuration);
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.24, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeOutCubic),
      ),
    );
    _detailsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.14, 0.38, curve: Curves.easeOut),
    );
    _controller.forward().whenComplete(() {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final logoSize = math.min(screenWidth * 0.78, 340.0);
          return Stack(
            children: [
              const Positioned.fill(child: _SplashBackground()),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.08),
                                    blurRadius: 36,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Semantics(
                                label: 'RiskSense AI logo',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.asset(
                                    'assets/images/risksense_logo.jpg',
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 27),
                        FadeTransition(
                          opacity: _detailsFade,
                          child: const Text(
                            'Secure Clinical Decision Support',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        FadeTransition(
                          opacity: _detailsFade,
                          child: Container(
                            width: math.min(screenWidth - 56, 350),
                            padding: const EdgeInsets.fromLTRB(18, 13, 18, 11),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(22),
                              border:
                                  Border.all(color: const Color(0xFFD5EBFA)),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 56,
                                  width: double.infinity,
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, _) => CustomPaint(
                                      painter: _EcgPainter(
                                        progress: _controller.value,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Preparing your experience',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 25,
                right: 24,
                child: SafeArea(
                  child: Text(
                    'v1.0.0',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F3FF), Color(0xFFF4FAFF), Colors.white],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            top: -120,
            right: -110,
            child: _Halo(size: 300, color: Color(0xFFB8E2FA)),
          ),
          Positioned(
            bottom: -135,
            left: -105,
            child: _Halo(size: 330, color: Color(0xFFCDEBFB)),
          ),
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  final double size;
  final Color color;
  const _Halo({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.38),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
        ),
      );
}

class _EcgPainter extends CustomPainter {
  final double progress;
  const _EcgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.58;
    final path = Path()..moveTo(0, y);
    const waveform = <Offset>[
      Offset(0.08, 0),
      Offset(0.15, 0),
      Offset(0.19, -0.13),
      Offset(0.23, 0.17),
      Offset(0.28, -0.78),
      Offset(0.33, 0.37),
      Offset(0.38, 0),
      Offset(0.51, 0),
      Offset(0.55, -0.12),
      Offset(0.59, 0.15),
      Offset(0.64, -0.7),
      Offset(0.69, 0.34),
      Offset(0.74, 0),
      Offset(0.88, 0),
      Offset(1, 0),
    ];
    for (final point in waveform) {
      path.lineTo(point.dx * size.width, y + point.dy * size.height);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD8E8F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final metric = path.computeMetrics().first;
    final visibleLength = metric.length * progress.clamp(0.0, 1.0);
    if (visibleLength <= 0) return;
    final visiblePath = metric.extractPath(0, visibleLength);
    canvas.drawPath(
      visiblePath,
      Paint()
        ..color = AppColors.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final tip = metric.getTangentForOffset(visibleLength)?.position;
    if (tip != null) {
      canvas.drawCircle(
        tip,
        5,
        Paint()..color = AppColors.teal.withValues(alpha: 0.22),
      );
      canvas.drawCircle(tip, 2.6, Paint()..color = AppColors.teal);
    }
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
