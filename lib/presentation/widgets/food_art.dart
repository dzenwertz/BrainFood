import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ilustración vectorial local para cada receta.
class FoodArt extends StatelessWidget {
  final String recipeId;
  final double size;

  const FoodArt({super.key, required this.recipeId, this.size = 180});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _FoodPainter(recipeId)),
    ),
  );
}

class _FoodPainter extends CustomPainter {
  final String id;
  _FoodPainter(this.id);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Sistema de coordenadas común para escalar la ilustración.
    canvas.scale(size.width / 240, size.height / 240);
    final paint = Paint()..isAntiAlias = true;

    _drawCeramicPlate(canvas, paint);

    // Variación estable para cada receta.
    final key = id.toLowerCase();
    final seed = key.codeUnits.fold<int>(0, (a, b) => a + b);
    final random = math.Random(seed);

    // Tipo visual según el nombre de la receta.
    final isPasta =
        key.contains('pasta') ||
        key.contains('espagueti') ||
        key.contains('macarron') ||
        key.contains('fideos') ||
        key.contains('penne');

    final isRice =
        key.contains('arroz') ||
        key.contains('risotto') ||
        key.contains('chaufa') ||
        key.contains('tacu') ||
        key.contains('quinoa') ||
        key.contains('paella');

    final isSoupOrCream =
        key.contains('crema') ||
        key.contains('sopa') ||
        key.contains('gazpacho') ||
        key.contains('caldo') ||
        key.contains('aguadito') ||
        key.contains('menestron') ||
        key.contains('velout');

    final isLegume =
        key.contains('lenteja') ||
        key.contains('garbanzo') ||
        key.contains('frijol') ||
        key.contains('frejol') ||
        key.contains('alubia') ||
        key.contains('chili') ||
        key.contains('hummus');

    final isSalad =
        key.contains('ensalada') ||
        key.contains('bowl') ||
        key.contains('cesar') ||
        key.contains('caprese') ||
        key.contains('solterito') ||
        key.contains('griega');

    final isToastOrSandwich =
        key.contains('tostada') ||
        key.contains('sandwich') ||
        key.contains('pan') ||
        key.contains('bruschetta');

    final isWrapOrQuesadilla =
        key.contains('wrap') ||
        key.contains('quesadilla') ||
        key.contains('fajita') ||
        key.contains('taco') ||
        key.contains('burrito');

    final isPotatoBase =
        key.contains('papa') ||
        key.contains('patata') ||
        key.contains('batata') ||
        key.contains('pure') ||
        key.contains('causa') ||
        key.contains('bravas');

    if (isPasta) {
      _drawPastaBase(canvas, paint, random);
    } else if (isRice) {
      final isYellow =
          key.contains('curry') ||
          key.contains('paella') ||
          key.contains('aji');
      final isGreen = key.contains('seco') || key.contains('culantro');
      _drawRiceBase(
        canvas,
        paint,
        random,
        isYellow: isYellow,
        isGreen: isGreen,
      );
    } else if (isSoupOrCream) {
      Color soupColor = const Color(0xFFE89A3E);
      if (key.contains('verde') ||
          key.contains('espinaca') ||
          key.contains('calabacin') ||
          key.contains('aguadito') ||
          key.contains('menestron')) {
        soupColor = const Color(0xFF5A8043);
      } else if (key.contains('tomate') ||
          key.contains('gazpacho') ||
          key.contains('criolla')) {
        soupColor = const Color(0xFFC7462C);
      } else if (key.contains('pollo') ||
          key.contains('fideos') ||
          key.contains('caldo')) {
        soupColor = const Color(0xFFE5C158);
      }
      _drawSoupBase(canvas, paint, soupColor);
    } else if (isLegume) {
      _drawLegumesBase(
        canvas,
        paint,
        random,
        isChickpea: key.contains('garbanzo'),
        isBlackBean: key.contains('frijol'),
      );
    } else if (isSalad) {
      _drawSaladBase(canvas, paint, random);
    } else if (isToastOrSandwich) {
      _drawToastBase(canvas, paint);
    } else if (isWrapOrQuesadilla) {
      _drawWrapBase(canvas, paint);
    } else if (isPotatoBase) {
      _drawPotatoBase(canvas, paint, random);
    } else {
      _drawSauteBase(canvas, paint, random);
    }

