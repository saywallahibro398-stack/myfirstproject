import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.client,
    this.initializationError,
    super.key,
  });

  final SupabaseClient? client;
  final String? initializationError;

  void _openAuth(BuildContext context, {required bool signUp}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScreen(
          client: client,
          startWithSignUp: signUp,
          setupError:
              initializationError ??
              AppConfig.fromBuildEnvironment.configurationError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 44,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: math.min(constraints.maxHeight * .43, 330),
                        width: double.infinity,
                        child: const CustomPaint(painter: DreamSkyPainter()),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'little notes,\nbig dreams',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              height: 1.04,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.ink,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'A simple space for your thoughts, ideas and dreams.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppPalette.mutedInk, height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _openAuth(context, signUp: true),
                          child: const Text('Get started'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _openAuth(context, signUp: false),
                        child: const Text(
                          'I already have an account  ·  Log in',
                        ),
                      ),
                      if (client == null || initializationError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppPalette.yellow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            initializationError ??
                                AppConfig
                                    .fromBuildEnvironment
                                    .configurationError ??
                                'Supabase could not initialize. Check the project URL and public key.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppPalette.ink,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DreamSkyPainter extends CustomPainter {
  const DreamSkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = const Color(0xFFF0EAF6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(42)),
      sky,
    );

    final moon = Paint()..color = const Color(0xFFF2DFAC);
    canvas.drawCircle(Offset(size.width * .72, size.height * .27), 37, moon);
    canvas.drawCircle(
      Offset(size.width * .75, size.height * .24),
      34,
      Paint()..color = const Color(0xFFF0EAF6),
    );

    final cloud = Paint()..color = const Color(0xFFFFFEFC);
    _drawCloud(canvas, Offset(size.width * .28, size.height * .38), .88, cloud);
    _drawCloud(canvas, Offset(size.width * .72, size.height * .62), .7, cloud);
    _drawStar(canvas, Offset(size.width * .2, size.height * .2), 9);
    _drawStar(canvas, Offset(size.width * .51, size.height * .2), 7);
    _drawStar(canvas, Offset(size.width * .84, size.height * .48), 6);
    _drawStar(canvas, Offset(size.width * .18, size.height * .69), 7);
    _drawFlower(
      canvas,
      Offset(size.width * .24, size.height * .76),
      16,
      const Color(0xFFE7AFC1),
    );
    _drawFlower(
      canvas,
      Offset(size.width * .76, size.height * .8),
      13,
      const Color(0xFFEAC17C),
    );

    final hill = Paint()..color = const Color(0xFFDDECE3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * 1.05),
        width: size.width * 1.3,
        height: size.height * .58,
      ),
      hill,
    );
  }

  void _drawCloud(Canvas canvas, Offset center, double scale, Paint paint) {
    canvas.drawCircle(
      center.translate(-18 * scale, 4 * scale),
      16 * scale,
      paint,
    );
    canvas.drawCircle(center.translate(0, -5 * scale), 21 * scale, paint);
    canvas.drawCircle(
      center.translate(21 * scale, 4 * scale),
      15 * scale,
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(2 * scale, 10 * scale),
          width: 58 * scale,
          height: 20 * scale,
        ),
        Radius.circular(10 * scale),
      ),
      paint,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..color = const Color(0xFFC3A9D9);
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      final extent = i.isEven ? radius : radius * .28;
      final point = Offset(
        center.dx + math.cos(angle) * extent,
        center.dy + math.sin(angle) * extent,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFlower(Canvas canvas, Offset center, double radius, Color color) {
    final petal = Paint()..color = color;
    for (var i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5;
      canvas.drawCircle(
        center.translate(
          math.cos(angle) * radius * .7,
          math.sin(angle) * radius * .7,
        ),
        radius * .44,
        petal,
      );
    }
    canvas.drawCircle(
      center,
      radius * .3,
      Paint()..color = const Color(0xFFF5E7B5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
