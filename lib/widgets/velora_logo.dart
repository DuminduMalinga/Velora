import 'package:flutter/material.dart';

/// Vector brand mark. Works at app-bar size or as a large splash/app-icon motif.
class VeloraLogo extends StatelessWidget {
  const VeloraLogo({
    super.key,
    this.size = 64,
    this.glow = true,
    this.onLight = false,
    this.semanticLabel = 'Velora logo',
  });
  final double size;
  final bool glow;
  final bool onLight;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: VeloraLogoPainter(glow: glow, onLight: onLight),
        ),
      ),
    ),
  );
}

class VeloraLogoPainter extends CustomPainter {
  const VeloraLogoPainter({this.glow = true, this.onLight = false});
  final bool glow;
  final bool onLight;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    const blue = Color(0xFF3B82F6);
    final white = onLight ? const Color(0xFF111B35) : const Color(0xFFF8FAFC);
    // The curved bag handle and tapered ribbon form one geometric V silhouette.
    final ribbon = Path()
      ..moveTo(13, 28)
      ..quadraticBezierTo(29, 27, 36, 42)
      ..lineTo(53, 72)
      ..lineTo(75, 30)
      ..lineTo(89, 28)
      ..lineTo(60, 83)
      ..quadraticBezierTo(53, 95, 45, 83)
      ..close();
    if (glow) {
      canvas.drawPath(
        ribbon,
        Paint()
          ..color = blue.withValues(alpha: .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = LinearGradient(
          colors: [white, const Color(0xFF98C5FF), blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(10, 20, 80, 70)),
    );
    final handle = Path()
      ..moveTo(32, 29)
      ..cubicTo(34, 7, 64, 7, 67, 29);
    canvas.drawPath(
      handle,
      Paint()
        ..color = white.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, 34)
        ..lineTo(51, 81),
      Paint()
        ..color = white.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
    final star = Path()
      ..moveTo(83, 6)
      ..quadraticBezierTo(85, 16, 94, 18)
      ..quadraticBezierTo(85, 20, 83, 30)
      ..quadraticBezierTo(81, 20, 72, 18)
      ..quadraticBezierTo(81, 16, 83, 6)
      ..close();
    canvas.drawPath(star, Paint()..color = blue);
    canvas.drawCircle(
      const Offset(83, 18),
      2,
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(VeloraLogoPainter oldDelegate) =>
      glow != oldDelegate.glow || onLight != oldDelegate.onLight;
}