    final hasSalmon = key.contains('salmon');
    final hasFish =
        key.contains('pescado') ||
        key.contains('merluza') ||
        key.contains('bacalao');
    final hasTuna = key.contains('atun');
    final hasChicken = key.contains('pollo') || key.contains('gallina');
    final hasMeat =
        key.contains('carne') ||
        key.contains('albondiga') ||
        key.contains('lomo') ||
        key.contains('picadillo') ||
        key.contains('hamburguesa') ||
        key.contains('cerdo') ||
        key.contains('bistec');
    final hasEgg =
        key.contains('huevo') ||
        key.contains('tortilla') ||
        key.contains('shakshuka') ||
        key.contains('omelette') ||
        key.contains('revuelto') ||
        key.contains('pericos');
    final hasMushrooms = key.contains('champinon') || key.contains('setas');
    final hasAvocado =
        key.contains('aguacate') ||
        key.contains('guacamole') ||
        key.contains('palta');
    final hasCheese =
        key.contains('queso') ||
        key.contains('parmesano') ||
        key.contains('feta') ||
        key.contains('mozzarella');

    if (hasSalmon) {
      _drawSalmonFillet(canvas, paint);
    } else if (hasFish) {
      _drawWhiteFishFillet(canvas, paint);
    } else if (hasTuna) {
      _drawTunaChunks(canvas, paint, random);
    } else if (hasChicken) {
      _drawChickenCutlets(canvas, paint, random);
    } else if (hasMeat) {
      _drawMeatElements(
        canvas,
        paint,
        random,
        isMeatballs: key.contains('albondiga'),
      );
    }

    if (hasEgg && !isSoupOrCream) {
      _drawFriedEgg(
        canvas,
        paint,
        Offset(
          isToastOrSandwich ? 120 : (115 + (random.nextDouble() - 0.5) * 16),
          isToastOrSandwich ? 116 : (112 + (random.nextDouble() - 0.5) * 14),
        ),
      );
    }

    if (hasMushrooms) {
      _drawMushrooms(canvas, paint, random);
    }

    if (hasAvocado) {
      _drawAvocadoSlices(canvas, paint);
    }

    if (hasCheese && !isPasta) {
      _drawCheeseCubes(canvas, paint, random);
    }

    final hasTomatoes =
        key.contains('tomate') ||
        isSalad ||
        isPasta ||
        isToastOrSandwich ||
        key.contains('bravas');
    if (hasTomatoes && !isSoupOrCream) {
      _drawCherryTomatoes(canvas, paint, random, count: isSalad ? 6 : 4);
    }

    final hasLemon = key.contains('limon') || hasFish || hasSalmon;
    if (hasLemon) {
      _drawLemonWedge(canvas, paint);
    }

    if (key.contains('cebolla') || isSalad) {
      _drawRedOnionRings(canvas, paint, random);
    }

    final leafCount = isSalad ? 12 : (isPasta ? 7 : 5);
    _drawFreshLeaves(canvas, paint, random, count: leafCount);

    _drawFinishingTouches(canvas, paint, random);

