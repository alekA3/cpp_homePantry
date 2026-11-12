import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/pantry/pantry_models.dart';
import '../../core/pantry/pantry_provider.dart';
import '../../core/theme/app_colors.dart';

class PantrySectionScreen extends StatelessWidget {
  const PantrySectionScreen({
    super.key,
    required this.sectionKey,
    this.pantryId,
    required this.onOpenSection,
  });

  final String sectionKey;
  final String? pantryId;
  final ValueChanged<String> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return switch (sectionKey) {
      'home' => PantryDashboardScreen(onOpenSection: onOpenSection),
      'pantries' => PantryListScreen(
        onOpenPantry: (id) => onOpenSection('pantry:$id'),
      ),
      'all-stock' => const StockListScreen(),
      'categories' => const CategoryListScreen(),
      'reminders' => const ReminderListScreen(),
      _ when pantryId != null => StockListScreen(pantryId: pantryId),
      _ => const Center(child: Text('Розділ не знайдено.')),
    };
  }
}

class PantryDashboardScreen extends StatelessWidget {
  const PantryDashboardScreen({super.key, required this.onOpenSection});

  final ValueChanged<String> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final allItems = provider.items;
    final expired = allItems.where((item) => item.isExpired).toList();
    final expiring = allItems.where((item) => item.isExpiringSoon).toList();
    final lowStock = allItems.where((item) => item.isLowStock).toList();
    final categoryCounts = provider.categories
        .map(
          (category) => (
            category: category,
            count: allItems
                .where((item) => item.categoryId == category.id)
                .length,
          ),
        )
        .where((entry) => entry.count > 0)
        .toList();

    return _PageScroll(
      children: [
        const _StorageErrorBanner(),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 900 ? 3 : 1;
            return _ResponsiveCards(
              columns: columns,
              children: [
                _MetricCard(
                  label: 'АКТИВНА КОМОРА',
                  value: provider.pantries.isEmpty
                      ? 'Немає комор'
                      : provider.pantries.first.name,
                  icon: Icons.kitchen_outlined,
                ),
                _MetricCard(
                  label: 'УСЬОГО ЗАПАСІВ',
                  value: '${allItems.length} позицій',
                  icon: Icons.inventory_2_outlined,
                ),
                _MetricCard(
                  label: 'ПОТРЕБУЮТЬ УВАГИ',
                  value:
                      '${expired.length + expiring.length + lowStock.length}',
                  icon: Icons.notifications_none,
                ),
              ],
            );
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final chart = _DashboardCard(
              title: 'Запаси за категоріями',
              child: categoryCounts.isEmpty
                  ? const _EmptyHint('Додайте перші запаси до комори.')
                  : Column(
                      children: [
                        for (final entry in categoryCounts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 13),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    entry.category.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: entry.count / allItems.length,
                                      minHeight: 10,
                                      color: olive,
                                      backgroundColor: lightOlive,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('${entry.count}'),
                              ],
                            ),
                          ),
                      ],
                    ),
            );
            final alerts = _DashboardCard(
              title: 'Швидкі дії',
              child: Column(
                children: [
                  _QuickAction(
                    label: 'Переглянути запаси',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => onOpenSection('all-stock'),
                  ),
                  _QuickAction(
                    label: 'Переглянути нагадування',
                    icon: Icons.notifications_none,
                    onTap: () => onOpenSection('reminders'),
                  ),
                  _QuickAction(
                    label: 'Додати запас',
                    icon: Icons.add,
                    onTap: () => _openItemForm(context),
                  ),
                ],
              ),
            );
            if (!wide) {
              return Column(
                children: [chart, const SizedBox(height: 16), alerts],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: chart),
                const SizedBox(width: 16),
                Expanded(child: alerts),
              ],
            );
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final lowStockCard = _DashboardCard(
              title: 'Низький рівень запасу',
              child: _ItemPreviewList(
                items: lowStock.take(3).toList(),
                emptyText: 'Усі запаси в достатній кількості.',
                onOpen: (item) => _openItemDetails(context, item.id),
              ),
            );
            final expiryCard = _DashboardCard(
              title: 'Термін придатності',
              child: _ItemPreviewList(
                items: [...expired, ...expiring].take(3).toList(),
                emptyText: 'Немає запасів із близьким терміном.',
                onOpen: (item) => _openItemDetails(context, item.id),
              ),
            );
            if (!wide) {
              return Column(
                children: [
                  lowStockCard,
                  const SizedBox(height: 16),
                  expiryCard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: lowStockCard),
                const SizedBox(width: 16),
                Expanded(child: expiryCard),
              ],
            );
          },
        ),
      ],
    );
  }
}

