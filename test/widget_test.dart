import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brain_food/main.dart';
import 'package:brain_food/data/models/ingredient_item.dart';
import 'package:brain_food/presentation/widgets/recipe_card.dart';

final captureKey = GlobalKey();
Future<void> launch(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
  bool seeded = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  SharedPreferences.setMockInitialValues(
    seeded
        ? {
            'brainfood_pantry_items': jsonEncode([
              IngredientItem(
                id: 't',
                name: 'Tomate',
                category: IngredientCategory.vegetables,
                quantityDisplay: '3 unidades',
                isExpiringSoon: true,
              ).toJson(),
              IngredientItem(
                id: 'e',
                name: 'Huevos',
                category: IngredientCategory.dairy,
                quantityDisplay: '6 unidades',
              ).toJson(),
              IngredientItem(
                id: 's',
                name: 'Espinaca',
                category: IngredientCategory.vegetables,
                quantityDisplay: '1 atado',
              ).toJson(),
            ]),
            'brainfood_staples_active': true,
          }
        : {},
  );
  await tester.runAsync(() async {
    final loader = FontLoader('BrainSans')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: const ProviderScope(child: BrainFoodApp()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.runAsync(() async {
    final boundary =
        captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('design_review')..createSync(recursive: true);
    File('${directory.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'First launch and all navigation destinations render without overflow',
    (tester) async {
      await launch(tester, width: 360);
      expect(find.text('brainfood'), findsOneWidget);
      await capture(tester, '01-home-empty');
      for (final name in ['Despensa', 'Recetas', 'Semana', 'Compras', 'Hoy']) {
        await tab(tester, name);
        expect(tester.takeException(), isNull, reason: name);
      }
    },
  );
  testWidgets(
    'Realistic pantry renders home and every screen, details and preferences',
    (tester) async {
      await launch(tester, seeded: true);
      await capture(tester, '02-home');
      for (final name in ['Despensa', 'Recetas', 'Semana', 'Compras']) {
        await tab(tester, name);
        expect(tester.takeException(), isNull, reason: name);
        await capture(tester, '03-$name');
      }
      await tab(tester, 'Recetas');
      await tester.tap(find.byType(RecipeCardWidget).first);
      await tester.pumpAndSettle();
      expect(find.text('Abrir modo cocina'), findsOneWidget);
      await capture(tester, '04-detail');
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Preferencias'));
      await tester.pumpAndSettle();
      expect(find.text('Tu cocina.\nTus reglas.'), findsOneWidget);
      await capture(tester, '05-preferences');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Large text keeps all five destinations usable on a narrow phone',
    (tester) async {
      await launch(tester, width: 360, scale: 1.5, seeded: true);
      for (final name in ['Hoy', 'Despensa', 'Recetas', 'Semana', 'Compras']) {
        await tab(tester, name);
        expect(tester.takeException(), isNull, reason: name);
      }
      await tester.tap(find.byTooltip('Preferencias'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'User can add an ingredient through the editor and gets a live pantry',
    (tester) async {
      await launch(tester);
      await tab(tester, 'Despensa');
      await tester.tap(find.text('Añadir alimento').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomate').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar alimento'));
      await tester.tap(find.text('Guardar alimento'));
      await tester.pumpAndSettle();
      expect(find.text('Tomate'), findsOneWidget);
      expect(find.text('2 unidades'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Shopping flow moves a checked purchase into the pantry', (
    tester,
  ) async {
    await launch(tester);
    await tab(tester, 'Compras');
    await tester.tap(find.text('Añadir producto'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Producto'),
      'Tomate',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad'),
      '4 unidades',
    );
    await tester.tap(find.text('Añadir a mi lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Compartir lista'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir por WhatsApp…'), findsOneWidget);
    await tester.tap(find.text('Copiar pendientes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).hitTestable().first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar comprados en despensa'));
    await tester.tap(find.text('Guardar comprados en despensa'));
    await tester.pumpAndSettle();
    await tab(tester, 'Despensa');
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('4 unidades'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Cooking mode restores the current step after leaving', (
    tester,
  ) async {
    await launch(tester, seeded: true);
    await tab(tester, 'Recetas');
    await tester.tap(find.byType(RecipeCardWidget).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir modo cocina'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 de '), findsOneWidget);
    await capture(tester, '08-cooking-mode');
    await tester.tap(find.text('Listo, siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 de '), findsOneWidget);
    await tester.tap(find.byTooltip('Salir del modo cocina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir modo cocina'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 de '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('A starter pack fills an empty pantry without manual entry', (
    tester,
  ) async {
    await launch(tester);
    await tab(tester, 'Despensa');
    await tester.tap(find.text('Empezar con una despensa rápida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Básicos peruanos'));
    await tester.pumpAndSettle();
    expect(find.text('Añadir 10 alimentos'), findsOneWidget);
    await capture(tester, '09-pantry-pack');
    await tester.ensureVisible(find.text('Añadir 10 alimentos'));
    await tester.tap(find.text('Añadir 10 alimentos'));
    await tester.pumpAndSettle();
    expect(find.text('10 alimentos'), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Finishing a recipe without marking depleted foods preserves all stock',
    (tester) async {
      await launch(tester, seeded: true);
      await tab(tester, 'Recetas');
      await tester.tap(find.byType(RecipeCardWidget).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir modo cocina'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 20; i++) {
        if (find.text('Terminé de cocinar').evaluate().isNotEmpty) break;
        await tester.tap(find.text('Listo, siguiente'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Terminé de cocinar'));
      await tester.pumpAndSettle();
      await capture(tester, '06-finish-cooking');
      await tester.ensureVisible(find.text('Listo, a disfrutar'));
      await tester.tap(find.text('Listo, a disfrutar'));
      await tester.pumpAndSettle();
      await tab(tester, 'Despensa');
      expect(find.text('3 alimentos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Full pages scroll safely with large text and the assistant can open',
    (tester) async {
      await launch(tester, width: 360, scale: 1.5, seeded: true);
      for (final label in ['Hoy', 'Despensa', 'Recetas', 'Semana', 'Compras']) {
        await tab(tester, label);
        for (var i = 0; i < 5; i++) {
          await tester.drag(
            find.byType(ListView).hitTestable().first,
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
        }
      }
      await tab(tester, 'Hoy');
      await tester.tap(find.text('¿Tienes algo en mente?'));
      await tester.pumpAndSettle();
      expect(find.text('Asistente de cocina'), findsOneWidget);
      await capture(tester, '07-assistant');
      expect(tester.takeException(), isNull);
    },
  );
}