    canvas.restore();
  }

  void _drawCeramicPlate(Canvas canvas, Paint paint) {
    final platePath = Path()
      ..addOval(Rect.fromCircle(center: const Offset(122, 120), radius: 102));
    canvas.drawShadow(platePath, const Color(0xFF092820), 14, false);

    canvas.drawCircle(
      const Offset(120, 116),
      101,
      paint..color = const Color(0xFFFCF9EB),
    );
    canvas.drawCircle(
      const Offset(120, 116),
      88,
      paint..color = const Color(0xFFE8E5D5),
    );
    canvas.drawCircle(
      const Offset(120, 115),
      84,
      paint..color = const Color(0xFFF7F3DE),
    );
  }

  void _drawPastaBase(Canvas canvas, Paint paint, math.Random random) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4.8;
    paint.strokeCap = StrokeCap.round;

    for (var i = 0; i < 42; i++) {
      final x = 65 + random.nextDouble() * 102;
      final y = 58 + random.nextDouble() * 108;
      canvas.drawArc(
        Rect.fromLTWH(x, y, 36, 18),
        random.nextDouble() * 3,
        3.7,
        false,
        paint
          ..color = i.isEven
              ? const Color(0xFFECC56D)
              : const Color(0xFFDDA64F),
      );
    }
    paint.style = PaintingStyle.fill;
  }

  void _drawRiceBase(
    Canvas canvas,
    Paint paint,
    math.Random random, {
    bool isYellow = false,
    bool isGreen = false,
  }) {
    final colors = isGreen
        ? [
            const Color(0xFF638645),
            const Color(0xFF557738),
            const Color(0xFF769B55),
          ]
        : isYellow
        ? [
            const Color(0xFFF1C865),
            const Color(0xFFE2B34B),
            const Color(0xFFF7D989),
          ]
        : [
            const Color(0xFFF3EDE2),
            const Color(0xFFE5DDD0),
            const Color(0xFFFAF6EE),
          ];

    for (var i = 0; i < 110; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = math.sqrt(random.nextDouble()) * 65;
      final x = 120 + math.cos(angle) * radius;
      final y = 116 + math.sin(angle) * radius;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 8.5, height: 4.2),
        paint..color = colors[i % colors.length],
      );
      canvas.restore();
    }
  }

  void _drawSoupBase(Canvas canvas, Paint paint, Color soupColor) {
    canvas.drawCircle(const Offset(120, 116), 72, paint..color = soupColor);

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.2;
    paint.strokeCap = StrokeCap.round;
    paint.color = const Color(0xFFFCFBEF).withValues(alpha: 0.85);

    final swirl = Path();
    swirl.moveTo(95, 108);
    swirl.cubicTo(105, 90, 138, 92, 142, 114);
    swirl.cubicTo(145, 132, 126, 140, 112, 134);
    swirl.cubicTo(104, 128, 108, 118, 118, 116);
    canvas.drawPath(swirl, paint);
    paint.style = PaintingStyle.fill;
  }

  void _drawLegumesBase(
    Canvas canvas,
    Paint paint,
    math.Random random, {
    bool isChickpea = false,
    bool isBlackBean = false,
  }) {
    final colors = isBlackBean
        ? [
            const Color(0xFF2C2422),
            const Color(0xFF3F3532),
            const Color(0xFF1D1716),
          ]
        : isChickpea
        ? [
            const Color(0xFFE2C48E),
            const Color(0xFFD3B177),
            const Color(0xFFECCFA0),
          ]
        : [
            const Color(0xFF8B653A),
            const Color(0xFFA87F4D),
            const Color(0xFFBF9B68),
          ];

    final count = isChickpea ? 85 : 140;
    final size = isChickpea ? 10.0 : 8.0;

    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = math.sqrt(random.nextDouble()) * 66;
      final x = 120 + math.cos(angle) * radius;
      final y = 116 + math.sin(angle) * radius;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: size,
          height: isChickpea ? size : size * 0.65,
        ),
        paint..color = colors[i % colors.length],
      );
    }
  }

  void _drawSaladBase(Canvas canvas, Paint paint, math.Random random) {
    final greens = [
      const Color(0xFF427A4B),
      const Color(0xFF5E9C57),
      const Color(0xFF7CB866),
      const Color(0xFF33603A),
    ];

    for (var i = 0; i < 35; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = math.sqrt(random.nextDouble()) * 62;
      final x = 120 + math.cos(angle) * radius;
      final y = 116 + math.sin(angle) * radius;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi * 2);

      final leaf = Path()
        ..moveTo(-18, 0)
        ..quadraticBezierTo(0, -20, 18, 0)
        ..quadraticBezierTo(0, 18, -18, 0);

      canvas.drawPath(leaf, paint..color = greens[i % greens.length]);
      canvas.restore();
    }
  }

  void _drawToastBase(Canvas canvas, Paint paint) {
    final breadRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(76, 74, 88, 84),
      const Radius.circular(16),
    );
    canvas.drawRRect(breadRect, paint..color = const Color(0xFF8F5829));

    final innerBread = RRect.fromRectAndRadius(
      const Rect.fromLTWH(81, 79, 78, 74),
      const Radius.circular(12),
    );
    canvas.drawRRect(innerBread, paint..color = const Color(0xFFE8C38B));
  }

  void _drawWrapBase(Canvas canvas, Paint paint) {
    final wrapPath = Path()
      ..moveTo(70, 130)
      ..lineTo(140, 68)
      ..arcToPoint(const Offset(165, 95), radius: const Radius.circular(30))
      ..lineTo(105, 155)
      ..close();

    canvas.drawPath(wrapPath, paint..color = const Color(0xFFECD7A8));

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.5;
    paint.color = const Color(0xFFBD8E52);
    canvas.drawLine(const Offset(95, 110), const Offset(130, 80), paint);
    canvas.drawLine(const Offset(105, 130), const Offset(145, 95), paint);
    paint.style = PaintingStyle.fill;
  }

  void _drawPotatoBase(Canvas canvas, Paint paint, math.Random random) {
    final potatoColors = [
      const Color(0xFFDCA952),
      const Color(0xFFE8BD6D),
      const Color(0xFFCA943C),
    ];

    for (var i = 0; i < 22; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = math.sqrt(random.nextDouble()) * 58;
      final x = 120 + math.cos(angle) * radius;
      final y = 116 + math.sin(angle) * radius;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -7, 20, 14),
          const Radius.circular(4),
        ),
        paint..color = potatoColors[i % potatoColors.length],
      );
      canvas.restore();
    }
  }

  void _drawSauteBase(Canvas canvas, Paint paint, math.Random random) {
    for (var i = 0; i < 45; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final radius = math.sqrt(random.nextDouble()) * 60;
      final x = 120 + math.cos(angle) * radius;
      final y = 116 + math.sin(angle) * radius;

      canvas.drawCircle(
        Offset(x, y),
        6.5,
        paint
          ..color = i.isEven
              ? const Color(0xFFE5B55E)
              : const Color(0xFFD19B44),
      );
    }
  }

  void _drawSalmonFillet(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.translate(120, 116);
    canvas.rotate(-0.25);

    final fillet = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-36, -22, 72, 44),
      const Radius.circular(10),
    );
    canvas.drawRRect(fillet, paint..color = const Color(0xFFF17C64));

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.2;
    paint.color = const Color(0xFFF9B8A8);
    for (var j = -24; j <= 24; j += 12) {
      canvas.drawLine(
        Offset(j.toDouble(), -18),
        Offset((j + 6).toDouble(), 18),
        paint,
      );
    }

    paint.color = const Color(0xFFB54D38);
    canvas.drawLine(
      const Offset(-32, -19),
      const Offset(32, -19),
      paint..strokeWidth = 3,
    );

    canvas.restore();
    paint.style = PaintingStyle.fill;
  }

  void _drawWhiteFishFillet(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.translate(120, 116);
    canvas.rotate(0.2);

    final fillet = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-34, -20, 68, 40),
      const Radius.circular(12),
    );
    canvas.drawRRect(fillet, paint..color = const Color(0xFFF7F1E5));

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.0;
    paint.color = const Color(0xFFD0A96B);
    canvas.drawLine(const Offset(-22, -8), const Offset(22, -8), paint);
    canvas.drawLine(const Offset(-20, 6), const Offset(20, 6), paint);

    canvas.restore();
    paint.style = PaintingStyle.fill;
  }

  void _drawTunaChunks(Canvas canvas, Paint paint, math.Random random) {
    for (var i = 0; i < 7; i++) {
      final x = 90 + random.nextDouble() * 60;
      final y = 88 + random.nextDouble() * 56;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -8, 24, 16),
          const Radius.circular(5),
        ),
        paint..color = const Color(0xFFD5745B),
      );
      canvas.restore();
    }
  }

  void _drawChickenCutlets(Canvas canvas, Paint paint, math.Random random) {
    for (var i = 0; i < 5; i++) {
      final x = 80 + random.nextDouble() * 75;
      final y = 75 + random.nextDouble() * 75;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i * 0.7);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-16, -11, 32, 22),
          const Radius.circular(7),
        ),
        paint..color = const Color(0xFFD99F55),
      );

      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = const Color(0xFF915F2E);
      for (var j = 0; j < 3; j++) {
        canvas.drawLine(
          Offset(-8 + j * 8.0, -7),
          Offset(-4 + j * 8.0, 7),
          paint,
        );
      }
      canvas.restore();
      paint.style = PaintingStyle.fill;
    }
  }

  void _drawMeatElements(
    Canvas canvas,
    Paint paint,
    math.Random random, {
    bool isMeatballs = false,
  }) {
    final count = isMeatballs ? 4 : 6;
    for (var i = 0; i < count; i++) {
      final x = 86 + random.nextDouble() * 68;
      final y = 82 + random.nextDouble() * 68;

      if (isMeatballs) {
        canvas.drawCircle(
          Offset(x, y),
          14,
          paint..color = const Color(0xFF783E28),
        );
        canvas.drawCircle(
          Offset(x - 3, y - 3),
          11,
          paint..color = const Color(0xFF8F4D33),
        );
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(random.nextDouble() * math.pi);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-15, -9, 30, 18),
            const Radius.circular(6),
          ),
          paint..color = const Color(0xFF703D2A),
        );
        canvas.restore();
      }
    }
  }

  void _drawFriedEgg(Canvas canvas, Paint paint, Offset center) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 78, height: 68),
      paint..color = const Color(0xFFFFFEF3),
    );

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.2;
    paint.color = const Color(0xFFE5CA92);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 78, height: 68),
      paint,
    );
    paint.style = PaintingStyle.fill;

    final yolkCenter = center.translate(1, -2);
    canvas.drawCircle(yolkCenter, 20, paint..color = const Color(0xFFF1B736));

    canvas.drawCircle(
      yolkCenter.translate(-5, -5),
      6.5,
      paint..color = const Color(0xFFFFDF7D),
    );
  }

  void _drawMushrooms(Canvas canvas, Paint paint, math.Random random) {
    for (var i = 0; i < 4; i++) {
      final x = 75 + random.nextDouble() * 88;
      final y = 72 + random.nextDouble() * 88;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi);

      canvas.drawArc(
        const Rect.fromLTWH(-12, -10, 24, 18),
        math.pi,
        math.pi,
        true,
        paint..color = const Color(0xFFC0A486),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-4, 0, 8, 8),
        paint..color = const Color(0xFFDFCDBD),
      );

      canvas.restore();
    }
  }

  void _drawAvocadoSlices(Canvas canvas, Paint paint) {
    for (var i = 0; i < 3; i++) {
      final angle = 0.5 + i * 0.35;
      final x = 110 + math.cos(angle) * 35;
      final y = 110 + math.sin(angle) * 35;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final skinPath = Path()
        ..moveTo(-16, 0)
        ..quadraticBezierTo(0, -14, 16, 0)
        ..quadraticBezierTo(0, 14, -16, 0);
      canvas.drawPath(skinPath, paint..color = const Color(0xFF2E5336));

      final fleshPath = Path()
        ..moveTo(-14, 0)
        ..quadraticBezierTo(0, -10, 14, 0)
        ..quadraticBezierTo(0, 10, -14, 0);
      canvas.drawPath(fleshPath, paint..color = const Color(0xFFBCD584));

      canvas.restore();
    }
  }

  void _drawCheeseCubes(Canvas canvas, Paint paint, math.Random random) {
    for (var i = 0; i < 6; i++) {
      final x = 85 + random.nextDouble() * 70;
      final y = 80 + random.nextDouble() * 70;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 10, height: 10),
          const Radius.circular(2),
        ),
        paint..color = const Color(0xFFF9F6EA),
      );
    }
  }

  void _drawCherryTomatoes(
    Canvas canvas,
    Paint paint,
    math.Random random, {
    int count = 4,
  }) {
    for (var i = 0; i < count; i++) {
      final x = 75 + random.nextDouble() * 88;
      final y = 72 + random.nextDouble() * 88;

      canvas.drawCircle(
        Offset(x, y),
        10,
        paint..color = const Color(0xFFCB4D37),
      );
      canvas.drawCircle(
        Offset(x - 1.5, y - 1.5),
        7,
        paint..color = const Color(0xFFE96D55),
      );
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.8;
      paint.color = const Color(0xFFFFD2AC);
      canvas.drawLine(Offset(x - 3, y - 2), Offset(x + 2, y + 3), paint);
      paint.style = PaintingStyle.fill;
    }
  }

  void _drawLemonWedge(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.translate(162, 145);
    canvas.rotate(0.4);

    canvas.drawArc(
      const Rect.fromLTWH(-16, -16, 32, 32),
      0,
      math.pi / 2,
      true,
      paint..color = const Color(0xFFECC436),
    );

    canvas.drawArc(
      const Rect.fromLTWH(-13, -13, 26, 26),
      0.05,
      (math.pi / 2) - 0.1,
      true,
      paint..color = const Color(0xFFF9E878),
    );

    canvas.restore();
  }

  void _drawRedOnionRings(Canvas canvas, Paint paint, math.Random random) {
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2.4;
    paint.strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final x = 80 + random.nextDouble() * 75;
      final y = 75 + random.nextDouble() * 75;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(x, y),
          radius: 14 + random.nextDouble() * 6,
        ),
        random.nextDouble() * math.pi,
        1.8,
        false,
        paint..color = const Color(0xFF9E3D67),
      );
    }
    paint.style = PaintingStyle.fill;
  }

  void _drawFreshLeaves(
    Canvas canvas,
    Paint paint,
    math.Random random, {
    int count = 7,
  }) {
    for (var i = 0; i < count; i++) {
      final angle =
          i * (math.pi * 2 / count) + (random.nextDouble() - 0.5) * 0.4;
      final radius = 35 + random.nextDouble() * 32;
      final x = 120 + math.cos(angle) * radius;
      final y = 116 + math.sin(angle) * radius;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final leaf = Path()
        ..moveTo(-16, 0)
        ..quadraticBezierTo(0, -18, 18, 0)
        ..quadraticBezierTo(0, 16, -16, 0);

      canvas.drawPath(
        leaf,
        paint
          ..color = i.isEven
              ? const Color(0xFF386142)
              : const Color(0xFF5E8B4E),
      );

      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.0;
      paint.color = const Color(0xFFB5C87E);
      canvas.drawLine(const Offset(-11, 0), const Offset(12, 0), paint);
      paint.style = PaintingStyle.fill;

      canvas.restore();
    }
  }

  void _drawFinishingTouches(Canvas canvas, Paint paint, math.Random random) {
    for (var i = 0; i < 28; i++) {
      final x = 70 + random.nextDouble() * 100;
      final y = 68 + random.nextDouble() * 100;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 3.2, height: 1.8),
        paint..color = const Color(0xFF2E5336),
      );
    }

    for (var i = 0; i < 18; i++) {
      final x = 75 + random.nextDouble() * 90;
      final y = 72 + random.nextDouble() * 90;
      canvas.drawCircle(
        Offset(x, y),
        0.9,
        paint..color = const Color(0xFF221F1F),
      );
    }
  }

  @override
  bool shouldRepaint(_FoodPainter oldDelegate) => oldDelegate.id != id;
}
