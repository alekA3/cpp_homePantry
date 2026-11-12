import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'pantry_models.dart';
import 'pantry_storage.dart';

enum StockFilter { all, expiring, expired, lowStock }

enum StockSort { name, expiration, quantity }

class PantryProvider extends ChangeNotifier {
  PantryProvider({PantryStorage? storage})
    : _storage = storage ?? PantryStorage() {
    initialized = _initialize();
  }

  final PantryStorage _storage;
  late final Future<void> initialized;
  late List<Pantry> _pantries = _createDemoPantries();
  late List<PantryCategory> _categories = _createDemoCategories();
  late List<StockItem> _items = _createDemoItems(_pantries);
  String? _storageError;
  int _nextId = 1;

  List<Pantry> get pantries => List.unmodifiable(_pantries);
  List<PantryCategory> get categories => List.unmodifiable(_categories);
  List<StockItem> get items => List.unmodifiable(_items);
  String? get storageError => _storageError;

  Future<void> _initialize() async {
    try {
      final saved = await _storage.read();
      if (saved != null) {
        final data = jsonDecode(saved) as Map<String, Object?>;
        final loadedPantries = (data['pantries']! as List<Object?>)
            .map((value) => Pantry.fromJson(value! as Map<String, Object?>))
            .toList();
        final loadedCategories = (data['categories']! as List<Object?>)
            .map(
              (value) =>
                  PantryCategory.fromJson(value! as Map<String, Object?>),
            )
            .toList();
        final loadedItems = (data['items']! as List<Object?>)
            .map((value) => StockItem.fromJson(value! as Map<String, Object?>))
            .toList();
        _pantries = loadedPantries;
        _categories = loadedCategories;
        _items = loadedItems;
      } else {
        await _persist(_pantries, _categories, _items);
      }
      _storageError = null;
    } catch (error) {
      _storageError = 'Не вдалося завантажити локальні дані: $error';
    }
    notifyListeners();
  }

  Future<void> _persist(
    List<Pantry> pantries,
    List<PantryCategory> categories,
    List<StockItem> items,
  ) async {
    final data = jsonEncode({
      'pantries': pantries.map((pantry) => pantry.toJson()).toList(),
      'categories': categories.map((category) => category.toJson()).toList(),
      'items': items.map((item) => item.toJson()).toList(),
    });
    await _storage.write(data);
  }

  Future<void> _commit({
    required List<Pantry> pantries,
    required List<PantryCategory> categories,
    required List<StockItem> items,
  }) async {
    try {
      await _persist(pantries, categories, items);
    } catch (error) {
      _storageError = 'Не вдалося зберегти зміни: $error';
      notifyListeners();
      rethrow;
    }
    _pantries = pantries;
    _categories = categories;
    _items = items;
    _storageError = null;
    notifyListeners();
  }

  Pantry pantryById(String id) =>
      _pantries.firstWhere((pantry) => pantry.id == id);

  StockItem itemById(String id) => _items.firstWhere((item) => item.id == id);

  PantryCategory categoryById(String id) =>
      _categories.firstWhere((category) => category.id == id);

