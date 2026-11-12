class Pantry {
  const Pantry({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Pantry.fromJson(Map<String, Object?> json) => Pantry(
    id: json['id']! as String,
    name: json['name']! as String,
    description: json['description']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
  );
}

class PantryCategory {
  const PantryCategory({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  factory PantryCategory.fromJson(Map<String, Object?> json) =>
      PantryCategory(id: json['id']! as String, name: json['name']! as String);
}

class StockItem {
  const StockItem({
    required this.id,
    required this.pantryId,
    required this.name,
    required this.categoryId,
    required this.brand,
    required this.quantity,
    required this.unit,
    required this.minimumQuantity,
    required this.expirationDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String pantryId;
  final String name;
  final String categoryId;
  final String brand;
  final double quantity;
  final String unit;
  final double minimumQuantity;
  final DateTime? expirationDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => quantity <= minimumQuantity;

  bool get isExpired {
    final expiration = expirationDate;
    if (expiration == null) return false;
    return _dateOnly(expiration).isBefore(_dateOnly(DateTime.now()));
  }

  bool get isExpiringSoon {
    final expiration = expirationDate;
    if (expiration == null || isExpired) return false;
    final daysLeft = _dateOnly(expiration)
        .difference(_dateOnly(DateTime.now()))
        .inDays;
    return daysLeft <= 7;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'pantryId': pantryId,
    'name': name,
    'categoryId': categoryId,
    'brand': brand,
    'quantity': quantity,
    'unit': unit,
    'minimumQuantity': minimumQuantity,
    'expirationDate': expirationDate?.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory StockItem.fromJson(Map<String, Object?> json) => StockItem(
    id: json['id']! as String,
    pantryId: json['pantryId']! as String,
    name: json['name']! as String,
    categoryId: json['categoryId']! as String,
    brand: json['brand']! as String,
    quantity: (json['quantity']! as num).toDouble(),
    unit: json['unit']! as String,
    minimumQuantity: (json['minimumQuantity']! as num).toDouble(),
    expirationDate: json['expirationDate'] == null
        ? null
        : DateTime.parse(json['expirationDate']! as String),
    notes: json['notes']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
