import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pantry/core/pantry/pantry_provider.dart';
import 'package:home_pantry/core/pantry/pantry_storage.dart';
import 'package:home_pantry/features/pantry/pantry_screens.dart';
import 'package:provider/provider.dart';

void main() {
  late _MemoryPantryStorage storage;
  late PantryProvider pantry;

  setUp(() async {
    storage = _MemoryPantryStorage();
    pantry = PantryProvider(storage: storage);
    await pantry.initialized;
  });

  tearDown(() {
    pantry.dispose();
  });

  test('search and stock filters use the demo inventory', () {
    expect(pantry.filteredItems(query: 'молоко').map((item) => item.name), [
      'Молоко 2.5%',
    ]);
    expect(
      pantry
          .filteredItems(filter: StockFilter.lowStock)
          .map((item) => item.name)
          .toSet(),
      containsAll(['Молоко 2.5%', 'Вода питна']),
    );
    expect(
      pantry
          .filteredItems(filter: StockFilter.expired)
          .map((item) => item.name),
      ['Йогурт натуральний'],
    );
  });

  test(
    'pantry edits and stock deletion persist across provider instances',
    () async {
      await pantry.savePantry(
        id: 'main-pantry',
        name: 'Кухонна комора',
        description: 'Оновлений опис',
      );
      await pantry.deleteItem('rice');

      final restored = PantryProvider(storage: storage);
      await restored.initialized;
      addTearDown(restored.dispose);

      expect(restored.pantryById('main-pantry').name, 'Кухонна комора');
      expect(restored.items.any((item) => item.id == 'rice'), isFalse);
    },
  );

  testWidgets('stock list applies search to visible inventory', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PantryProvider>.value(
        value: pantry,
        child: const MaterialApp(
          home: Scaffold(
            body: PantrySectionScreen(
              sectionKey: 'all-stock',
              onOpenSection: _ignoreSection,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Рис жасмин'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Молоко');
    await tester.pumpAndSettle();

    expect(find.text('Молоко 2.5%'), findsOneWidget);
    expect(find.text('Рис жасмин'), findsNothing);
  });

  testWidgets('all main sections and stock details render on desktop', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final (sectionKey, pantryId) in [
      ('home', null),
      ('pantries', null),
      ('all-stock', null),
      ('pantry:main-pantry', 'main-pantry'),
      ('categories', null),
      ('reminders', null),
    ]) {
      await tester.pumpWidget(
        ChangeNotifierProvider<PantryProvider>.value(
          value: pantry,
          child: MaterialApp(
            home: Scaffold(
              body: PantrySectionScreen(
                sectionKey: sectionKey,
                pantryId: pantryId,
                onOpenSection: _ignoreSection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: sectionKey);
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<PantryProvider>.value(
        value: pantry,
        child: const MaterialApp(
          home: Scaffold(
            body: PantrySectionScreen(
              sectionKey: 'all-stock',
              onOpenSection: _ignoreSection,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Переглянути').first);
    await tester.pumpAndSettle();
    expect(find.text('ПОТОЧНА КІЛЬКІСТЬ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _ignoreSection(String _) {}

class _MemoryPantryStorage extends PantryStorage {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async {
    _value = value;
  }
}