  List<StockItem> filteredItems({
    String? pantryId,
    String? categoryId,
    String query = '',
    StockFilter filter = StockFilter.all,
    StockSort sort = StockSort.name,
    bool descending = false,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final result = _items.where((item) {
      if (pantryId != null && item.pantryId != pantryId) return false;
      if (categoryId != null && item.categoryId != categoryId) return false;
      if (normalizedQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(normalizedQuery) &&
          !item.brand.toLowerCase().contains(normalizedQuery)) {
        return false;
      }
      return switch (filter) {
        StockFilter.all => true,
        StockFilter.expiring => item.isExpiringSoon,
        StockFilter.expired => item.isExpired,
        StockFilter.lowStock => item.isLowStock,
      };
    }).toList();

    int compare(StockItem first, StockItem second) {
      return switch (sort) {
        StockSort.name => first.name.toLowerCase().compareTo(
          second.name.toLowerCase(),
        ),
        StockSort.expiration =>
          (first.expirationDate ?? DateTime(9999)).compareTo(
            second.expirationDate ?? DateTime(9999),
          ),
        StockSort.quantity => first.quantity.compareTo(second.quantity),
      };
    }

    result.sort((first, second) {
      final comparison = compare(first, second);
      return descending ? -comparison : comparison;
    });
    return result;
  }

  Future<void> savePantry({
    String? id,
    required String name,
    required String description,
  }) async {
    final pantry = Pantry(
      id: id ?? _id('pantry'),
      name: name.trim(),
      description: description.trim(),
      createdAt: id == null ? DateTime.now() : pantryById(id).createdAt,
    );
    final updated = [..._pantries];
    final existingIndex = updated.indexWhere((value) => value.id == pantry.id);
    if (existingIndex < 0) {
      updated.add(pantry);
    } else {
      updated[existingIndex] = pantry;
    }
    await _commit(pantries: updated, categories: _categories, items: _items);
  }

  Future<void> deletePantry(String id) async {
    if (_pantries.length == 1) {
      throw StateError('У застосунку має залишитися хоча б одна комора.');
    }
    final pantries = _pantries.where((pantry) => pantry.id != id).toList();
    final items = _items.where((item) => item.pantryId != id).toList();
    await _commit(pantries: pantries, categories: _categories, items: items);
  }

  Future<void> saveCategory({String? id, required String name}) async {
    final category = PantryCategory(
      id: id ?? _id('category'),
      name: name.trim(),
    );
    final updated = [..._categories];
    final index = updated.indexWhere((value) => value.id == category.id);
    if (index < 0) {
      updated.add(category);
    } else {
      updated[index] = category;
    }
    await _commit(pantries: _pantries, categories: updated, items: _items);
  }

  Future<void> deleteCategory(String id) async {
    if (_items.any((item) => item.categoryId == id)) {
      throw StateError('Спершу перемістіть запаси з цієї категорії.');
    }
    final categories = _categories
        .where((category) => category.id != id)
        .toList();
    await _commit(pantries: _pantries, categories: categories, items: _items);
  }

  Future<void> saveItem({
    String? id,
    required String pantryId,
    required String name,
    required String categoryId,
    required String brand,
    required double quantity,
    required String unit,
    required double minimumQuantity,
    required DateTime? expirationDate,
    required String notes,
  }) async {
    final existing = id == null ? null : itemById(id);
    final now = DateTime.now();
    final item = StockItem(
      id: id ?? _id('stock'),
      pantryId: pantryId,
      name: name.trim(),
      categoryId: categoryId,
      brand: brand.trim(),
      quantity: quantity,
      unit: unit,
      minimumQuantity: minimumQuantity,
      expirationDate: expirationDate,
      notes: notes.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final updated = [..._items];
    final index = updated.indexWhere((value) => value.id == item.id);
    if (index < 0) {
      updated.add(item);
    } else {
      updated[index] = item;
    }
    await _commit(pantries: _pantries, categories: _categories, items: updated);
  }

  Future<void> changeQuantity(String id, double delta) async {
    final existing = itemById(id);
    final quantity = existing.quantity + delta;
    if (quantity < 0) {
      throw StateError('Кількість не може бути меншою за нуль.');
    }
    final updatedItem = StockItem(
      id: existing.id,
      pantryId: existing.pantryId,
      name: existing.name,
      categoryId: existing.categoryId,
      brand: existing.brand,
      quantity: quantity,
      unit: existing.unit,
      minimumQuantity: existing.minimumQuantity,
      expirationDate: existing.expirationDate,
      notes: existing.notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    final updated = [..._items]
      ..[_items.indexWhere((item) => item.id == id)] = updatedItem;
    await _commit(pantries: _pantries, categories: _categories, items: updated);
  }

  Future<void> deleteItem(String id) async {
    final items = _items.where((item) => item.id != id).toList();
    await _commit(pantries: _pantries, categories: _categories, items: items);
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  static List<Pantry> _createDemoPantries() {
    final now = DateTime.now();
    return [
      Pantry(
        id: 'main-pantry',
        name: 'Основна комора',
        description: 'На кухні для продуктів і щоденних запасів.',
        createdAt: now.subtract(const Duration(days: 120)),
      ),
      Pantry(
        id: 'utility-pantry',
        name: 'Комора 2',
        description: 'Побутові речі та запас у підвалі.',
        createdAt: now.subtract(const Duration(days: 48)),
      ),
    ];
  }

  static List<PantryCategory> _createDemoCategories() => const [
    PantryCategory(id: 'food', name: 'Продукти'),
    PantryCategory(id: 'water', name: 'Вода'),
    PantryCategory(id: 'first-aid', name: 'Аптечка'),
    PantryCategory(id: 'lighting', name: 'Освітлення'),
    PantryCategory(id: 'power', name: 'Електроживлення'),
    PantryCategory(id: 'batteries', name: 'Батарейки та акумулятори'),
    PantryCategory(id: 'hygiene', name: 'Гігієна'),
    PantryCategory(id: 'household', name: 'Господарські товари'),
    PantryCategory(id: 'other', name: 'Інше'),
  ];

  static List<StockItem> _createDemoItems(List<Pantry> pantries) {
    final now = DateTime.now();
    StockItem item({
      required String id,
      required String pantryId,
      required String name,
      required String category,
      required double quantity,
      required String unit,
      required double minimum,
      int? expirationDays,
      String brand = '',
      String notes = '',
    }) => StockItem(
      id: id,
      pantryId: pantryId,
      name: name,
      categoryId: category,
      brand: brand,
      quantity: quantity,
      unit: unit,
      minimumQuantity: minimum,
      expirationDate: expirationDays == null
          ? null
          : DateTime(now.year, now.month, now.day + expirationDays),
      notes: notes,
      createdAt: now.subtract(const Duration(days: 18)),
      updatedAt: now,
    );

    return [
      item(
        id: 'rice',
        pantryId: pantries[0].id,
        name: 'Рис жасмин',
        category: 'food',
        quantity: 5,
        unit: 'кг',
        minimum: 1,
        expirationDays: 220,
        brand: 'Добрий урожай',
      ),
      item(
        id: 'milk',
        pantryId: pantries[0].id,
        name: 'Молоко 2.5%',
        category: 'food',
        quantity: 0.5,
        unit: 'л',
        minimum: 1,
        expirationDays: 3,
        brand: 'Молокія',
        notes: 'Зберігати в холодильнику.',
      ),
      item(
        id: 'yogurt',
        pantryId: pantries[0].id,
        name: 'Йогурт натуральний',
        category: 'food',
        quantity: 2,
        unit: 'шт',
        minimum: 2,
        expirationDays: -2,
        brand: 'Галичина',
      ),
      item(
        id: 'buckwheat',
        pantryId: pantries[0].id,
        name: 'Гречка',
        category: 'food',
        quantity: 3,
        unit: 'кг',
        minimum: 1,
        expirationDays: 180,
      ),
      item(
        id: 'water',
        pantryId: pantries[0].id,
        name: 'Вода питна',
        category: 'water',
        quantity: 2,
        unit: 'пляш.',
        minimum: 6,
        expirationDays: 300,
      ),
      item(
        id: 'first-aid',
        pantryId: pantries[1].id,
        name: 'Аптечка базова',
        category: 'first-aid',
        quantity: 1,
        unit: 'набір',
        minimum: 1,
        expirationDays: 170,
      ),
      item(
        id: 'flashlight',
        pantryId: pantries[1].id,
        name: 'Ліхтарик LED',
        category: 'lighting',
        quantity: 2,
        unit: 'шт',
        minimum: 1,
        brand: 'LightPro',
        notes: 'Заряджати раз на три місяці.',
      ),
      item(
        id: 'batteries',
        pantryId: pantries[1].id,
        name: 'Батарейки AA',
        category: 'batteries',
        quantity: 12,
        unit: 'шт',
        minimum: 8,
        expirationDays: 520,
      ),
      item(
        id: 'powerbank',
        pantryId: pantries[1].id,
        name: 'Павербанк 20000 мА·год',
        category: 'power',
        quantity: 1,
        unit: 'шт',
        minimum: 1,
        brand: 'PowerGo',
        notes: 'Заряд акумулятора перевірено.',
      ),
    ];
  }
}
