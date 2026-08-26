import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Eduly Özel Vektörel Logo ve Amblem Widget'ı
class EdulyLogo extends StatelessWidget {
  const EdulyLogo({
    super.key,
    this.size = 80,
    this.useImageAsset = true,
  });

  final double size;
  final bool useImageAsset;

  @override
  Widget build(BuildContext context) {
    if (useImageAsset) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/eduly_logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return CustomPaint(
                size: Size(size, size),
                painter: _EdulyCompassPainter(),
              );
            },
          ),
        ),
      );
    }

    return CustomPaint(
      size: Size(size, size),
      painter: _EdulyCompassPainter(),
    );
  }
}

/// Eduly Vektörel Pusula Çizici (Kırmızı İğneli Geometrik Pusula)
class _EdulyCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Dış İndigo / Koyu Mavi Çerçeve
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1B4B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Gümüş / Beyaz İnce İç Çember
    final ringPaint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;
    canvas.drawCircle(center, radius * 0.82, ringPaint);

    // 3. Yıldız N noktaları (Yörünge İşaretleri)
    final starPaint = Paint()
      ..color = Colors.white.withAlpha(180)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 4; i++) {
      double angle = i * math.pi / 2;
      double px = center.dx + math.cos(angle) * (radius * 0.82);
      double py = center.dy + math.sin(angle) * (radius * 0.82);
      canvas.drawCircle(Offset(px, py), radius * 0.04, starPaint);
    }

    // 4. Kırmızı İğne (Kuzey-Doğu Yönü: -45 Derece)
    final redNeedlePath = Path();
    const angle = -math.pi / 4; // -45 derece (Sağ Üst)
    final needleLength = radius * 0.70;
    final needleWidth = radius * 0.18;

    double tipX = center.dx + math.cos(angle) * needleLength;
    double tipY = center.dy + math.sin(angle) * needleLength;

    double perpAngle = angle + math.pi / 2;
    double baseLeftX = center.dx + math.cos(perpAngle) * (needleWidth / 2);
    double baseLeftY = center.dy + math.sin(perpAngle) * (needleWidth / 2);
    double baseRightX = center.dx - math.cos(perpAngle) * (needleWidth / 2);
    double baseRightY = center.dy - math.sin(perpAngle) * (needleWidth / 2);

    redNeedlePath.moveTo(tipX, tipY);
    redNeedlePath.lineTo(baseLeftX, baseLeftY);
    redNeedlePath.lineTo(baseRightX, baseRightY);
    redNeedlePath.close();

    final redPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawPath(redNeedlePath, redPaint);

    // 5. Mavi/Gümüş Alt İğne (Güney-Batı Yönü)
    final blueNeedlePath = Path();
    const oppositeAngle = angle + math.pi;
    double oppTipX = center.dx + math.cos(oppositeAngle) * needleLength;
    double oppTipY = center.dy + math.sin(oppositeAngle) * needleLength;

    blueNeedlePath.moveTo(oppTipX, oppTipY);
    blueNeedlePath.lineTo(baseLeftX, baseLeftY);
    blueNeedlePath.lineTo(baseRightX, baseRightY);
    blueNeedlePath.close();

    final bluePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(blueNeedlePath, bluePaint);

    // 6. Merkez Göbek (Altın Sarı Düğme)
    final centerPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.12, centerPaint);

    final innerCenterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.05, innerCenterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
