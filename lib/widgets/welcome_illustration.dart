import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'velora_logo.dart';

/// Abstract brand artwork, deliberately independent of products and API data.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({
    super.key,
    required this.motion,
    required this.dark,
  });
  final Animation<double> motion;
  final bool dark;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _ShoppingPainter(motion: motion, dark: dark),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _ShoppingPainter extends CustomPainter {
  _ShoppingPainter({required this.motion, required this.dark})
    : super(repaint: motion);
  final Animation<double> motion;
  final bool dark;
  static const blue = Color(0xFF3B82F6);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 420, size.height / 380);
    canvas.save();
    canvas.translate(
      (size.width - 420 * scale) / 2,
      (size.height - 380 * scale) / 2,
    );
    canvas.scale(scale);
    final wave = math.sin(motion.value * math.pi * 2);
    final faint = dark ? const Color(0xFF405980) : const Color(0xFF9EB6DB);
    canvas.drawCircle(
      const Offset(211, 185),
      146,
      Paint()
        ..shader = RadialGradient(
          colors: [blue.withValues(alpha: .2), blue.withValues(alpha: 0)],
        ).createShader(const Rect.fromLTWH(65, 39, 292, 292)),
    );
    canvas.save();
    canvas.translate(210, 195);
    canvas.rotate(-.35);
    canvas.drawOval(
      const Rect.fromLTWH(-190, -80, 380, 160),
      Paint()
        ..color = faint.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    canvas.restore();
    canvas.drawCircle(
      const Offset(210, 185),
      148,
      Paint()
        ..color = faint.withValues(alpha: .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
    // Soft ground shadow, detached from the floating bag.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(216, 328),
        width: 190 - wave * 10,
        height: 15,
      ),
      Paint()
        ..color = blue.withValues(alpha: dark ? .25 : .15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    _satellite(canvas, Offset(79, 143 - wave * 5), -.22, dark);
    _satellite(canvas, Offset(335, 240 + wave * 6), .2, dark);
    canvas.save();
    canvas.translate(0, wave * 7);
    final bag = Path()
      ..moveTo(139, 127)
      ..lineTo(279, 117)
      ..lineTo(302, 285)
      ..quadraticBezierTo(302, 296, 290, 298)
      ..lineTo(136, 306)
      ..quadraticBezierTo(123, 306, 125, 293)
      ..close();
    canvas.drawShadow(
      bag,
      const Color(0xFF030B20).withValues(alpha: dark ? .7 : .25),
      18,
      false,
    );
    canvas.drawPath(
      bag,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A9CFF), Color(0xFF2363DF), Color(0xFF153A8C)],
        ).createShader(const Rect.fromLTWH(125, 117, 177, 189)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(279, 117)
        ..lineTo(305, 134)
        ..lineTo(323, 283)
        ..lineTo(302, 296)
        ..lineTo(292, 211)
        ..close(),
      Paint()..color = const Color(0xFF102D68),
    );
    canvas.drawPath(
      Path()
        ..moveTo(139, 127)
        ..lineTo(162, 144)
        ..lineTo(305, 134)
        ..lineTo(279, 117)
        ..close(),
      Paint()..color = const Color(0xFF8DBBFF),
    );
    final handle = Path()
      ..moveTo(174, 151)
      ..cubicTo(161, 54, 252, 53, 252, 145);
    canvas.drawPath(
      handle,
      Paint()
        ..color = const Color(0xFF102E67)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      handle,
      Paint()
        ..color = const Color(0xFFD6E8FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    for (final point in [const Offset(174, 151), const Offset(252, 145)]) {
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFFB6D6FF));
    }
    canvas.save();
    canvas.translate(177, 182);
    const VeloraLogoPainter(glow: false).paint(canvas, const Size(77, 77));
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(139, 134)
        ..lineTo(129, 291),
      Paint()
        ..color = Colors.white.withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
    _sparkle(canvas, Offset(318, 80 + wave * 4), 13);
    _sparkle(canvas, const Offset(104, 278), 7);
    canvas.drawCircle(const Offset(62, 220), 3, Paint()..color = blue);
    canvas.drawCircle(const Offset(286, 43), 2, Paint()..color = faint);
    canvas.drawCircle(const Offset(358, 159), 3, Paint()..color = faint);
    canvas.restore();
  }

  void _satellite(Canvas canvas, Offset center, double angle, bool dark) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-31, -35, 62, 70),
      const Radius.circular(14),
    );
    canvas.drawShadow(
      Path()..addRRect(rect),
      const Color(0xFF07152E),
      8,
      false,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF283E63), const Color(0xFF132340)]
              : [Colors.white, const Color(0xFFE0EAFC)],
        ).createShader(rect.outerRect),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = blue.withValues(alpha: .3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final handle = Path()
      ..moveTo(-12, -12)
      ..cubicTo(-13, -47, 13, -47, 12, -12);
    canvas.drawPath(
      handle,
      Paint()
        ..color = const Color(0xFF7EADFA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(-9, 7),
      const Offset(0, 18),
      Paint()
        ..color = const Color(0xFF82B2FF)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(0, 18),
      const Offset(12, -1),
      Paint()
        ..color = const Color(0xFF82B2FF)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _sparkle(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(
        center.dx + 2,
        center.dy - 2,
        center.dx + radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + 2,
        center.dy + 2,
        center.dx,
        center.dy + radius,
      )
      ..quadraticBezierTo(
        center.dx - 2,
        center.dy + 2,
        center.dx - radius,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - 2,
        center.dy - 2,
        center.dx,
        center.dy - radius,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF82B2FF));
  }

  @override
  bool shouldRepaint(_ShoppingPainter oldDelegate) =>
      dark != oldDelegate.dark || motion != oldDelegate.motion;
}