class PantryListScreen extends StatelessWidget {
  const PantryListScreen({super.key, required this.onOpenPantry});

  final ValueChanged<String> onOpenPantry;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    return _PageScroll(
      children: [
        const _StorageErrorBanner(),
        _PageHeading(
          title: 'Ваші комори',
          subtitle: 'Список усіх місць зберігання',
          actionLabel: 'Створити комору',
          actionIcon: Icons.add,
          onAction: () => _openPantryForm(context),
        ),
        if (provider.pantries.isEmpty)
          const _EmptyState(
            icon: Icons.kitchen_outlined,
            title: 'Комор ще немає',
            message: 'Створіть комору, щоб упорядкувати домашні запаси.',
          )
        else
          for (final pantry in provider.pantries)
            _PantryCard(pantry: pantry, onOpen: () => onOpenPantry(pantry.id)),
      ],
    );
  }
}

class _PantryCard extends StatelessWidget {
  const _PantryCard({required this.pantry, required this.onOpen});

  final Pantry pantry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final count = provider.items
        .where((item) => item.pantryId == pantry.id)
        .length;
    return _AppCard(
      onTap: onOpen,
      child: Row(
        children: [
          const _IconTile(icon: Icons.kitchen_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pantry.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  pantry.description.isEmpty
                      ? 'Опис не додано'
                      : pantry.description,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count запасів · Створено ${_formatDate(pantry.createdAt)}',
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Відкрити запаси',
            onPressed: onOpen,
            icon: const Icon(Icons.arrow_forward_ios, size: 17),
          ),
          IconButton(
            tooltip: 'Редагувати комору',
            onPressed: () => _openPantryForm(context, pantry: pantry),
            icon: const Icon(Icons.edit_outlined, color: olive),
          ),
          IconButton(
            tooltip: 'Видалити комору',
            onPressed: () => _confirmDelete(
              context,
              title: 'Видалити комору?',
              message:
                  'Комору та її запаси буде видалено з локального сховища.',
              onDelete: () => provider.deletePantry(pantry.id),
            ),
            icon: const Icon(Icons.delete_outline, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key, this.pantryId});

  final String? pantryId;

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  final _searchController = TextEditingController();
  String? _categoryId;
  StockFilter _filter = StockFilter.all;
  StockSort _sort = StockSort.name;
  bool _descending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final selectedPantry = widget.pantryId == null
        ? null
        : provider.pantries
              .where((pantry) => pantry.id == widget.pantryId)
              .firstOrNull;
    final items = provider.filteredItems(
      pantryId: widget.pantryId,
      categoryId: _categoryId,
      query: _searchController.text,
      filter: _filter,
      sort: _sort,
      descending: _descending,
    );
    final title = selectedPantry?.name ?? 'Усі запаси';

    return _PageScroll(
      children: [
        const _StorageErrorBanner(),
        _PageHeading(
          title: title,
          subtitle:
              selectedPantry?.description ??
              'Пошук, фільтрування та облік запасів',
          actionLabel: 'Додати запас',
          actionIcon: Icons.add,
          onAction: () => _openItemForm(context, pantryId: widget.pantryId),
        ),
        _AppCard(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Пошук запасів…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Категорія',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Усі категорії'),
                    ),
                    for (final category in provider.categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<StockFilter>(
                  initialValue: _filter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Фільтр',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: StockFilter.all,
                      child: Text('Усі стани'),
                    ),
                    DropdownMenuItem(
                      value: StockFilter.expiring,
                      child: Text('Скоро закінчиться'),
                    ),
                    DropdownMenuItem(
                      value: StockFilter.expired,
                      child: Text('Прострочені'),
                    ),
                    DropdownMenuItem(
                      value: StockFilter.lowStock,
                      child: Text('Мало запасу'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _filter = value);
                  },
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<StockSort>(
                  initialValue: _sort,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Сортування',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: StockSort.name,
                      child: Text('За назвою'),
                    ),
                    DropdownMenuItem(
                      value: StockSort.expiration,
                      child: Text('За терміном'),
                    ),
                    DropdownMenuItem(
                      value: StockSort.quantity,
                      child: Text('За кількістю'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                ),
              ),
              IconButton(
                tooltip: _descending ? 'За зростанням' : 'За спаданням',
                onPressed: () => setState(() => _descending = !_descending),
                icon: Icon(
                  _descending ? Icons.south : Icons.north,
                  color: olive,
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          const _EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Запасів не знайдено',
            message: 'Змініть параметри пошуку або додайте новий запас.',
          )
        else
          _AppCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _StockRow(item: items[index]),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'Показано ${items.length} з ${provider.items.length} запасів',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final category = provider.categories
        .where((value) => value.id == item.categoryId)
        .firstOrNull;
    final status = item.isExpired
        ? 'Прострочено'
        : item.isExpiringSoon
        ? 'Закінчується'
        : item.isLowStock
        ? 'Мало запасу'
        : 'У нормі';
    final statusColor = item.isExpired
        ? Colors.red.shade700
        : item.isLowStock || item.isExpiringSoon
        ? const Color(0xFF9A6B18)
        : olive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const _IconTile(icon: Icons.inventory_2_outlined, small: true),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.brand.isNotEmpty)
                  Text(
                    item.brand,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(category?.name ?? 'Без категорії')),
          Expanded(
            child: Text('${_formatQuantity(item.quantity)} ${item.unit}'),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.expirationDate == null
                  ? '—'
                  : _formatDate(item.expirationDate!),
            ),
          ),
          _StatusChip(label: status, color: statusColor),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Переглянути',
            onPressed: () => _openItemDetails(context, item.id),
            icon: const Icon(Icons.visibility_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'Редагувати',
            onPressed: () => _openItemForm(context, item: item),
            icon: const Icon(Icons.edit_outlined, size: 19, color: olive),
          ),
          IconButton(
            tooltip: 'Видалити',
            onPressed: () => _confirmDelete(
              context,
              title: 'Видалити запас?',
              message: '«${item.name}» буде видалено з комори.',
              onDelete: () => provider.deleteItem(item.id),
            ),
            icon: const Icon(Icons.delete_outline, size: 19),
          ),
        ],
      ),
    );
  }
}

