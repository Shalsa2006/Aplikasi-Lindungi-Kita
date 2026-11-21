import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Logo LindungiKita: perisai bergradasi dengan hati di tengah, digambar dengan kode (tanpa file gambar).
class LogoMark extends StatelessWidget {
  final double size;
  final bool onDark; // true = perisai putih (di atas latar gradasi)
  const LogoMark({super.key, this.size = 80, this.onDark = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size * 1.08), painter: _LogoPainter(onDark));
}

class _LogoPainter extends CustomPainter {
  final bool onDark;
  _LogoPainter(this.onDark);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final shield = Path()
      ..moveTo(w * .5, h * .03)
      ..cubicTo(w * .62, h * .13, w * .80, h * .17, w * .93, h * .17)
      ..lineTo(w * .93, h * .50)
      ..cubicTo(w * .93, h * .76, w * .72, h * .91, w * .5, h * .99)
      ..cubicTo(w * .28, h * .91, w * .07, h * .76, w * .07, h * .50)
      ..lineTo(w * .07, h * .17)
      ..cubicTo(w * .20, h * .17, w * .38, h * .13, w * .5, h * .03)
      ..close();

    canvas.drawShadow(shield, C.purple.withAlpha(120), 6, false);
    final paint = Paint();
    if (onDark) {
      paint.color = Colors.white;
    } else {
      paint.shader = gMain.createShader(Rect.fromLTWH(0, 0, w, h));
    }
    canvas.drawPath(shield, paint);

    // hati
    final cx = w * .5, cy = h * .50, k = w * .19;
    final heart = Path()
      ..moveTo(cx, cy + k * 1.05)
      ..cubicTo(cx - k * 2.1, cy - k * .15, cx - k * 1.0, cy - k * 1.7, cx, cy - k * .5)
      ..cubicTo(cx + k * 1.0, cy - k * 1.7, cx + k * 2.1, cy - k * .15, cx, cy + k * 1.05)
      ..close();
    final hp = Paint();
    if (onDark) {
      hp.shader = gMain.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      hp.color = Colors.white;
    }
    canvas.drawPath(heart, hp);

    // dua "tangan" melindungi: busur kecil di bawah hati
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .035
      ..strokeCap = StrokeCap.round
      ..color = onDark ? C.pink : Colors.white.withAlpha(200);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, cy + k * .55), width: k * 3.6, height: k * 3.0), .35, 2.45, false, arc);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.onDark != onDark;
}

class LogoFull extends StatelessWidget {
  final double size;
  final bool onDark;
  final bool vertical;
  const LogoFull({super.key, this.size = 56, this.onDark = false, this.vertical = false});

  @override
  Widget build(BuildContext context) {
    final col = onDark ? Colors.white : C.ink;
    final text = Column(
      crossAxisAlignment: vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'Lindungi', style: TextStyle(color: col, fontWeight: FontWeight.w900)),
          TextSpan(text: 'Kita', style: TextStyle(color: onDark ? C.yellow : C.pink, fontWeight: FontWeight.w900)),
        ]), style: TextStyle(fontSize: size * .5, letterSpacing: -.5)),
        Text('Aman bersuara, aman terlindungi',
            style: TextStyle(color: col.withAlpha(190), fontSize: size * .2, fontWeight: FontWeight.w500)),
      ],
    );
    final mark = LogoMark(size: size, onDark: onDark);
    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: [mark, SizedBox(height: size * .2), text])
        : Row(mainAxisSize: MainAxisSize.min, children: [mark, SizedBox(width: size * .25), text]);
  }
}