class StockDetailScreen extends StatelessWidget {
  const StockDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final item = provider.itemById(itemId);
    final category = provider.categoryById(item.categoryId);
    final pantry = provider.pantryById(item.pantryId);
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: Text('Деталі запасу: ${item.name}'),
        actions: [
          IconButton(
            tooltip: 'Редагувати',
            onPressed: () => _openItemForm(context, item: item),
            icon: const Icon(Icons.edit_outlined, color: olive),
          ),
          IconButton(
            tooltip: 'Видалити',
            onPressed: () => _confirmDelete(
              context,
              title: 'Видалити запас?',
              message: '«${item.name}» буде видалено з комори.',
              onDelete: () async {
                await provider.deleteItem(item.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _PageScroll(
        children: [
          const _StorageErrorBanner(),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 720;
              final details = _AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(label: category.name, color: olive),
                        _StatusChip(
                          label: item.isExpired
                              ? 'Прострочено'
                              : item.isExpiringSoon
                              ? 'Закінчується'
                              : item.isLowStock
                              ? 'Мало запасу'
                              : 'У нормі',
                          color: item.isExpired ? Colors.red.shade700 : olive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (item.brand.isNotEmpty)
                      Text(
                        'Виробник: ${item.brand}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    const Divider(height: 30),
                    Wrap(
                      spacing: 26,
                      runSpacing: 16,
                      children: [
                        _DetailValue(
                          label: 'ПОТОЧНА КІЛЬКІСТЬ',
                          value:
                              '${_formatQuantity(item.quantity)} ${item.unit}',
                        ),
                        _DetailValue(
                          label: 'МІНІМАЛЬНИЙ ЗАПАС',
                          value:
                              '${_formatQuantity(item.minimumQuantity)} ${item.unit}',
                        ),
                        _DetailValue(
                          label: 'ТЕРМІН ПРИДАТНОСТІ',
                          value: item.expirationDate == null
                              ? 'Не застосовується'
                              : _formatDate(item.expirationDate!),
                        ),
                        _DetailValue(label: 'КОМОРА', value: pantry.name),
                      ],
                    ),
                    const Divider(height: 30),
                    const Text(
                      'ОПИС ТА ПРИМІТКИ',
                      style: TextStyle(
                        color: olive,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.notes.isEmpty ? 'Приміток немає.' : item.notes),
                  ],
                ),
              );
              final preview = _AppCard(
                child: Column(
                  children: [
                    Container(
                      height: 190,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: lightOlive,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: olive,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DetailValue(
                      label: 'ДОДАНО',
                      value: _formatDate(item.createdAt),
                    ),
                    const SizedBox(height: 12),
                    _DetailValue(
                      label: 'ОСТАННЄ ОНОВЛЕННЯ',
                      value: _formatDate(item.updatedAt),
                    ),
                  ],
                ),
              );
              if (!wide) {
                return Column(
                  children: [
                    preview,
                    const SizedBox(height: 16),
                    details,
                    const SizedBox(height: 16),
                    _QuantityActions(item: item),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 270, child: preview),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        details,
                        const SizedBox(height: 16),
                        _QuantityActions(item: item),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuantityActions extends StatelessWidget {
  const _QuantityActions({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PantryProvider>();
    return _DashboardCard(
      title: 'Швидке керування кількістю',
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: item.quantity <= 0
                  ? null
                  : () => _perform(
                      context,
                      () => provider.changeQuantity(item.id, -1),
                    ),
              icon: const Icon(Icons.remove),
              label: const Text('Використати 1'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  _perform(context, () => provider.changeQuantity(item.id, 1)),
              icon: const Icon(Icons.add),
              label: const Text('Додати 1'),
            ),
          ),
        ],
      ),
    );
  }
}

class StockFormScreen extends StatefulWidget {
  const StockFormScreen({super.key, this.item, this.pantryId});

  final StockItem? item;
  final String? pantryId;

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _quantity;
  late final TextEditingController _minimum;
  late final TextEditingController _notes;
  late String? _pantryId;
  late String? _categoryId;
  String _unit = 'шт';
  DateTime? _expirationDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _brand = TextEditingController(text: item?.brand ?? '');
    _quantity = TextEditingController(
      text: item == null ? '' : _formatQuantity(item.quantity),
    );
    _minimum = TextEditingController(
      text: item == null ? '' : _formatQuantity(item.minimumQuantity),
    );
    _notes = TextEditingController(text: item?.notes ?? '');
    _pantryId = item?.pantryId ?? widget.pantryId;
    _categoryId = item?.categoryId;
    _unit = item?.unit ?? 'шт';
    _expirationDate = item?.expirationDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _quantity.dispose();
    _minimum.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pantryId == null || _categoryId == null) return;
    setState(() => _saving = true);
    try {
      await context.read<PantryProvider>().saveItem(
        id: widget.item?.id,
        pantryId: _pantryId!,
        name: _name.text,
        categoryId: _categoryId!,
        brand: _brand.text,
        quantity: double.parse(_quantity.text.replaceAll(',', '.')),
        unit: _unit,
        minimumQuantity: double.parse(_minimum.text.replaceAll(',', '.')),
        expirationDate: _expirationDate,
        notes: _notes.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showFeedback(context, 'Не вдалося зберегти запас: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    _pantryId ??= provider.pantries.firstOrNull?.id;
    _categoryId ??= provider.categories.firstOrNull?.id;
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: Text(widget.item == null ? 'Додати запас' : 'Редагувати запас'),
      ),
      body: Form(
        key: _formKey,
        child: _PageScroll(
          children: [
            const _StorageErrorBanner(),
            _AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormTextField(
                    controller: _name,
                    label: 'Назва запасу',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Введіть назву запасу.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 650;
                      final controls = [
                        DropdownButtonFormField<String>(
                          initialValue: _pantryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Комора',
                          ),
                          items: [
                            for (final pantry in provider.pantries)
                              DropdownMenuItem(
                                value: pantry.id,
                                child: Text(pantry.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _pantryId = value),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _categoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Категорія',
                          ),
                          items: [
                            for (final category in provider.categories)
                              DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _categoryId = value),
                        ),
                      ];
                      if (compact) {
                        return Column(
                          children: [
                            controls[0],
                            const SizedBox(height: 14),
                            controls[1],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: controls[0]),
                          const SizedBox(width: 14),
                          Expanded(child: controls[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _FormTextField(controller: _brand, label: 'Виробник'),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 650;
                      final quantity = _FormTextField(
                        controller: _quantity,
                        label: 'Кількість',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateNumber,
                      );
                      final minimum = _FormTextField(
                        controller: _minimum,
                        label: 'Мінімальний запас',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateNumber,
                      );
                      final unit = DropdownButtonFormField<String>(
                        initialValue: _unit,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Одиниця'),
                        items: const [
                          DropdownMenuItem(value: 'шт', child: Text('шт')),
                          DropdownMenuItem(value: 'кг', child: Text('кг')),
                          DropdownMenuItem(value: 'г', child: Text('г')),
                          DropdownMenuItem(value: 'л', child: Text('л')),
                          DropdownMenuItem(value: 'мл', child: Text('мл')),
                          DropdownMenuItem(
                            value: 'набір',
                            child: Text('набір'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _unit = value);
                        },
                      );
                      if (compact) {
                        return Column(
                          children: [
                            quantity,
                            const SizedBox(height: 14),
                            unit,
                            const SizedBox(height: 14),
                            minimum,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: quantity),
                          const SizedBox(width: 14),
                          SizedBox(width: 130, child: unit),
                          const SizedBox(width: 14),
                          Expanded(child: minimum),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _expirationDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        helpText: 'Термін придатності (необов’язково)',
                      );
                      if (selected != null) {
                        setState(() => _expirationDate = selected);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _expirationDate == null
                          ? 'Додати термін придатності'
                          : 'Термін придатності: ${_formatDate(_expirationDate!)}',
                    ),
                  ),
                  if (_expirationDate != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _expirationDate = null),
                        child: const Text('Очистити дату'),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _FormTextField(
                    controller: _notes,
                    label: 'Опис та примітки',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Скасувати'),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check),
                        label: Text(_saving ? 'Збереження…' : 'Зберегти'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PantryFormScreen extends StatefulWidget {
  const PantryFormScreen({super.key, this.pantry});

  final Pantry? pantry;

  @override
  State<PantryFormScreen> createState() => _PantryFormScreenState();
}

class _PantryFormScreenState extends State<PantryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.pantry?.name ?? '');
    _description = TextEditingController(
      text: widget.pantry?.description ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<PantryProvider>().savePantry(
        id: widget.pantry?.id,
        name: _name.text,
        description: _description.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) _showFeedback(context, 'Не вдалося зберегти комору: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: Text(
          widget.pantry == null ? 'Створити комору' : 'Редагувати комору',
        ),
      ),
      body: Form(
        key: _formKey,
        child: _PageScroll(
          children: [
            _AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormTextField(
                    controller: _name,
                    label: 'Назва комори',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Введіть назву комори.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _FormTextField(
                    controller: _description,
                    label: 'Опис',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Скасувати'),
                      ),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Збереження…' : 'Зберегти'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    return _PageScroll(
      children: [
        const _StorageErrorBanner(),
        _PageHeading(
          title: 'Категорії',
          subtitle: 'Групування запасів за призначенням',
          actionLabel: 'Створити категорію',
          actionIcon: Icons.add,
          onAction: () => _openCategoryForm(context),
        ),
        _CategoryGrid(categories: provider.categories),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<PantryCategory> categories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 0,
            childAspectRatio: columns == 1 ? 3.2 : 2.3,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) =>
              _CategoryCard(category: categories[index]),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final PantryCategory category;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final count = provider.items
        .where((item) => item.categoryId == category.id)
        .length;
    return _AppCard(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CategoryDetailScreen(categoryId: category.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: _categoryIcon(category.name)),
              const Spacer(),
              IconButton(
                tooltip: 'Редагувати категорію',
                onPressed: () => _openCategoryForm(context, category: category),
                icon: const Icon(Icons.edit_outlined, color: olive),
              ),
              IconButton(
                tooltip: 'Видалити категорію',
                onPressed: () => _confirmDelete(
                  context,
                  title: 'Видалити категорію?',
                  message:
                      'Категорію можна видалити лише без пов’язаних запасів.',
                  onDelete: () => provider.deleteCategory(category.id),
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${_itemWord(count)}',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final category = provider.categoryById(categoryId);
    final items = provider.filteredItems(categoryId: categoryId);
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(title: Text(category.name)),
      body: _PageScroll(
        children: [
          const _StorageErrorBanner(),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Запаси в категорії · ${items.length} ${_itemWord(items.length)}',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: Colors.black54),
            ),
          ),
          if (items.isEmpty)
            const _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'У цій категорії поки немає запасів',
              message: 'Додайте запас, щоб він відображався тут.',
            )
          else
            for (final item in items) _CategoryStockCard(item: item),
        ],
      ),
    );
  }
}

class _CategoryStockCard extends StatelessWidget {
  const _CategoryStockCard({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final pantry = context.read<PantryProvider>().pantryById(item.pantryId);
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(
                label: item.isExpired
                    ? 'Прострочено'
                    : item.isExpiringSoon
                    ? 'Закінчується'
                    : item.isLowStock
                    ? 'Мало запасу'
                    : 'У нормі',
                color: item.isExpired ? Colors.red.shade700 : olive,
              ),
            ],
          ),
          if (item.brand.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Виробник: ${item.brand}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const Divider(height: 24),
          Wrap(
            spacing: 26,
            runSpacing: 14,
            children: [
              _DetailValue(label: 'КОМОРА', value: pantry.name),
              _DetailValue(
                label: 'ПОТОЧНА КІЛЬКІСТЬ',
                value: '${_formatQuantity(item.quantity)} ${item.unit}',
              ),
              _DetailValue(
                label: 'МІНІМАЛЬНИЙ ЗАПАС',
                value: '${_formatQuantity(item.minimumQuantity)} ${item.unit}',
              ),
              _DetailValue(
                label: 'ТЕРМІН ПРИДАТНОСТІ',
                value: item.expirationDate == null
                    ? 'Не застосовується'
                    : _formatDate(item.expirationDate!),
              ),
              _DetailValue(label: 'ДОДАНО', value: _formatDate(item.createdAt)),
              _DetailValue(
                label: 'ОСТАННЄ ОНОВЛЕННЯ',
                value: _formatDate(item.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.notes.isEmpty ? 'Приміток немає.' : item.notes,
            style: const TextStyle(color: Colors.black87),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openItemDetails(context, item.id),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Деталі запасу'),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({super.key, this.category});

  final PantryCategory? category;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<PantryProvider>().saveCategory(
        id: widget.category?.id,
        name: _name.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        _showFeedback(context, 'Не вдалося зберегти категорію: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: Text(
          widget.category == null
              ? 'Створити категорію'
              : 'Редагувати категорію',
        ),
      ),
      body: Form(
        key: _formKey,
        child: _PageScroll(
          children: [
            _AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormTextField(
                    controller: _name,
                    label: 'Назва категорії',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Введіть назву категорії.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Скасувати'),
                      ),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Збереження…' : 'Зберегти'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final expired = provider.items.where((item) => item.isExpired).toList();
    final expiring = provider.items
        .where((item) => item.isExpiringSoon)
        .toList();
    final lowStock = provider.items.where((item) => item.isLowStock).toList();
    return _PageScroll(
      children: [
        const _StorageErrorBanner(),
        _PageHeading(
          title: 'Нагадування',
          subtitle: 'Запаси, які потребують вашої уваги',
        ),
        _ReminderGroup(
          title: 'Термін придатності минув',
          icon: Icons.error_outline,
          items: expired,
          critical: true,
        ),
        _ReminderGroup(
          title: 'Термін придатності наближається',
          icon: Icons.calendar_today_outlined,
          items: expiring,
        ),
        _ReminderGroup(
          title: 'Низький запас',
          icon: Icons.inventory_2_outlined,
          items: lowStock,
        ),
      ],
    );
  }
}

class _ReminderGroup extends StatelessWidget {
  const _ReminderGroup({
    required this.title,
    required this.icon,
    required this.items,
    this.critical = false,
  });

  final String title;
  final IconData icon;
  final List<StockItem> items;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: title,
      icon: icon,
      child: items.isEmpty
          ? const _EmptyHint('Немає запасів у цій групі.')
          : Column(
              children: [
                for (final item in items)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _IconTile(
                        icon: Icons.inventory_2_outlined,
                        tint: critical ? Colors.red.shade50 : lightOlive,
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${item.quantity} ${item.unit} · ${item.expirationDate == null ? 'без терміну' : _formatDate(item.expirationDate!)}',
                      ),
                      trailing: OutlinedButton(
                        onPressed: () => _openItemDetails(context, item.id),
                        child: const Text('Переглянути'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          if (actionLabel != null)
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.add),
              label: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      child: Row(
        children: [
          _IconTile(icon: icon),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.child, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: olive),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE6E7DF)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E7DF)),
      ),
      child: child,
    );
  }
}

class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _ResponsiveCards extends StatelessWidget {
  const _ResponsiveCards({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(children: children);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 0,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    this.small = false,
    this.tint = lightOlive,
  });

  final IconData icon;
  final bool small;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 44.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: small ? 18 : 22, color: olive),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: olive,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ItemPreviewList extends StatelessWidget {
  const _ItemPreviewList({
    required this.items,
    required this.emptyText,
    required this.onOpen,
  });

  final List<StockItem> items;
  final String emptyText;
  final ValueChanged<StockItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyHint(emptyText);
    return Column(
      children: [
        for (final item in items)
          Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('${item.quantity} ${item.unit}'),
              trailing: const Icon(Icons.chevron_right, color: olive),
              onTap: () => onOpen(item),
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Align(alignment: Alignment.centerLeft, child: Text(label)),
        style: OutlinedButton.styleFrom(
          foregroundColor: olive,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(message, style: const TextStyle(color: Colors.black54)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _AppCard(
      child: Column(
        children: [
          Icon(icon, size: 40, color: olive),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StorageErrorBanner extends StatelessWidget {
  const _StorageErrorBanner();

  @override
  Widget build(BuildContext context) {
    final error = context.select<PantryProvider, String?>(
      (provider) => provider.storageError,
    );
    if (error == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: Color(0xFF9A6B18)),
          const SizedBox(width: 8),
          Expanded(child: Text(error)),
        ],
      ),
    );
  }
}

String? _validateNumber(String? value) {
  final number = double.tryParse((value ?? '').replaceAll(',', '.'));
  if (number == null || number < 0) return 'Введіть число не менше нуля.';
  return null;
}

IconData _categoryIcon(String name) => switch (name.toLowerCase()) {
  'продукти' => Icons.restaurant_outlined,
  'вода' => Icons.water_drop_outlined,
  'аптечка' => Icons.medical_services_outlined,
  'освітлення' => Icons.lightbulb_outline,
  'електроживлення' => Icons.power_outlined,
  'батарейки та акумулятори' => Icons.battery_4_bar,
  'гігієна' => Icons.spa_outlined,
  'господарські товари' => Icons.cleaning_services_outlined,
  _ => Icons.more_horiz,
};

String _itemWord(int count) {
  if (count == 1) return 'позиція';
  if (count >= 2 && count <= 4) return 'позиції';
  return 'позицій';
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

String _formatQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

void _openPantryForm(BuildContext context, {Pantry? pantry}) {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => PantryFormScreen(pantry: pantry)),
  );
}

void _openCategoryForm(BuildContext context, {PantryCategory? category}) {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CategoryFormScreen(category: category),
    ),
  );
}

void _openItemForm(BuildContext context, {StockItem? item, String? pantryId}) {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => StockFormScreen(item: item, pantryId: pantryId),
    ),
  );
}

void _openItemDetails(BuildContext context, String itemId) {
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => StockDetailScreen(itemId: itemId)),
  );
}

Future<void> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onDelete,
}) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Скасувати'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Видалити'),
        ),
      ],
    ),
  );
  if (shouldDelete != true || !context.mounted) return;
  await _perform(context, onDelete);
}

Future<void> _perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    if (context.mounted) _showFeedback(context, 'Зміни збережено.');
  } catch (error) {
    if (context.mounted) {
      _showFeedback(context, 'Не вдалося виконати дію: $error');
    }
  }
}

void _showFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
